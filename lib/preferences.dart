import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  // singleton class to manage configuration settings
  ConfigService._internal();

  static const String _apiUrlKey = 'api_url';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';
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

    return preference.getString(_apiUrlKey) ?? '';
  }

  Future<void> saveUsername(String value) async {
    final preference = await SharedPreferences.getInstance();
    await preference.setString(_usernameKey, value);
  }

  Future<String> getUsername() async {
    final preference = await SharedPreferences.getInstance();
    return preference.getString(_usernameKey) ?? '';
  }

  Future<void> savePassword(String value) async {
    final preference = await SharedPreferences.getInstance();
    await preference.setString(_passwordKey, value);
  }

  Future<String> getPassword() async {
    final preference = await SharedPreferences.getInstance();
    return preference.getString(_passwordKey) ?? '';
  }

  Future<void> clearConfig() async {
    final preference = await SharedPreferences.getInstance();
    await preference.clear();
  }
}
