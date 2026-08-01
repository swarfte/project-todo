/// Platform abstraction for the "pin window / always-on-top" feature.
library;
///
/// The feature is backed by `window_manager`, which only ships native
/// implementations for desktop OSes. Calling it on Android or the web throws at
/// runtime (`MissingPluginException` on Android; the plugin has no web target
/// at all), so this barrel hides `window_manager` behind a tiny interface and
/// selects the implementation via a conditional export:
///
///   - Web (`dart:io` unavailable) → [window_pin_stub], where every member is a
///     no-op and `supportsAlwaysOnTop` is `false`. `window_manager` is never
///     even imported here, so the web build never references it.
///   - Native (`dart:io` available) → [window_pin_io], which imports
///     `window_manager` for real but still guards every call behind
///     `supportsAlwaysOnTop` so Android (where the plugin isn't implemented)
///     never invokes it.
///
/// Callers (`main.dart`, `AlwaysOnTopNotifier`, `PinWindowButton`) depend only
/// on this file and never touch `window_manager` or `dart:io` directly.
export 'window_pin_stub.dart'
    if (dart.library.io) 'window_pin_io.dart';
