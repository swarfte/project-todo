import 'package:pocketbase/pocketbase.dart';
import 'package:project_todo/preferences.dart';
import 'package:project_todo/models.dart';

class APIService {
  // singleton class
  APIService._internal();
  PocketBase? _pb;
  RecordAuth? _authData;
  final ConfigService _configService = ConfigService();

  static final APIService _instance = APIService._internal();

  factory APIService() {
    return _instance;
  }

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

  Future<List<RecordModel>> getProjectList() async {
    if (_pb == null) {
      await connectDB();
    }

    return await _pb!.collection('projects').getFullList();
  }

  Future<List<RecordModel>> getTaskList() async {
    if (_pb == null) {
      await connectDB();
    }

    return await _pb!.collection('tasks').getFullList();
  }

  Future<List<RecordModel>> getStepList() async {
    if (_pb == null) {
      await connectDB();
    }

    return await _pb!.collection('steps').getFullList();
  }

  Future<bool> createProject(String name) async {
    if (_pb == null) {
      await connectDB();
    }

    final body = {
      'name': name,
      "isCompleted": false,
      "userId": _authData!.record.id,
      "completedAt": null,
    };

    // print('user id: ${_authData!.record.id}');

    try {
      final response = await _pb!
          .collection('projects')
          .create(body: body, files: []);
      return response.id.isNotEmpty ? true : false;
    } catch (e) {
      print('Error when creating project: $e');
      return false;
    }
  }

  Future<bool> createTask(
    String name,
    String projectId, {
    String? previousTaskId,
    DateTime? dueDate,
  }) async {
    if (_pb == null) {
      await connectDB();
    }

    final body = {
      'name': name,
      'projectId': projectId,
      'userId': _authData!.record.id,
      'isCompleted': false,
      'dueDate': dueDate?.toIso8601String(),
      'previousTaskId': previousTaskId,
      'completedAt': null,
    };

    try {
      final response = await _pb!
          .collection('tasks')
          .create(body: body, files: []);
      return response.id.isNotEmpty ? true : false;
    } catch (e) {
      print('Error when creating task: $e');
      return false;
    }
  }

  Future<bool> updateProject(Project project) async {
    if (_pb == null) {
      await connectDB();
    }

    final body = {'name': project.name, 'isCompleted': project.isCompleted};

    try {
      final response = await _pb!
          .collection('projects')
          .update(project.id, body: body, files: []);
      return response.id.isNotEmpty ? true : false;
    } catch (e) {
      print('Error when updating project: $e');
      return false;
    }
  }

  Future<bool> deleteProject(String projectId) async {
    if (_pb == null) {
      await connectDB();
    }

    try {
      await _pb!.collection('projects').delete(projectId);
      return true;
    } catch (e) {
      print('Error when deleting project: $e');
      return false;
    }
  }

  Future<List<RecordModel>> getTaskListByProjectId(String projectId) async {
    if (_pb == null) {
      await connectDB();
    }

    return await _pb!
        .collection('tasks')
        .getFullList(filter: 'projectId="$projectId"');
  }

  Future<bool> updateTask(Task task) async {
    if (_pb == null) {
      await connectDB();
    }

    final body = {
      'name': task.name,
      'isCompleted': task.isCompleted,
      'dueDate': task.dueDate?.toIso8601String(),
      'previousTaskId': task.previousTaskId,
      'completedAt': task.completedAt?.toIso8601String(),
    };

    try {
      final response = await _pb!
          .collection('tasks')
          .update(task.id, body: body, files: []);
      return response.id.isNotEmpty ? true : false;
    } catch (e) {
      print('Error when updating task: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    if (_pb == null) {
      await connectDB();
    }

    try {
      await _pb!.collection('tasks').delete(taskId);
      return true;
    } catch (e) {
      print('Error when deleting task: $e');
      return false;
    }
  }
}
