import 'package:project_todo/common/utils/step_orderer.dart';
import 'package:project_todo/core/log/logger.dart';
import 'package:project_todo/core/models/project.dart';
import 'package:project_todo/core/models/task.dart';
import 'package:project_todo/core/models/task_step.dart';
import 'package:project_todo/core/network/handler.dart';
import 'package:project_todo/core/network/interceptor.dart';
import 'package:project_todo/core/storage/preferences.dart';

/// High-level business API over PocketBase.
///
/// This class focuses purely on business logic (CRUD, task-tree duplication,
/// step-chain splicing, client-side aggregation). The two cross-cutting
/// concerns that used to be smeared across every method live elsewhere:
///
///  - Authentication / connection readiness → [AuthInterceptor.ensureReady],
///    called as the first line of each method (replacing the old
///    `if (_pb == null) connectDB()` guard).
///  - Error classification (200/400/401/404/500) → [guard], which wraps every
///    call so methods return an [ApiResult] instead of throwing or returning a
///    bare bool the caller can't distinguish from "network failed".
///
/// Writes return [ApiResult<bool>]; reads return [ApiResult] of the typed
/// model list. The VM layer maps these onto UI state and user-facing messages.
class ApiService {
  ApiService({AuthInterceptor? auth})
      : _auth = auth ?? AuthInterceptor(ConfigService());

  final AuthInterceptor _auth;

  /// A handle to the auth/connection layer, used by router redirects and the
  /// settings dialog to test/establish connectivity.
  AuthInterceptor get auth => _auth;

  // ---------------------------------------------------------------------------
  // Connection / auth passthroughs
  // ---------------------------------------------------------------------------

  /// Establishes the backend connection and authenticates. Delegated to the
  /// interceptor so business methods don't each repeat the guard.
  Future<ApiResult<bool>> connect() => _auth.connect();

  Future<bool> isLoggedIn() async {
    await _auth.ensureReady();
    return _auth.isReady;
  }

  Future<bool> logout() async {
    await _auth.logout();
    return true;
  }

  Future<bool> authRefresh() => _auth.authRefresh();

  // ---------------------------------------------------------------------------
  // Projects
  // ---------------------------------------------------------------------------

  Future<ApiResult<List<Project>>> getProjectList() => guard(() async {
        await _auth.ensureReady();
        final records = await _auth.pb.collection('projects').getFullList();
        return records.map((r) => Project.fromJson(r.toJson())).toList();
      });

  Future<ApiResult<bool>> createProject(String name) => guard(() async {
        await _auth.ensureReady();
        final body = {'name': name, 'userId': _auth.userId};
        final response = await _auth.pb
            .collection('projects')
            .create(body: body, files: []);
        return response.id.isNotEmpty;
      });

  /// Updates a project's editable fields.
  ///
  /// Only `name` is sent — the projects collection no longer carries a stored
  /// completion flag (a project is "completed" iff all its tasks are done,
  /// which the UI derives from task counts). PocketBase's autodate on
  /// `updatedAt` fires automatically on every write, so a rename also moves
  /// the project back to the top of the "by updatedAt" ordering.
  Future<ApiResult<bool>> updateProject(Project project) => guard(() async {
        await _auth.ensureReady();
        final response = await _auth.pb
            .collection('projects')
            .update(project.id, body: {'name': project.name}, files: []);
        return response.id.isNotEmpty;
      });

  Future<ApiResult<bool>> deleteProject(String projectId) => guard(() async {
        await _auth.ensureReady();
        await _auth.pb.collection('projects').delete(projectId);
        return true;
      });

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  Future<ApiResult<List<Task>>> getTaskList() => guard(() async {
        await _auth.ensureReady();
        final records = await _auth.pb.collection('tasks').getFullList();
        return records.map((r) => Task.fromJson(r.toJson())).toList();
      });

  Future<ApiResult<List<Task>>> getTaskListByProjectId(
    String projectId,
  ) => guard(() async {
        await _auth.ensureReady();
        final records = await _auth.pb
            .collection('tasks')
            .getFullList(filter: 'projectId="$projectId"');
        return records.map((r) => Task.fromJson(r.toJson())).toList();
      });

