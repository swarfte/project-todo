import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  // singleton class to manage configuration settings
  ConfigService._internal();

  static const String _apiUrlKey = 'api_url';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';

  // Defaults applied on first launch so a brand-new install can connect to
  // the seeded PocketBase backend without any setup. Once the user saves
  // their own values, the saved value always wins over these.
  static const String defaultApiUrl = 'http://127.0.0.1:8090';
  static const String defaultUsername = 'admin@gmail.com';
  static const String defaultPassword = 'admin1234';

  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  Future<void> saveApiUrl(String value) async {
    final preference = await SharedPreferences.getInstance();
    await preference.setString(_apiUrlKey, value);
  }

  Future<String> getApiUrl() async {
    final preference = await SharedPreferences.getInstance();

    return preference.getString(_apiUrlKey) ?? defaultApiUrl;
  }

  Future<void> saveUsername(String value) async {
    final preference = await SharedPreferences.getInstance();
    await preference.setString(_usernameKey, value);
  }

  Future<String> getUsername() async {
    final preference = await SharedPreferences.getInstance();
    return preference.getString(_usernameKey) ?? defaultUsername;
  }

  Future<void> savePassword(String value) async {
    final preference = await SharedPreferences.getInstance();
    await preference.setString(_passwordKey, value);
  }

  Future<String> getPassword() async {
    final preference = await SharedPreferences.getInstance();
    return preference.getString(_passwordKey) ?? defaultPassword;
  }

  Future<void> clearConfig() async {
    final preference = await SharedPreferences.getInstance();
    await preference.clear();
  }
}
