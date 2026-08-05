import 'package:flutter/material.dart' show Rect;

/// Web / unsupported-platform stub for the window-geometry feature.
///
/// Selected whenever `dart:io` is *unavailable* (i.e. the web). `window_manager`
/// has no web target, so this file must not import it — otherwise the web build
/// would fail trying to resolve the plugin. Every member is a no-op and
/// [isSupported] is `false`. The interface mirrors [WindowGeometry] in
/// `window_geometry_io.dart` exactly.
class WindowGeometry {
  WindowGeometry();

  bool get isSupported => false;

  Future<void> ensureInitialized() async {}

  /// Always `null`: there is no window to describe on the web.
  Future<Rect?> getBounds() async => null;

  Future<void> setBounds(Rect bounds) async {}

  Future<bool> isMaximized() async => false;

  Future<bool> isFullScreen() async => false;

  Future<void> maximize() async {}

  Future<void> setFullScreen(bool value) async {}

  void startTracking(void Function() onGeometryChanged) {}

  void stopTracking() {}
}