  Future<ApiResult<bool>> createTask(
    String name,
    String projectId, {
    String? previousTaskId,
    DateTime? dueDate,
  }) => guard(() async {
        await _auth.ensureReady();
        final body = {
          'name': name,
          'projectId': projectId,
          'userId': _auth.userId,
          'isCompleted': false,
          'dueDate': dueDate?.toIso8601String(),
          'previousTaskId': previousTaskId,
          'completedAt': null,
          'isFolded': false,
        };
        final response = await _auth.pb
            .collection('tasks')
            .create(body: body, files: []);
        final created = response.id.isNotEmpty;
        // Best-effort: bump the parent project's `updatedAt` so the project
        // page's "newest first" ordering surfaces the project that just got a
        // new task. PocketBase autodate only fires on writes to the projects
        // record itself, so this needs an explicit update. A failure here is
        // logged and swallowed — the task was still created successfully.
        if (created) {
          await _bumpProjectUpdatedAt(projectId);
        }
        return created;
      });

  Future<ApiResult<bool>> updateTask(Task task) => guard(() async {
        await _auth.ensureReady();
        final body = {
          'name': task.name,
          'isCompleted': task.isCompleted,
          'dueDate': task.dueDate?.toIso8601String(),
          'previousTaskId': task.previousTaskId,
          'completedAt': task.completedAt?.toIso8601String(),
          'isFolded': task.isFolded,
        };
        final response = await _auth.pb
            .collection('tasks')
            .update(task.id, body: body, files: []);
        return response.id.isNotEmpty;
      });

  Future<ApiResult<bool>> deleteTask(String taskId) => guard(() async {
        await _auth.ensureReady();
        await _auth.pb.collection('tasks').delete(taskId);
        return true;
      });

  /// Returns task counts keyed by project id: how many tasks each project
  /// has in total and how many of those are completed.
  ///
  /// PocketBase's REST API does not expose a COUNT aggregate, so this fetches
  /// all tasks in a single `getFullList` call and aggregates client-side.
  /// One network request regardless of how many projects exist.
  Future<ApiResult<Map<String, ({int total, int completed})>>>
      getTaskCountsByProject() => guard(() async {
            await _auth.ensureReady();
            final records = await _auth.pb.collection('tasks').getFullList();

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
          });

  // ---------------------------------------------------------------------------
  // Steps
  // ---------------------------------------------------------------------------

  Future<ApiResult<List<TaskStep>>> getStepListByTaskId(
    String taskId,
  ) => guard(() async {
        await _auth.ensureReady();
        final records = await _auth.pb
            .collection('steps')
            .getFullList(filter: 'taskId="$taskId"');
        return records.map((r) => TaskStep.fromJson(r.toJson())).toList();
      });

  /// Returns step counts keyed by task id: how many steps each task has in
  /// total and how many of those are completed.
  ///
  /// PocketBase's REST API does not expose a COUNT aggregate, so this fetches
  /// every step in a single `getFullList` call and aggregates client-side.
  /// One network request regardless of how many tasks exist. Tasks without
  /// steps are omitted from the map (callers treat absence as "no steps").
  Future<ApiResult<Map<String, ({int total, int completed})>>>
      getStepCountsByTask() => guard(() async {
            await _auth.ensureReady();
            final records = await _auth.pb.collection('steps').getFullList();

            final counts = <String, ({int total, int completed})>{};
            for (final r in records) {
              final json = r.toJson();
              final taskId = json['taskId'] as String?;
              if (taskId == null) continue;
              final isCompleted = json['isCompleted'] == true;
              final current = counts[taskId] ?? (total: 0, completed: 0);
              counts[taskId] = (
                total: current.total + 1,
                completed: current.completed + (isCompleted ? 1 : 0),
              );
            }
            return counts;
          });

  Future<ApiResult<bool>> createStep(
    String name,
    String taskId, {
    String? previousStepId,
  }) => guard(() async {
        await _auth.ensureReady();
        final body = {
          'name': name,
          'taskId': taskId,
          'isCompleted': false,
          'previousStepId': previousStepId,
        };
        final response = await _auth.pb
            .collection('steps')
            .create(body: body, files: []);
        return response.id.isNotEmpty;
      });

