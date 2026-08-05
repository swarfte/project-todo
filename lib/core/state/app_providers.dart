import 'dart:async' show Timer;

import 'package:flutter/material.dart' show Rect;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:project_todo/core/platform/window_geometry.dart';
import 'package:project_todo/core/platform/window_pin.dart';
import 'package:project_todo/core/state/network_providers.dart';
import 'package:project_todo/core/storage/preferences.dart';

/// The single [WindowPin] instance used across the app.
///
/// Resolves to the real `window_manager`-backed implementation on desktop
/// native builds, and to the no-op stub on web/Android (where the feature is
/// disabled). Centralised here so [main.dart], [AlwaysOnTopNotifier] and
/// [PinWindowButton] all agree on whether the feature is available.
final WindowPin windowPin = const WindowPin();

/// The single [WindowGeometry] instance used across the app.
///
/// Same conditional-export story as [windowPin]: real `window_manager`-backed
/// implementation on desktop native builds, no-op stub on web/Android. Owns the
/// tracking listener it registers with the plugin, so it is not `const`.
final WindowGeometry windowGeometry = WindowGeometry();

final Logger _windowLogger = Logger('project_todo.window');

/// Minimum sane window size used when sanity-clamping a restored frame. Guards
/// against restoring an absurd (e.g. zero or negative) size from corrupted or
/// hand-edited preferences.
const double _minWindowDimension = 200;

/// Owns the "remember window bounds across launches" feature for desktop
/// builds (Windows / macOS).
///
/// On launch [restore] reads the last saved *normal* bounds plus the maximized
/// / full-screen flags from [ConfigService] and re-applies them. [startTracking]
/// then listens to window move/resize/maximize/full-screen events and persists
/// the geometry, throttled so a drag doesn't spam SharedPreferences. The
/// maximized / full-screen flags are written immediately whenever they flip.
///
/// Everything is a no-op on platforms where [windowGeometry] isn't supported
/// (Android, web), and the choice still round-trips through [ConfigService] so
/// it carries across to a later desktop launch.
///
/// Not Riverpod state — the window geometry isn't something the widget tree
/// needs to react to. It's exposed as a plain class via
/// [windowGeometryControllerProvider] purely so DI stays consistent (a single
/// instance, overridable in tests) and so [main.dart] can obtain one without
/// constructing [ConfigService] itself.
class WindowGeometryController {
  WindowGeometryController(this._config);

  final ConfigService _config;

  /// Coalesces a burst of move/resize events into a single SharedPreferences
  /// write. `null` while idle.
  Timer? _persistTimer;

  /// Restores the saved window state on startup. No-op where unsupported.
  Future<void> restore() async {
    if (!windowGeometry.isSupported) return;

    try {
      final maximized = await _config.getWindowMaximized();
      final fullScreen = await _config.getWindowFullScreen();
      final bounds = await _config.getWindowBounds();

      if (bounds != null) {
        final clamped = _clampBounds(bounds);
        // Apply the normal frame first; if the window was maximized / full
        // screen, the subsequent calls re-apply that state on top, so that
        // un-maximizing later returns to the correct restored size.
        await windowGeometry.setBounds(clamped);
      }
      if (fullScreen) {
        await windowGeometry.setFullScreen(true);
      } else if (maximized) {
        // Don't maximize while full-screen is requested — full-screen wins.
        await windowGeometry.maximize();
      }
    } catch (error, stack) {
      _windowLogger.warning('Failed to restore window geometry', error, stack);
    }
  }

  /// Begins persisting window geometry changes. No-op where unsupported.
  void startTracking() {
    if (!windowGeometry.isSupported) return;
    windowGeometry.startTracking(_onGeometryChanged);
  }

  /// Stops persisting geometry changes and cancels any pending write. Called
  /// on app teardown; rarely needed since the process is exiting anyway.
  void dispose() {
    windowGeometry.stopTracking();
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  Future<void> _onGeometryChanged() async {
    if (!windowGeometry.isSupported) return;
    try {
      // The maximized / full-screen flags are cheap and binary — persist them
      // immediately so a state flip is never lost to the throttle window.
      final maximized = await windowGeometry.isMaximized();
      final fullScreen = await windowGeometry.isFullScreen();
      await _config.saveWindowMaximized(maximized);
      await _config.saveWindowFullScreen(fullScreen);

      // Only update the *normal* bounds when the window is in its normal
      // state. While maximized or full-screen, getBounds() returns the
      // filled-screen frame, not the restore size — overwriting here would
      // make un-maximize jump to the wrong size next launch.
      if (maximized || fullScreen) {
        _persistTimer?.cancel();
        _persistTimer = null;
        return;
      }

      // Throttle the normal-bounds write so a continuous drag/resize coalesces
      // into one SharedPreferences hit 400 ms after the last event. That is
      // well below any realistic relaunch latency, so at worst a relaunch
      // within 400 ms of the final move loses a tiny amount of position.
      _persistTimer?.cancel();
      _persistTimer = Timer(const Duration(milliseconds: 400), () async {
        _persistTimer = null;
        final bounds = await windowGeometry.getBounds();
        if (bounds != null) {
          await _config.saveWindowBounds(bounds);
        }
      });
    } catch (error, stack) {
      _windowLogger.warning('Failed to persist window geometry', error, stack);
    }
  }

  /// Guards against restoring a degenerate frame. Size is clamped to a sane
  /// minimum; position is left alone except for wildly negative values (which
  /// would push the title bar off-screen on Windows).
  ///
  /// NOTE: multi-monitor edge cases (window saved on a now-disconnected
  /// display) are *not* handled — `window_manager` 0.5.2 exposes no display
  /// enumeration API. The restored position may be off-screen in that case,
  /// though the OS usually keeps enough on-screen to grab the title bar.
  Rect _clampBounds(Rect bounds) {
    final width = bounds.width < _minWindowDimension
        ? _minWindowDimension
        : bounds.width;
    final height = bounds.height < _minWindowDimension
        ? _minWindowDimension
        : bounds.height;
    final left = bounds.left < -10000 ? 0.0 : bounds.left;
    final top = bounds.top < -10000 ? 0.0 : bounds.top;
    return Rect.fromLTWH(left, top, width, height);
  }
}

/// The single [WindowGeometryController], wired to [configServiceProvider].
final Provider<WindowGeometryController> windowGeometryControllerProvider =
    Provider(
  (ref) => WindowGeometryController(ref.watch(configServiceProvider)),
);


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
