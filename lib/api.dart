import 'package:pocketbase/pocketbase.dart';
import 'package:project_todo/preferences.dart';

class APIService {
  PocketBase? pb;
  RecordAuth? authData;

  APIService();

  Future<void> init() async {
    await refreshConfig();
  }

  Future<void> refreshConfig() async {
    final configService = ConfigService();
    String apiUrl = await configService.getApiUrl();
    pb = PocketBase(apiUrl);
  }

  Future<bool> login() async {
    if (pb == null) {
      await refreshConfig();
    }
    final configService = ConfigService();
    String username = await configService.getUsername();
    String password = await configService.getPassword();
    try {
      authData = await pb!
          .collection('users')
          .authWithPassword(username, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    if (pb != null) {
      pb!.authStore.clear();
      authData = null;
    }
  }

  Future<bool> isLoggedIn() async {
    if (pb == null) {
      await refreshConfig();
    }
    if (pb != null && pb!.authStore.isValid) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> authRefresh() async {
    if (pb != null && authData != null) {
      try {
        authData = await pb!.collection('users').authRefresh();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<List<RecordModel>> getProjects() async {
    if (pb == null) {
      await refreshConfig();
    }
    if (pb != null) {
      return await pb!.collection('projects').getFullList();
    } else {
      throw Exception('PocketBase instance is not initialized.');
    }
  }

  Future<List<RecordModel>> getTasks() async {
    if (pb == null) {
      await refreshConfig();
    }
    if (pb != null) {
      return await pb!.collection('tasks').getFullList();
    } else {
      throw Exception('PocketBase instance is not initialized.');
    }
  }
}
