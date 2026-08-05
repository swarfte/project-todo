import 'dart:io' show Platform;

import 'package:flutter/material.dart' show Rect;
import 'package:window_manager/window_manager.dart';

/// Native implementation of the window-geometry feature.
///
/// Selected on every platform where `dart:io` is available (Windows, macOS,
/// Linux, Android, iOS). The `window_manager` plugin, however, is only
/// implemented for *desktop* OSes — calling it on Android/iOS throws a
/// `MissingPluginException`. [isSupported] therefore returns `true` only on
/// desktop, and every other method early-returns when the feature isn't
/// supported. This mirrors [WindowPin] in `window_pin_io.dart`.
///
/// Not `const`-constructible (unlike [WindowPin]) because it owns the single
/// [_listener] it registers with `window_manager`.
class WindowGeometry {
  WindowGeometry();

  /// `true` only on desktop platforms where `window_manager` is implemented.
  bool get isSupported =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Initializes the `window_manager` plugin. Safe to call on any native
  /// platform; it's a no-op where the plugin isn't supported. Idempotent, so
  /// calling alongside `WindowPin.ensureInitialized` is harmless.
  Future<void> ensureInitialized() async {
    if (!isSupported) return;
    await windowManager.ensureInitialized();
  }

  /// Returns the window's outer bounds (top-left position + size) in logical
  /// coordinates. Returns `null` where unsupported.
  Future<Rect?> getBounds() async {
    if (!isSupported) return null;
    return windowManager.getBounds();
  }

  /// Moves and resizes the window to [bounds]. No-op where unsupported.
  Future<void> setBounds(Rect bounds) async {
    if (!isSupported) return;
    await windowManager.setBounds(bounds);
  }

  /// Whether the window is currently maximized. `false` where unsupported.
  Future<bool> isMaximized() async {
    if (!isSupported) return false;
    return windowManager.isMaximized();
  }

  /// Whether the window is currently in full-screen mode. `false` where
  /// unsupported.
  Future<bool> isFullScreen() async {
    if (!isSupported) return false;
    return windowManager.isFullScreen();
  }

  /// Maximizes the window. No-op where unsupported.
  Future<void> maximize() async {
    if (!isSupported) return;
    await windowManager.maximize();
  }

  /// Toggles full-screen mode. No-op where unsupported.
  Future<void> setFullScreen(bool value) async {
    if (!isSupported) return;
    await windowManager.setFullScreen(value);
  }

  /// Starts forwarding window move/resize/maximize/full-screen events to
  /// [onGeometryChanged]. Safe to call on any platform; it's a no-op where
  /// unsupported. Re-calling replaces the previous callback. The callback is
  /// invoked after the WM round-trip reports the change, so callers can
  /// re-query the live bounds.
  void startTracking(void Function() onGeometryChanged) {
    if (!isSupported) return;
    // Replace any previously installed listener so we never accumulate them.
    if (_listener != null) {
      windowManager.removeListener(_listener!);
    }
    _listener = _TrackingListener(onGeometryChanged);
    windowManager.addListener(_listener!);
  }

  /// Removes the tracking listener installed by [startTracking]. No-op where
  /// unsupported or if no listener was ever installed. Rarely needed — the
  /// process is exiting by the time state tracking is irrelevant.
  void stopTracking() {
    if (!isSupported || _listener == null) return;
    windowManager.removeListener(_listener!);
    _listener = null;
  }

  _TrackingListener? _listener;
}

/// Forwards every geometry-relevant window event to a single callback.
///
/// `window_manager` invokes these after the native window has settled into its
/// new state, so the handler can safely re-read `getBounds()` / `isMaximized()`
/// to capture the post-change geometry.
class _TrackingListener implements WindowListener {
  _TrackingListener(this._onChanged);

  final void Function() _onChanged;

  @override
  void onWindowMove() => _onChanged();

  @override
  void onWindowMoved() => _onChanged();

  @override
  void onWindowResize() => _onChanged();

  @override
  void onWindowResized() => _onChanged();

  @override
  void onWindowMaximize() => _onChanged();

  @override
  void onWindowUnmaximize() => _onChanged();

  @override
  void onWindowEnterFullScreen() => _onChanged();

  @override
  void onWindowLeaveFullScreen() => _onChanged();

  // Events we don't care about — required because `WindowListener` is an
  // abstract mixin class and we `implement` it, so every member must be
  // provided even though the base class gives them empty bodies. Keeping them
  // explicit (rather than relying on that) also documents the choice.
  @override
  void onWindowClose() {}

  @override
  void onWindowFocus() {}

  @override
  void onWindowBlur() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowDocked() {}

  @override
  void onWindowUndocked() {}

  @override
  void onWindowEvent(String eventName) {}
}
