/// Web / unsupported-platform stub for the pin-window feature.
///
/// Selected whenever `dart:io` is *unavailable* (i.e. the web). `window_manager`
/// has no web target, so this file must not import it — otherwise the web build
/// would fail trying to resolve the plugin. Every member is a no-op and
/// [supportsAlwaysOnTop] is `false`, which also signals the UI to hide the pin
/// button. The interface mirrors [WindowPin] in `window_pin_io.dart` exactly.
class WindowPin {
  const WindowPin();

  bool get supportsAlwaysOnTop => false;

  Future<void> ensureInitialized() async {}

  Future<void> setAlwaysOnTop(bool value) async {}
}
