import 'dart:async';

import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:provider/provider.dart';

import 'services/clipboard_store.dart';
import 'services/window_controller.dart';
import 'ui/full_history_view.dart';
import 'ui/popup_view.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManipulator.initialize();

  final windowController = WindowController();
  await windowController.init();

  final store = ClipboardStore();
  unawaited(store.init());

  runApp(ClipboardApp(store: store, windowController: windowController));
}

class ClipboardApp extends StatelessWidget {
  const ClipboardApp({
    super.key,
    required this.store,
    required this.windowController,
  });

  final ClipboardStore store;
  final WindowController windowController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider.value(value: windowController),
      ],
      child: MaterialApp(
        title: 'Clipboard',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const _RootView(),
      ),
    );
  }
}

class _RootView extends StatelessWidget {
  const _RootView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WindowController>();
    return controller.mode == WindowMode.full
        ? FullHistoryView(
            key: ValueKey(controller.navSeq),
            initialPage: controller.requestedPage,
          )
        : const PopupView();
  }
}
