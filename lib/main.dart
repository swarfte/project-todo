import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/app.dart';
import 'package:project_todo/core/log/logger.dart';
import 'package:project_todo/core/state/app_providers.dart';

Future<void> main() async {
  // Required before any plugin (window_manager, SharedPreferences) use on
  // desktop platforms.
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();

  // Initialize the desktop window plugin. No-op (and skipped) on Android and
  // web, where the pin feature is disabled — see [windowPin].
  await windowPin.ensureInitialized();

  // Create the container now so we can restore the always-on-top preference
  // before the first frame — a pinned window stays pinned across restarts.
  // The restore is only meaningful where the feature is supported; elsewhere
  // the notifier's window call is a no-op, but we still run it so the state
  // reflects the persisted value if the app is later opened on desktop.
  final container = ProviderContainer();
  if (windowPin.supportsAlwaysOnTop) {
    await container.read(alwaysOnTopProvider.notifier).load();
  }

  // Restore the saved window size/position (and maximized / full-screen state)
  // before the first frame, so the window appears where the user left it
  // rather than at the default size. No-op on Android / web — see
  // [WindowGeometryController]. Initializing the geometry plugin is idempotent
  // with the pin plugin's init above.
  final geometry = container.read(windowGeometryControllerProvider);
  await windowGeometry.ensureInitialized();
  await geometry.restore();
  geometry.startTracking();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainApp(),
    ),
  );
}
