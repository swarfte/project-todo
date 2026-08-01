import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  // singleton class to manage configuration settings
  ConfigService._internal();

  static const String _apiUrlKey = 'api_url';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
  static const String _alwaysOnTopKey = 'always_on_top';

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

  Future<void> clearConfig() async {
    final preference = await _prefs();
    // Only remove the keys owned by this environment. Never wipe the other
    // environment's data — e.g. clearing dev must not delete release config.
    for (final key in _ownedKeys) {
      await preference.remove(_key(key));
    }
  }
}
