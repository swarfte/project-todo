import 'package:flutter/material.dart';
import 'package:project_todo/components/pin_window_button.dart';
import 'package:project_todo/logger.dart';
import 'package:project_todo/pages/project.dart';
import 'package:project_todo/preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // Required before any plugin (window_manager, SharedPreferences) use on
  // desktop platforms.
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();

  await windowManager.ensureInitialized();

  // Restore the user's last always-on-top choice so a pinned window stays
  // pinned across restarts. Seed the global notifier so every page's pin
  // button reflects the restored state.
  final alwaysOnTop = await ConfigService().getAlwaysOnTop();
  await windowManager.setAlwaysOnTop(alwaysOnTop);
  alwaysOnTopNotifier.value = alwaysOnTop;

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Todo',
      theme: ThemeData(),
      home: const HomePage(),
    );
  }
}