  Future<ApiResult<bool>> updateStep(TaskStep step) => guard(() async {
        await _auth.ensureReady();
        final body = {
          'name': step.name,
          'isCompleted': step.isCompleted,
          'previousStepId': step.previousStepId,
        };
        final response = await _auth.pb
            .collection('steps')
            .update(step.id, body: body, files: []);
        return response.id.isNotEmpty;
      });

  /// Sets `isCompleted = false` on every completed step belonging to [taskId].
  ///
  /// Only the completion flag is touched — step names and the
  /// `previousStepId` chain are left intact, so the order and content of the
  /// chain are unchanged. Steps already pending are skipped (no network
  /// round-trip). Returns the number of steps that were actually flipped to
  /// pending; individual failures are logged but don't abort the rest, since
  /// the caller reloads either way and the UI reflects whatever got through.
  Future<ApiResult<int>> unfinishAllSteps(String taskId) => guard(() async {
        await _auth.ensureReady();
        final records = await _auth.pb
            .collection('steps')
            .getFullList(filter: 'taskId="$taskId"');
        final steps =
            records.map((r) => TaskStep.fromJson(r.toJson())).toList();

        var succeeded = 0;
        for (final step in steps) {
          if (!step.isCompleted) continue; // already pending; nothing to do.

          final uncompleted = step.copyWith(isCompleted: false);
          final result = await updateStep(uncompleted);
          if (result.isSuccess) succeeded++;
        }
        return succeeded;
      });

  // ---------------------------------------------------------------------------
  // Task duplication
  // ---------------------------------------------------------------------------

  /// Deep-duplicates [original] and its entire subtree into the same project.
  ///
  /// The duplicate's root is a sibling of [original] (it reuses [original]'s
  /// `previousTaskId`), is named "`{original.name} copy`", and carries over
  /// the original's completion status, due date, fold state, and step chain —
  /// including each step's completion status. Every descendant task is
  /// duplicated the same way, with fresh `previousTaskId` links pointing at
  /// the newly created parents so the copied tree mirrors the original.
  ///
  /// Returns the id of the newly created root task, or null if that root
  /// could not be created. Failures deeper in the subtree are logged but do
  /// not abort the rest: the parts that did copy stay in the DB, and the
  /// caller's reload reconciles the view.
  Future<ApiResult<String?>> duplicateTask(Task original) => guard(() async {
        await _auth.ensureReady();
        final newRootId = await _createTaskRecord(
          name: '${original.name} copy',
          projectId: original.projectId,
          previousTaskId: original.previousTaskId,
          dueDate: original.dueDate,
          isCompleted: original.isCompleted,
          completedAt: original.completedAt,
          isFolded: original.isFolded,
        );
        if (newRootId == null) return null;

        await _copySteps(original.id, newRootId);
        await _duplicateChildren(original.id, newRootId);

        // A duplicate is a user-initiated creation, so bump the project's
        // `updatedAt` once (not per descendant) to surface the project at the
        // top of the project page's ordering.
        await _bumpProjectUpdatedAt(original.projectId);

        return newRootId;
      });

  /// Recursively duplicates every direct child of [originalId] under
  /// [newParentId], preserving each child's fields and step chain.
  Future<void> _duplicateChildren(
    String originalId,
    String newParentId,
  ) async {
    final children = await _getDirectChildTasks(originalId);
    for (final child in children) {
      final newChildId = await _createTaskRecord(
        name: child.name,
        projectId: child.projectId,
        previousTaskId: newParentId,
        dueDate: child.dueDate,
        isCompleted: child.isCompleted,
        completedAt: child.completedAt,
        isFolded: child.isFolded,
      );
      if (newChildId == null) continue;

      await _copySteps(child.id, newChildId);
      await _duplicateChildren(child.id, newChildId);
    }
  }

