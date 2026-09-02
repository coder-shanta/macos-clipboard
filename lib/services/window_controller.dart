import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

enum WindowMode { hidden, popup, full }

/// Destination page inside the full history window, requested from the
/// tray's right-click-style menu (e.g. "Trash" jumps straight to trash).
enum HistoryPage { history, trash, settings, about }

/// How long to wait after a first tray click to see if a second one
/// arrives, before treating it as a plain single click.
const _doubleClickWindow = Duration(milliseconds: 350);

const popupSize = Size(380, 480);
const fullSize = Size(760, 580);

/// Corner radius of the native glass panel, kept in sync with
/// `cardRadius` in `ui/theme.dart` (services intentionally don't import
/// the ui layer, so this is duplicated rather than shared).
const _glassCornerRadius = 16.0;
const _allCorners = VisualEffectSubviewProperties.topLeftCorner |
    VisualEffectSubviewProperties.topRightCorner |
    VisualEffectSubviewProperties.bottomRightCorner |
    VisualEffectSubviewProperties.bottomLeftCorner;

/// Owns the tray icon and the single app window, switching it between a
/// small popup anchored under the tray icon and a larger "full history"
/// window.
class WindowController extends ChangeNotifier
    with WindowListener, TrayListener {
  WindowMode mode = WindowMode.hidden;
  int? _glassSubviewId;
  Timer? _clickTimer;

  /// The page [showFullHistory] should land on next; set by the tray menu.
  HistoryPage requestedPage = HistoryPage.history;

  /// Bumped on every [showFullHistory] call so the UI can tell a fresh
  /// navigation request apart from an unrelated rebuild, even when the
  /// window was already in full mode.
  int navSeq = 0;

  Future<void> init() async {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: popupSize,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(true);
      await windowManager.setResizable(false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.hide();
    });
    windowManager.addListener(this);

    // A native NSVisualEffectView behind the Flutter content gives the
    // window real macOS vibrancy/blur (the "glass" look) instead of a
    // flat painted background. Its frame/material/corner radius are
    // updated on every mode switch to match the current window size.
    _glassSubviewId = await WindowManipulator.addVisualEffectSubview(
      VisualEffectSubviewProperties(
        frameX: 0,
        frameY: 0,
        frameWidth: popupSize.width,
        frameHeight: popupSize.height,
        cornerRadius: _glassCornerRadius,
        cornerMask: _allCorners,
        material: NSVisualEffectViewMaterial.popover,
        state: NSVisualEffectViewState.active,
      ),
    );

    await trayManager.setIcon(
      'assets/icons/tray_icon.png',
      isTemplate: true,
    );
    await trayManager.setToolTip('Clipboard');
    await trayManager.setContextMenu(_buildTrayMenu());
    trayManager.addListener(this);
  }

  Menu _buildTrayMenu() {
    return Menu(
      items: [
        MenuItem(
          key: 'history',
          label: 'History',
          onClick: (_) => showFullHistory(page: HistoryPage.history),
        ),
        MenuItem(
          key: 'trash',
          label: 'Trash',
          onClick: (_) => showFullHistory(page: HistoryPage.trash),
        ),
        MenuItem(
          key: 'settings',
          label: 'Settings',
          onClick: (_) => showFullHistory(page: HistoryPage.settings),
        ),
        MenuItem(
          key: 'about',
          label: 'About',
          onClick: (_) => showFullHistory(page: HistoryPage.about),
        ),
        MenuItem(key: 'quit', label: 'Quit', onClick: (_) => quit()),
      ],
    );
  }

  Future<void> _setGlass(Size size, NSVisualEffectViewMaterial material) async {
    final id = _glassSubviewId;
    if (id == null) return;
    await WindowManipulator.updateVisualEffectSubviewProperties(
      id,
      VisualEffectSubviewProperties(
        frameX: 0,
        frameY: 0,
        frameWidth: size.width,
        frameHeight: size.height,
        cornerRadius: _glassCornerRadius,
        cornerMask: _allCorners,
        material: material,
      ),
    );
  }

  @override
  void onTrayIconMouseDown() {
    if (_clickTimer != null) {
      // Second click arrived within the window: treat as a double click.
      _clickTimer?.cancel();
      _clickTimer = null;
      if (mode == WindowMode.popup) hideWindow();
      trayManager.popUpContextMenu();
      return;
    }

    // Wait to see if a second click follows before acting on this one.
    _clickTimer = Timer(_doubleClickWindow, () {
      _clickTimer = null;
      if (mode == WindowMode.hidden) {
        showPopup();
      } else {
        hideWindow();
      }
    });
  }

  /// Secondary click on the tray icon — includes a trackpad two-finger tap
  /// — shows the menu immediately, matching standard macOS status item
  /// behavior instead of requiring a double click.
  @override
  void onTrayIconRightMouseDown() {
    _clickTimer?.cancel();
    _clickTimer = null;
    if (mode == WindowMode.popup) hideWindow();
    trayManager.popUpContextMenu();
  }

  Future<void> showPopup() async {
    mode = WindowMode.popup;
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setResizable(false);
    await windowManager.setSize(popupSize);
    await _positionUnderTray();
    await _setGlass(popupSize, NSVisualEffectViewMaterial.popover);
    await windowManager.show();
    await windowManager.focus();
    notifyListeners();
  }

  Future<void> showFullHistory({HistoryPage page = HistoryPage.history}) async {
    requestedPage = page;
    navSeq++;
    mode = WindowMode.full;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSize(fullSize);
    await windowManager.center();
    await _setGlass(fullSize, NSVisualEffectViewMaterial.sidebar);
    await windowManager.show();
    await windowManager.focus();
    notifyListeners();
  }

  Future<void> hideWindow() async {
    mode = WindowMode.hidden;
    await windowManager.hide();
    notifyListeners();
  }

  Future<void> _positionUnderTray() async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final screenWidth = display.size.width;

      final trayBounds = await trayManager.getBounds();

      double x;
      double y;
      if (trayBounds != null) {
        // tray_manager already reports the icon's frame in the same
        // top-left-origin coordinates window_manager uses for setPosition,
        // so the popup just needs to sit right below the icon's bottom edge.
        final iconCenterX = trayBounds.left + trayBounds.width / 2;
        x = iconCenterX - popupSize.width / 2;
        y = trayBounds.top + trayBounds.height + 4;
      } else {
        x = screenWidth - popupSize.width - 12;
        y = 36;
      }

      x = x.clamp(8.0, screenWidth - popupSize.width - 8.0);
      await windowManager.setPosition(Offset(x, y));
    } catch (_) {
      // Fall back to whatever position the window already has.
    }
  }

  @override
  void onWindowBlur() {
    if (mode == WindowMode.popup) {
      hideWindow();
    }
  }

  /// Quits the app entirely. `LSUIElement` (no dock icon, no windows to
  /// close) means the process otherwise has no way to terminate itself.
  Future<void> quit() async {
    await trayManager.destroy();
    exit(0);
  }

  @override
  void dispose() {
    _clickTimer?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }
}
