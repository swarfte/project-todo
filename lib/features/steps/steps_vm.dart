import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/common/utils/step_orderer.dart';
import 'package:project_todo/core/models/task.dart';
import 'package:project_todo/core/models/task_step.dart';
import 'package:project_todo/core/network/handler.dart';
import 'package:project_todo/core/state/network_providers.dart';
import 'package:project_todo/features/projects/projects_vm.dart';
import 'package:project_todo/features/tasks/tasks_vm.dart';

/// The ordered step chain for a single task.
class StepsView {
  const StepsView(this.steps);
  final List<TaskStep> steps;

  static const empty = StepsView([]);
}

/// Loads a task's step chain (ordered) and exposes step CRUD plus the
/// chain-splicing insert and bulk unfinish operations.
///
/// Parameterised by `taskId` (passed via the constructor, Riverpod 3.x style).
/// The page looks up the parent [Task] via [taskMetaProvider] since the router
/// only carries the id.
class StepsNotifier extends AsyncNotifier<StepsView> {
  StepsNotifier(this.taskId);

  final String taskId;

  @override
  Future<StepsView> build() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.getStepListByTaskId(taskId);

    final steps = result.dataOrNull ?? const [];
    return StepsView(orderSteps(steps));
  }

  /// Re-runs [build] to refresh the chain. `ref.invalidateSelf()` preserves
  /// the previous data as the loading fallback so the UI doesn't flash empty.
  Future<void> reload() async {
    ref.invalidateSelf();
  }

  /// Refreshes this task's chain *and* notifies the owning task tree.
  ///
  /// Step mutations change the task's step counts, which the task page reads via
  /// [tasksProvider]'s `stepCounts`. [tasksProvider] is long-lived
  /// (non-autoDispose) and parameterised by `projectId`, so without invalidating
  /// it here it keeps showing stale counts — e.g. finish a step, press back, and
  /// the task page's step indicator still reads the old number. We don't know
  /// the task's `projectId` here (the router carries only the id), so we look it
  /// up from any loaded task tree via [_lookupProjectId]; if no tree is loaded
  /// the task page will rebuild from scratch on next entry anyway.
  Future<void> _afterMutation() async {
    await reload();
    final projectId = _lookupProjectId();
    if (projectId != null) {
      ref.invalidate(tasksProvider(projectId));
    }
  }

  /// Finds the project that owns [taskId] by scanning currently-loaded task
  /// trees. Returns null if no tree has been loaded yet (the parent task page
  /// is on the stack when the step page is open, so this normally resolves).
  String? _lookupProjectId() {
    final projectsView = ref.read(projectsProvider).value;
    if (projectsView == null) return null;
    for (final row in projectsView.rows) {
      final tasksView = ref.read(tasksProvider(row.project.id)).value;
      if (tasksView == null) continue;
      for (final tree in tasksView.trees) {
        for (final node in tree) {
          if (node.task.id == taskId) return row.project.id;
        }
      }
    }
    return null;
  }

  Future<ApiResult<bool>> createStep(
    String name, {
    String? previousStepId,
  }) async {
    final result = await ref
        .read(apiServiceProvider)
        .createStep(name, taskId, previousStepId: previousStepId);
    if (result.isSuccess) await _afterMutation();
    return result;
  }

  /// Inserts a step mid-chain, splicing it directly after [afterStep].
  Future<ApiResult<bool>> insertStep(String name, TaskStep afterStep) async {
    final result =
        await ref.read(apiServiceProvider).insertStep(name, afterStep);
    if (result.isSuccess) await _afterMutation();
    return result;
  }

  Future<ApiResult<bool>> updateStep(TaskStep step) async {
    final result = await ref.read(apiServiceProvider).updateStep(step);
    if (result.isSuccess) await _afterMutation();
    return result;
  }

  Future<ApiResult<bool>> deleteStep(String stepId) async {
    final result = await ref.read(apiServiceProvider).deleteStep(stepId);
    if (result.isSuccess) await _afterMutation();
    return result;
  }

  /// Marks every completed step in this task as pending. Returns the count
  /// actually reset (individual failures are logged but don't abort the batch).
  Future<ApiResult<int>> unfinishAll() async {
    final result = await ref.read(apiServiceProvider).unfinishAllSteps(taskId);
    if (result.isSuccess) await _afterMutation();
    return result;
  }
}

/// Parameterised steps provider: one notifier per task. The concrete family
/// type is internal to Riverpod, so we let `final` infer it.
final stepsProvider =
    AsyncNotifierProvider.family<StepsNotifier, StepsView, String>(
  StepsNotifier.new,
);

/// Looks up a single [Task] by id across every loaded project's task tree, so
/// the step page can show the task name in its AppBar. Returns null if the
/// task's project tree hasn't been loaded.
///
/// Walking every task tree is O(tasks) and only runs on step-page entry, which
/// is fine for this app's scale; a dedicated task index provider could be
/// added if it ever shows up in profiles.
final taskMetaProvider =
    Provider.family<Task?, String>((ref, String taskId) {
  // We don't know which project the task belongs to, so scan all currently
  // loaded task trees. Riverpod only has entries for projects that have been
  // opened; the router ensures the parent task page is on the stack when the
  // step page is pushed, so its tree is loaded.
  final projectsView = ref.watch(projectsProvider).value;
  if (projectsView == null) return null;

  for (final row in projectsView.rows) {
    final tasksView = ref.watch(tasksProvider(row.project.id)).value;
    if (tasksView == null) continue;
    for (final tree in tasksView.trees) {
      for (final node in tree) {
        if (node.task.id == taskId) return node.task;
      }
    }
  }
  return null;
});