  /// Returns the tasks whose `previousTaskId` equals [parentId] — the direct
  /// successors of [parentId] in the task tree.
  Future<List<Task>> _getDirectChildTasks(String parentId) async {
    try {
      await _auth.ensureReady();
      final records = await _auth.pb
          .collection('tasks')
          .getFullList(filter: 'previousTaskId="$parentId"');
      return records.map((r) => Task.fromJson(r.toJson())).toList();
    } catch (e) {
      apiLogger.warning('Error fetching child tasks of $parentId', e);
      return const [];
    }
  }

  /// Copies the ordered step chain of [originalTaskId] into [newTaskId],
  /// preserving each step's name and completion status and rebuilding the
  /// `previousStepId` links so the new chain matches the original order.
  Future<void> _copySteps(String originalTaskId, String newTaskId) async {
    final result = await getStepListByTaskId(originalTaskId);
    final steps = result.dataOrNull ?? const <TaskStep>[];
    final ordered = orderSteps(steps);

    String? previousNewStepId;
    for (final step in ordered) {
      final newStepId = await _createStepRecord(
        name: step.name,
        taskId: newTaskId,
        previousStepId: previousNewStepId,
        isCompleted: step.isCompleted,
      );
      if (newStepId != null) {
        previousNewStepId = newStepId;
      }
    }
  }

  /// Creates a task record and returns its id, preserving completion status,
  /// fold state, due date, and completion timestamp. Unlike [createTask],
  /// which forces `isCompleted: false` and returns only a bool, this returns
  /// the new id so the caller can link descendants to it.
  Future<String?> _createTaskRecord({
    required String name,
    required String projectId,
    String? previousTaskId,
    DateTime? dueDate,
    required bool isCompleted,
    DateTime? completedAt,
    bool isFolded = false,
  }) async {
    try {
      await _auth.ensureReady();
      final body = {
        'name': name,
        'projectId': projectId,
        'userId': _auth.userId,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
        'previousTaskId': previousTaskId,
        'completedAt': completedAt?.toIso8601String(),
        'isFolded': isFolded,
      };
      final response = await _auth.pb
          .collection('tasks')
          .create(body: body, files: []);
      return response.id.isNotEmpty ? response.id : null;
    } catch (e) {
      apiLogger.warning('Error when creating task record', e);
      return null;
    }
  }

