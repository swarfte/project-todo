import 'package:pocketbase/pocketbase.dart';
import 'package:project_todo/preferences.dart';
import 'package:project_todo/models.dart';
import 'package:project_todo/adaptor.dart';

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
      'isFolded': false,
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

  /// Returns task counts keyed by project id: how many tasks each project
  /// has in total and how many of those are completed.
  ///
  /// PocketBase's REST API does not expose a COUNT aggregate, so this fetches
  /// all tasks in a single `getFullList` call and aggregates client-side.
  /// One network request regardless of how many projects exist.
  Future<Map<String, ({int total, int completed})>>
  getTaskCountsByProject() async {
    if (_pb == null) {
      await connectDB();
    }

    final records = await _pb!.collection('tasks').getFullList();

    final counts = <String, ({int total, int completed})>{};
    for (final r in records) {
      final json = r.toJson();
      final projectId = json['projectId'] as String?;
      if (projectId == null) continue;
      final isCompleted = json['isCompleted'] == true;
      final current = counts[projectId] ?? (total: 0, completed: 0);
      counts[projectId] = (
        total: current.total + 1,
        completed: current.completed + (isCompleted ? 1 : 0),
      );
    }
    return counts;
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
      'isFolded': task.isFolded,
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

  Future<List<RecordModel>> getStepListByTaskId(String taskId) async {
    if (_pb == null) {
      await connectDB();
    }

    return await _pb!
        .collection('steps')
        .getFullList(filter: 'taskId="$taskId"');
  }

  Future<bool> createStep(
    String name,
    String taskId, {
    String? previousStepId,
  }) async {
    if (_pb == null) {
      await connectDB();
    }

    final body = {
      'name': name,
      'taskId': taskId,
      'isCompleted': false,
      'previousStepId': previousStepId,
    };

    try {
      final response = await _pb!
          .collection('steps')
          .create(body: body, files: []);
      return response.id.isNotEmpty ? true : false;
    } catch (e) {
      print('Error when creating step: $e');
      return false;
    }
  }

  /// Inserts a new step into the chain directly after [afterStep], splicing
  /// it between [afterStep] and its current successor.
  ///
  /// The steps collection forms a linked list via `previousStepId`, so a
  /// mid-chain insert is two operations:
  ///   1. Create the new step with `previousStepId = afterStep.id`.
  ///   2. Re-point the step that currently followed `afterStep` so it now
  ///      follows the new step.
  ///
  /// Returns true only when both operations succeed. If the create succeeds
  /// but the re-link fails, the new step still exists in the DB (appended
  /// after `afterStep`) but the old successor is now orphaned into a second
  /// head — callers should reload and surface the partial failure so the
  /// user can fix it manually. A full rollback (delete the just-created
  /// step) is intentionally avoided because that delete can itself fail.
  ///
  /// [afterStep] is the full step object (not just an id) because the
  /// successor lookup needs the in-memory chain context the caller already
  /// has; the API doesn't refetch to avoid a race with concurrent edits.
  Future<bool> insertStep(String name, TaskStep afterStep) async {
    // Find the step that currently comes directly after `afterStep`, if any.
    // `afterStep` is treated as the tail if nothing points back at it.
    final successorId = await _findStepSuccessor(
      afterStep.taskId,
      afterStep.id,
    );

    // 1. Create the new step linked to `afterStep`.
    final created = await createStep(
      name,
      afterStep.taskId,
      previousStepId: afterStep.id,
    );
    if (!created) return false;

    // No successor → the new step is simply appended at the tail. Done.
    if (successorId == null) return true;

    // 2. Fetch the successor and re-link it to follow the newly created
    //    step. We can't reuse the new step's id from step 1 without a
    //    richer create response, so look it up: it's the only step whose
    //    previousStepId == afterStep.id AND isn't the known successor.
    final newStepId = await _findInsertedStepId(afterStep.id, successorId);
    if (newStepId == null) {
      // Couldn't locate the new step to relink against. Treat as partial
      // failure: the insert happened, the successor is now a second head.
      print('insertStep: created step but could not locate it to relink');
      return false;
    }

    final successor = await _getStepById(successorId);
    if (successor == null) return false;

    final relinked = TaskStep(
      id: successor.id,
      name: successor.name,
      taskId: successor.taskId,
      isCompleted: successor.isCompleted,
      createdAt: successor.createdAt,
      updatedAt: successor.updatedAt,
      previousStepId: newStepId,
    );
    return updateStep(relinked);
  }

  /// Returns the id of the step whose `previousStepId` equals [headId], i.e.
  /// the direct successor of [headId] in [taskId]'s chain. null if [headId]
  /// is currently the tail.
  Future<String?> _findStepSuccessor(String taskId, String headId) async {
    final records = await getStepListByTaskId(taskId);
    for (final r in records) {
      final json = r.toJson();
      if (json['previousStepId'] == headId) {
        return json['id'] as String?;
      }
    }
    return null;
  }

  /// After an insert, locates the id of the just-created step. It is the
  /// newest step whose `previousStepId == afterStepId` and whose id is not
  /// [knownSuccessorId] (the pre-existing successor, which also pointed at
  /// `afterStepId` before the re-link).
  Future<String?> _findInsertedStepId(
    String afterStepId,
    String knownSuccessorId,
  ) async {
    String? candidate;
    DateTime? newest;
    final records = await _pb!
        .collection('steps')
        .getFullList(filter: 'previousStepId="$afterStepId"');
    for (final r in records) {
      final json = r.toJson();
      final id = json['id'] as String?;
      if (id == null || id == knownSuccessorId) continue;
      // Prefer PocketBase's built-in `created` (or custom `createdAt`) to
      // pick the newest match, defensively parsed like the adaptor.
      final createdStr = (json['createdAt'] as String?)?.isNotEmpty == true
          ? json['createdAt'] as String?
          : json['created'] as String?;
      final created = createdStr != null && createdStr.isNotEmpty
          ? DateTime.parse(createdStr)
          : DateTime.fromMillisecondsSinceEpoch(0);
      if (newest == null || created.isAfter(newest)) {
        newest = created;
        candidate = id;
      }
    }
    return candidate;
  }

  /// Fetches a single step by id and maps it through the adaptor. Returns
  /// null if the step can't be found or parsed.
  Future<TaskStep?> _getStepById(String stepId) async {
    if (_pb == null) {
      await connectDB();
    }
    try {
      final record = await _pb!.collection('steps').getOne(stepId);
      return StepAdaptor.fromJson(record.toJson());
    } catch (e) {
      print('Error when fetching step $stepId: $e');
      return null;
    }
  }

  Future<bool> updateStep(TaskStep step) async {
    if (_pb == null) {
      await connectDB();
    }

    final body = {
      'name': step.name,
      'isCompleted': step.isCompleted,
      'previousStepId': step.previousStepId,
    };

    try {
      final response = await _pb!
          .collection('steps')
          .update(step.id, body: body, files: []);
      return response.id.isNotEmpty ? true : false;
    } catch (e) {
      print('Error when updating step: $e');
      return false;
    }
  }

  Future<bool> deleteStep(String stepId) async {
    if (_pb == null) {
      await connectDB();
    }

    try {
      await _pb!.collection('steps').delete(stepId);
      return true;
    } catch (e) {
      print('Error when deleting step: $e');
      return false;
    }
  }
}
