import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/core/platform/window_pin.dart';
import 'package:project_todo/core/state/network_providers.dart';

/// The single [WindowPin] instance used across the app.
///
/// Resolves to the real `window_manager`-backed implementation on desktop
/// native builds, and to the no-op stub on web/Android (where the feature is
/// disabled). Centralised here so [main.dart], [AlwaysOnTopNotifier] and
/// [PinWindowButton] all agree on whether the feature is available.
final WindowPin windowPin = const WindowPin();

/// App-wide, persisted "always on top" window state.
///
/// Replaces the global `ValueNotifier<bool> alwaysOnTopNotifier` that used to
/// live inside `pin_window_button.dart`. Driving it through Riverpod means
/// every page's pin button subscribes to the same source of truth and the
/// choice survives restarts via [ConfigService] (read through
/// [configServiceProvider] using the notifier's [ref]).
///
/// The window call is delegated to [windowPin], which is a no-op on platforms
/// where the feature isn't supported (Android, web); the persisted preference
/// is still read/written everywhere so the choice round-trips on desktop.
class AlwaysOnTopNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Restores the saved preference and applies it to the window. Called once
  /// during app start so a pinned window stays pinned across restarts. The
  /// notifier is created with a sensible default of `false`; this fills in the
  /// persisted value asynchronously.
  Future<void> load() async {
    final value = await ref.read(configServiceProvider).getAlwaysOnTop();
    await windowPin.setAlwaysOnTop(value);
    state = value;
  }

  /// Toggles the flag, persists it, and updates the window immediately.
  Future<void> toggle() async {
    final value = !state;
    await windowPin.setAlwaysOnTop(value);
    await ref.read(configServiceProvider).saveAlwaysOnTop(value);
    state = value;
  }
}

/// The single source of truth for the window's always-on-top flag.
///
/// Implemented with the modern `Notifier`/`NotifierProvider` API (Riverpod 3.x
/// marks `StateNotifier` as legacy).
final NotifierProvider<AlwaysOnTopNotifier, bool> alwaysOnTopProvider =
    NotifierProvider(AlwaysOnTopNotifier.new);
