import 'package:pocketbase/pocketbase.dart';
import 'package:project_todo/preferences.dart';

class APIService {
  PocketBase? _pb;
  RecordAuth? _authData;

  APIService();

  Future<void> init() async {
    await refreshConfig();
  }

  Future<void> refreshConfig() async {
    final configService = ConfigService();
    String apiUrl = await configService.getApiUrl();
    _pb = PocketBase(apiUrl);
  }

  Future<bool> login() async {
    if (_pb == null) {
      await refreshConfig();
    }
    final configService = ConfigService();
    String username = await configService.getUsername();
    String password = await configService.getPassword();
    try {
      _authData = await _pb!
          .collection('users')
          .authWithPassword(username, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    if (_pb != null) {
      _pb!.authStore.clear();
      _authData = null;
    }
  }

  Future<bool> isLoggedIn() async {
    if (_pb == null) {
      await refreshConfig();
    }
    if (_pb != null && _pb!.authStore.isValid) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> authRefresh() async {
    if (_pb != null && _authData != null) {
      try {
        _authData = await _pb!.collection('users').authRefresh();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<List<RecordModel>> getProjects() async {
    if (_pb == null) {
      await refreshConfig();
    }
    if (_pb != null) {
      return await _pb!.collection('projects').getFullList();
    } else {
      throw Exception('PocketBase instance is not initialized.');
    }
  }

  Future<List<RecordModel>> getTasks() async {
    if (_pb == null) {
      await refreshConfig();
    }
    if (_pb != null) {
      return await _pb!.collection('tasks').getFullList();
    } else {
      throw Exception('PocketBase instance is not initialized.');
    }
  }
}
