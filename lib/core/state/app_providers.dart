import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/core/storage/preferences.dart';
import 'package:project_todo/core/state/network_providers.dart';
import 'package:window_manager/window_manager.dart';

/// App-wide, persisted "always on top" window state.
///
/// Replaces the global `ValueNotifier<bool> alwaysOnTopNotifier` that used to
/// live inside `pin_window_button.dart`. Driving it through Riverpod means
/// every page's pin button subscribes to the same source of truth and the
/// choice survives restarts via [ConfigService].
class AlwaysOnTopNotifier extends StateNotifier<bool> {
  AlwaysOnTopNotifier(this._configService) : super(false);

  final ConfigService _configService;

  /// Restores the saved preference and applies it to the window. Called once
  /// during app start so a pinned window stays pinned across restarts.
  Future<void> load() async {
    final value = await _configService.getAlwaysOnTop();
    await windowManager.setAlwaysOnTop(value);
    state = value;
  }

  /// Toggles the flag, persists it, and updates the window immediately.
  Future<void> toggle() async {
    final value = !state;
    await windowManager.setAlwaysOnTop(value);
    await _configService.saveAlwaysOnTop(value);
    state = value;
  }
}

/// The single source of truth for the window's always-on-top flag.
final StateNotifierProvider<AlwaysOnTopNotifier, bool> alwaysOnTopProvider =
    StateNotifierProvider(
  (ref) => AlwaysOnTopNotifier(ref.watch(configServiceProvider)),
);
