import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart' show Rect;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  // singleton class to manage configuration settings
  ConfigService._internal();

  static const String _apiUrlKey = 'api_url';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _alwaysOnTopKey = 'always_on_top';

  // Persisted desktop window geometry (Windows / macOS). The four bounds keys
  // hold the window's *normal* (non-maximized, non-full-screen) outer frame;
  // the maximized / full-screen flags are stored alongside so the window can be
  // re-applied to the same state on the next launch. See `WindowGeometry`.
  static const String _windowXKey = 'window_x';
  static const String _windowYKey = 'window_y';
  static const String _windowWKey = 'window_w';
  static const String _windowHKey = 'window_h';
  static const String _windowMaximizedKey = 'window_maximized';
  static const String _windowFullScreenKey = 'window_fullscreen';

  // Defaults applied on first launch so a brand-new install can connect to
  // the seeded PocketBase backend without any setup. Once the user saves
  // their own values, the saved value always wins over these.
  static const String defaultApiUrl = 'http://127.0.0.1:8090';
  static const String defaultUsername = 'guest@example.com';
  static const String defaultPassword = 'guest1234';

  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  /// Prefix applied to every preference key.
  ///
  /// Debug builds launched with `flutter run` are namespaced under `dev_` so
  /// they read and write their own isolated sandbox of values and never
  /// overwrite the configuration saved by an installed release build.
  /// Release builds use the bare keys, preserving any configuration the user
  /// already has on disk. This keeps development and production data fully
  /// separate with no flags or extra setup.
  static const String _keyPrefix = kDebugMode ? 'dev_' : '';

  /// All keys owned by this service, used by [clearConfig].
  static const List<String> _ownedKeys = [
    _apiUrlKey,
    _usernameKey,
    _passwordKey,
    _alwaysOnTopKey,
    _windowXKey,
    _windowYKey,
    _windowWKey,
    _windowHKey,
    _windowMaximizedKey,
    _windowFullScreenKey,
  ];

  /// Returns the stored key with the current environment's prefix applied.
  String _key(String key) => '$_keyPrefix$key';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<void> saveApiUrl(String value) async {
    final preference = await _prefs();
    await preference.setString(_key(_apiUrlKey), value);
  }

  Future<String> getApiUrl() async {
    final preference = await _prefs();

    return preference.getString(_key(_apiUrlKey)) ?? defaultApiUrl;
  }

  Future<void> saveUsername(String value) async {
    final preference = await _prefs();
    await preference.setString(_key(_usernameKey), value);
  }

  Future<String> getUsername() async {
    final preference = await _prefs();
    return preference.getString(_key(_usernameKey)) ?? defaultUsername;
  }

  Future<void> savePassword(String value) async {
    final preference = await _prefs();
    await preference.setString(_key(_passwordKey), value);
  }

  Future<String> getPassword() async {
    final preference = await _prefs();
    return preference.getString(_key(_passwordKey)) ?? defaultPassword;
  }

  Future<void> saveAlwaysOnTop(bool value) async {
    final preference = await _prefs();
    await preference.setBool(_key(_alwaysOnTopKey), value);
  }

  Future<bool> getAlwaysOnTop() async {
    final preference = await _prefs();
    return preference.getBool(_key(_alwaysOnTopKey)) ?? false;
  }

  /// Persists the window's *normal* outer bounds (position + size).
  ///
  /// Callers must only pass a bounds measured while the window is in its
  /// normal (non-maximized, non-full-screen) state — a maximized frame would
  /// otherwise be restored as the default size.
  Future<void> saveWindowBounds(Rect bounds) async {
    final preference = await _prefs();
    await preference.setDouble(_key(_windowXKey), bounds.left);
    await preference.setDouble(_key(_windowYKey), bounds.top);
    await preference.setDouble(_key(_windowWKey), bounds.width);
    await preference.setDouble(_key(_windowHKey), bounds.height);
  }

  /// Returns the last saved normal bounds, or `null` if any component is
  /// missing (e.g. first launch, or a partial write).
  Future<Rect?> getWindowBounds() async {
    final preference = await _prefs();
    final x = preference.getDouble(_key(_windowXKey));
    final y = preference.getDouble(_key(_windowYKey));
    final w = preference.getDouble(_key(_windowWKey));
    final h = preference.getDouble(_key(_windowHKey));
    if (x == null || y == null || w == null || h == null) return null;
    return Rect.fromLTWH(x, y, w, h);
  }

  Future<void> saveWindowMaximized(bool value) async {
    final preference = await _prefs();
    await preference.setBool(_key(_windowMaximizedKey), value);
  }

  Future<bool> getWindowMaximized() async {
    final preference = await _prefs();
    return preference.getBool(_key(_windowMaximizedKey)) ?? false;
  }

  Future<void> saveWindowFullScreen(bool value) async {
    final preference = await _prefs();
    await preference.setBool(_key(_windowFullScreenKey), value);
  }

  Future<bool> getWindowFullScreen() async {
    final preference = await _prefs();
    return preference.getBool(_key(_windowFullScreenKey)) ?? false;
  }

  Future<void> clearConfig() async {
    final preference = await _prefs();
    // Only remove the keys owned by this environment. Never wipe the other
    // environment's data — e.g. clearing dev must not delete release config.
    for (final key in _ownedKeys) {
      await preference.remove(_key(key));
    }
  }
}