  /// Creates a step record and returns its id, preserving completion status.
  /// Unlike [createStep], which forces `isCompleted: false` and returns only
  /// a bool, this returns the new id so the caller can chain the next step.
  Future<String?> _createStepRecord({
    required String name,
    required String taskId,
    String? previousStepId,
    required bool isCompleted,
  }) async {
    try {
      await _auth.ensureReady();
      final body = {
        'name': name,
        'taskId': taskId,
        'isCompleted': isCompleted,
        'previousStepId': previousStepId,
      };
      final response = await _auth.pb
          .collection('steps')
          .create(body: body, files: []);
      return response.id.isNotEmpty ? response.id : null;
    } catch (e) {
      apiLogger.warning('Error when creating step record', e);
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Step chain splicing
  // ---------------------------------------------------------------------------

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
  Future<ApiResult<bool>> insertStep(String name, TaskStep afterStep) =>
      guard(() async {
        await _auth.ensureReady();
        // Find the step that currently comes directly after `afterStep`, if
        // any. `afterStep` is treated as the tail if nothing points back at
        // it.
        final successorId = await _findStepSuccessor(
          afterStep.taskId,
          afterStep.id,
        );

        // 1. Create the new step linked to `afterStep`.
        final created = await _rawCreateStep(
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
          apiLogger.warning(
            'insertStep: created step but could not locate it to relink',
          );
          return false;
        }

        final successor = await _getStepById(successorId);
        if (successor == null) return false;

        final relinked =
            successor.copyWith(previousStepId: newStepId);
        final result = await updateStep(relinked);
        return result.isSuccess;
      });

  /// Thin wrapper around the raw PocketBase create used by [insertStep]'s
  /// first half, so it can report a plain bool without an [ApiResult] wrapper.
  Future<bool> _rawCreateStep(
    String name,
    String taskId, {
    String? previousStepId,
  }) async {
    final result = await createStep(
      name,
      taskId,
      previousStepId: previousStepId,
    );
    return result.isSuccess;
  }

  /// Returns the id of the step whose `previousStepId` equals [headId], i.e.
  /// the direct successor of [headId] in [taskId]'s chain. null if [headId]
  /// is currently the tail.
  Future<String?> _findStepSuccessor(String taskId, String headId) async {
    final result = await getStepListByTaskId(taskId);
    final steps = result.dataOrNull ?? const <TaskStep>[];
    for (final s in steps) {
      if (s.previousStepId == headId) return s.id;
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
    await _auth.ensureReady();
    String? candidate;
    DateTime? newest;
    final records = await _auth.pb
        .collection('steps')
        .getFullList(filter: 'previousStepId="$afterStepId"');
    for (final r in records) {
      final json = r.toJson();
      final id = json['id'] as String?;
      if (id == null || id == knownSuccessorId) continue;
      // Prefer PocketBase's built-in `created` (or custom `createdAt`) to
      // pick the newest match, defensively parsed like the model converter.
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

  /// Fetches a single step by id and maps it through the model. Returns
  /// null if the step can't be found or parsed.
  Future<TaskStep?> _getStepById(String stepId) async {
    try {
      await _auth.ensureReady();
      final record = await _auth.pb.collection('steps').getOne(stepId);
      return TaskStep.fromJson(record.toJson());
    } catch (e) {
      apiLogger.warning('Error when fetching step $stepId', e);
      return null;
    }
  }

  /// Deletes a step and re-links the chain so order is preserved.
  ///
  /// The steps collection is a linked list via `previousStepId`, so a naive
  /// delete would orphan the deleted step's successor: its `previousStepId`
  /// would point at a now-missing id, turning it into a second chain head
  /// and scrambling the visible order.
  ///
  /// This performs the linked-list splice before deleting:
  ///   1. Fetch the step to learn its taskId and predecessor.
  ///   2. Find its successor (the step whose `previousStepId == stepId`).
  ///   3. If a successor exists, re-point it at the deleted step's
  ///      predecessor (or null if the deleted step was the head), bridging
  ///      the gap.
  ///   4. Delete the step.
  ///
  /// Returns false if the delete itself fails. Re-link failure is logged
  /// but does not block the delete, since leaving the step in place would
  /// be more confusing than a possibly-mislinked successor — the caller
  /// reloads either way and `orderSteps` is robust to extra heads.
  Future<ApiResult<bool>> deleteStep(String stepId) => guard(() async {
        await _auth.ensureReady();
        // Fetch the step we're about to delete so we know its task and
        // predecessor, then splice the gap before removing it.
        final step = await _getStepById(stepId);
        if (step != null) {
          final successorId =
              await _findStepSuccessor(step.taskId, stepId);
          if (successorId != null) {
            final successor = await _getStepById(successorId);
            if (successor != null) {
              // Bridge the gap: successor now follows the deleted step's
              // predecessor (null if the deleted step was the chain head).
              final relinked = successor.copyWith(
                previousStepId: step.previousStepId,
              );
              final relinkedOk = await updateStep(relinked);
              if (!relinkedOk.isSuccess) {
                apiLogger.warning(
                  'deleteStep: failed to re-link successor $successorId '
                  'before deleting $stepId; chain may split',
                );
              }
            }
          }
        }

        await _auth.pb.collection('steps').delete(stepId);
        return true;
      });

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Re-writes a project record so PocketBase's autodate refreshes its
  /// `updatedAt`. The name is fetched first (we don't have it here) and
  /// re-sent unchanged so no field is clobbered. Any failure is logged and
  /// swallowed; callers use this purely for the ordering side effect.
  Future<void> _bumpProjectUpdatedAt(String projectId) async {
    try {
      await _auth.ensureReady();
      final record = await _auth.pb.collection('projects').getOne(projectId);
      final name = record.toJson()['name'] as String?;
      await _auth.pb
          .collection('projects')
          .update(projectId, body: {'name': name}, files: []);
    } catch (e) {
      apiLogger.warning('Error when bumping project updatedAt', e);
    }
  }
}
