import 'package:pocketbase/pocketbase.dart';
import 'package:project_todo/preferences.dart';

class APIService {
  PocketBase? _pb;
  RecordAuth? _authData;
  final ConfigService _configService = ConfigService();

  APIService();

  Future<void> init() async {
    await connectDB();
  }

  Future<bool> connectDB() async {
    String apiUrl = await _configService.getApiUrl();
    _pb = PocketBase(apiUrl);

    String username = await _configService.getUsername();
    String password = await _configService.getPassword();
    _authData = await _pb!
        .collection('users')
        .authWithPassword(username, password);

    return _authData != null && _pb!.authStore.isValid;
  }

  Future<bool> logout() async {
    if (_pb == null) {
      await connectDB();
    }
    _pb!.authStore.clear();
    _authData = null;
    return true;
  }

  Future<bool> isLoggedIn() async {
    if (_pb == null) {
      await connectDB();
    }
    return _pb!.authStore.isValid;
  }

  Future<bool> authRefresh() async {
    if (_pb == null) {
      await connectDB();
    }
    _authData = await _pb!.collection('users').authRefresh();

    return _pb!.authStore.isValid;
  }

  Future<List<RecordModel>> getProjects() async {
    if (_pb == null) {
      await connectDB();
    }

    return await _pb!.collection('projects').getFullList();
  }

  Future<List<RecordModel>> getTasks() async {
    if (_pb == null) {
      await connectDB();
    }

    return await _pb!.collection('tasks').getFullList();
  }
}
