import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/common/utils/task_forest.dart';
import 'package:project_todo/core/models/project.dart';
import 'package:project_todo/core/models/task.dart';
import 'package:project_todo/core/network/handler.dart';
import 'package:project_todo/core/state/network_providers.dart';
import 'package:project_todo/features/projects/projects_vm.dart';

/// A task forest flattened for display: per-tree groups plus the raw counts
/// the timeline widget needs. Mirrors what the old task page computed inline.
class TasksView {
  const TasksView({required this.trees, required this.stepCounts});

  /// Trees sorted by urgency, each a list of [FlatTaskNode] in pre-order.
  final List<List<FlatTaskNode>> trees;

  /// Step counts keyed by task id (only tasks with steps appear here).
  final Map<String, ({int total, int completed})> stepCounts;

  static const empty = TasksView(trees: [], stepCounts: {});
}

/// Loads a project's task tree together with global step counts and exposes
/// the task CRUD operations the task page needs.
///
/// Parameterised by `projectId` (passed via the constructor, Riverpod 3.x
/// style) because each project has its own task page. The page also looks up
/// the project's name via [projectMetaProvider] (the router only carries the
/// id).
class TasksNotifier extends AsyncNotifier<TasksView> {
  TasksNotifier(this.projectId);

  final String projectId;

  @override
  Future<TasksView> build() async {
    final api = ref.read(apiServiceProvider);

    // Fetch tasks (scoped to this project) and step counts (global, joined by
    // task id) together. Tasks without steps simply won't have an entry.
    final results = await Future.wait([
      api.getTaskListByProjectId(projectId),
      api.getStepCountsByTask(),
    ]);
    final tasksResult = results[0] as ApiResult<List<Task>>;
    final countsResult =
        results[1] as ApiResult<Map<String, ({int total, int completed})>>;

    final tasks = tasksResult.dataOrNull ?? const [];
    final counts = countsResult.dataOrNull ?? const {};

    return TasksView(
      trees: buildTaskForest(tasks, counts),
      stepCounts: counts,
    );
  }

  /// Re-runs [build] to refresh the tree. `ref.invalidateSelf()` preserves the
  /// previous data as the loading fallback so the UI doesn't flash empty.
  Future<void> reload() async {
    ref.invalidateSelf();
  }

  Future<ApiResult<bool>> createTask(
    String name, {
    String? previousTaskId,
    DateTime? dueDate,
  }) async {
    final result = await ref.read(apiServiceProvider).createTask(
          name,
          projectId,
          previousTaskId: previousTaskId,
          dueDate: dueDate,
        );
    if (result.isSuccess) await reload();
    return result;
  }

  Future<ApiResult<bool>> updateTask(Task task) async {
    final result = await ref.read(apiServiceProvider).updateTask(task);
    if (result.isSuccess) await reload();
    return result;
  }

  Future<ApiResult<bool>> deleteTask(String taskId) async {
    final result = await ref.read(apiServiceProvider).deleteTask(taskId);
    if (result.isSuccess) await reload();
    return result;
  }

  Future<ApiResult<String?>> duplicateTask(Task original) async {
    final result = await ref.read(apiServiceProvider).duplicateTask(original);
    if (result.isSuccess) await reload();
    return result;
  }
}

/// Parameterised tasks provider: one notifier per project. The concrete family
/// type is internal to Riverpod, so we let `final` infer it.
final tasksProvider =
    AsyncNotifierProvider.family<TasksNotifier, TasksView, String>(
  TasksNotifier.new,
);

/// The set of tasks belonging to [projectId], unflattened, so the create/edit
/// dialogs can populate a "previous task" selector without refetching.
final taskListProvider =
    Provider.family<List<Task>, String>((ref, String projectId) {
  final asyncView = ref.watch(tasksProvider(projectId));
  final view = asyncView.value;
  if (view == null) return const [];

  // Collect every task across all trees (the forest helpers only kept
  // FlatTaskNode wrappers).
  final seen = <String>{};
  final tasks = <Task>[];
  for (final tree in view.trees) {
    for (final node in tree) {
      if (seen.add(node.task.id)) tasks.add(node.task);
    }
  }
  return tasks;
});

/// Looks up a single [Project] by id from the projects list, so the task page
/// can show the project name in its AppBar without the router passing a whole
/// object. Returns null if the project isn't loaded (yet).
final projectMetaProvider =
    Provider.family<Project?, String>((ref, String projectId) {
  final view = ref.watch(projectsProvider).value;
  if (view == null) return null;
  for (final row in view.rows) {
    if (row.project.id == projectId) return row.project;
  }
  return null;
});
