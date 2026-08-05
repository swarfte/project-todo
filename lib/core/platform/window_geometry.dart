/// Platform abstraction for persisting and restoring the desktop window's
/// bounds (position + size) and its maximized / full-screen state.
///
/// Mirrors the strategy used by `window_pin.dart`: `window_manager` only ships
/// native implementations for desktop OSes, so this barrel hides it behind a
/// tiny interface and selects the implementation via a conditional export:
///
///   - Web (`dart:io` unavailable) → [window_geometry_stub], where every member
///     is a no-op and `isSupported` is `false`. `window_manager` is never
///     imported here, so the web build never references it.
///   - Native (`dart:io` available) → [window_geometry_io], which imports
///     `window_manager` for real but still guards every call behind
///     `isSupported`, so Android/iOS (where the plugin isn't implemented) never
///     invoke it.
///
/// Callers (`main.dart`, `WindowGeometryController`) depend only on this file
/// and never touch `window_manager` or `dart:io` directly.
library;

export 'window_geometry_stub.dart'
    if (dart.library.io) 'window_geometry_io.dart';
