import 'dart:io' show Platform;

import 'package:window_manager/window_manager.dart';

/// Native implementation of the pin-window feature.
///
/// Selected on every platform where `dart:io` is available (Windows, macOS,
/// Linux, Android, iOS). The `window_manager` plugin, however, is only
/// implemented for *desktop* OSes — calling it on Android/iOS throws a
/// `MissingPluginException`. [supportsAlwaysOnTop] therefore returns `true`
/// only on desktop, and every other method early-returns when the feature
/// isn't supported. Callers should also hide the UI affordance when
/// [supportsAlwaysOnTop] is `false` (see [PinWindowButton]).
class WindowPin {
  const WindowPin();

  /// `true` only on desktop platforms where `window_manager` is implemented.
  bool get supportsAlwaysOnTop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Initializes the `window_manager` plugin. Safe to call on any native
  /// platform; it's a no-op where the plugin isn't supported.
  Future<void> ensureInitialized() async {
    if (!supportsAlwaysOnTop) return;
    await windowManager.ensureInitialized();
  }

  /// Sets the always-on-top flag. No-op where unsupported.
  Future<void> setAlwaysOnTop(bool value) async {
    if (!supportsAlwaysOnTop) return;
    await windowManager.setAlwaysOnTop(value);
  }
}
