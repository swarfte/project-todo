import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/app.dart';
import 'package:project_todo/core/log/logger.dart';
import 'package:project_todo/core/state/app_providers.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  // Required before any plugin (window_manager, SharedPreferences) use on
  // desktop platforms.
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();

  await windowManager.ensureInitialized();

  // Create the container now so we can restore the always-on-top preference
  // before the first frame — a pinned window stays pinned across restarts.
  final container = ProviderContainer();
  await container.read(alwaysOnTopProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainApp(),
    ),
  );
}
