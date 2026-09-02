import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/clipboard_item.dart';
import 'database_service.dart';
import 'login_item_service.dart';
import 'settings_service.dart';

class ClipboardStore extends ChangeNotifier with ClipboardListener {
  ClipboardStore({
    DatabaseService? database,
    SettingsService? settings,
    LoginItemService? loginItem,
  })  : _database = database ?? DatabaseService(),
        _settings = settings ?? SettingsService(),
        _loginItem = loginItem ?? LoginItemService();

  final DatabaseService _database;
  final SettingsService _settings;
  final LoginItemService _loginItem;

  List<ClipboardItem> history = [];
  List<ClipboardItem> trash = [];
  int menuBarItemCount = defaultMenuBarItemCount;
  bool launchAtLogin = false;
  bool ready = false;

  List<ClipboardItem> get menuBarItems =>
      history.take(menuBarItemCount).toList(growable: false);

  Future<void> init() async {
    menuBarItemCount = await _settings.getMenuBarItemCount();
    launchAtLogin = await _loginItem.isEnabled();

    await _database.purgeExpiredTrash();
    await _refreshHistory();
    await _refreshTrash();

    ready = true;
    notifyListeners();

    clipboardWatcher.addListener(this);
    await clipboardWatcher.start();
  }

  @override
  void onClipboardChanged() {
    _handleClipboardChanged();
  }

  Future<void> _handleClipboardChanged() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    await _database.recordCopy(text);
    await _refreshHistory();
  }

  /// Re-copies [item]'s text to the system clipboard and bumps it back to
  /// the top of the history.
  Future<void> recopy(ClipboardItem item) async {
    await Clipboard.setData(ClipboardData(text: item.content));
    await _database.recordCopy(item.content);
    await _refreshHistory();
  }

  Future<void> moveToTrash(ClipboardItem item) async {
    await _database.moveToTrash(item.id);
    await _refreshHistory();
    await _refreshTrash();
  }

  /// Moves every item currently in History to Trash.
  Future<void> clearHistory() async {
    await _database.moveAllToTrash();
    await _refreshHistory();
    await _refreshTrash();
  }

  Future<void> restoreFromTrash(ClipboardItem item) async {
    await _database.restore(item.id);
    await _refreshHistory();
    await _refreshTrash();
  }

  Future<void> deleteForever(ClipboardItem item) async {
    await _database.deleteForever(item.id);
    await _refreshTrash();
  }

  Future<void> emptyTrash() async {
    await _database.emptyTrash();
    await _refreshTrash();
  }

  Future<void> setMenuBarItemCount(int count) async {
    menuBarItemCount = count.clamp(minMenuBarItemCount, maxMenuBarItemCount);
    await _settings.setMenuBarItemCount(menuBarItemCount);
    notifyListeners();
  }

  Future<void> setLaunchAtLogin(bool value) async {
    final ok = await _loginItem.setEnabled(value);
    launchAtLogin = ok ? value : await _loginItem.isEnabled();
    notifyListeners();
  }

  Future<void> _refreshHistory() async {
    history = await _database.getHistory();
    notifyListeners();
  }

  Future<void> _refreshTrash() async {
    trash = await _database.getTrash();
    notifyListeners();
  }

  @override
  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
    super.dispose();
  }
}
