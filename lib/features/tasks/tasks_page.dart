import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/common/utils/date_formatter.dart';
import 'package:project_todo/common/widgets/pin_window_button.dart';
import 'package:project_todo/common/widgets/success_snackbar.dart';
import 'package:project_todo/core/models/task.dart';
import 'package:project_todo/core/router/routes.dart';
import 'package:project_todo/features/tasks/tasks_vm.dart';
import 'package:project_todo/features/tasks/widgets/chain_timeline.dart';
import 'package:project_todo/features/tasks/widgets/create_task_dialog.dart';
import 'package:project_todo/features/tasks/widgets/edit_task_dialog.dart';

/// A single project's task tree.
///
/// Subscribes to [tasksProvider] (parameterised by `projectId`) and renders the
/// flattened forest via [ChainTimeline]. The AppBar title comes from
/// [projectMetaProvider] since the router only carries the id. All mutations
/// go through the VM, so this widget holds no API or business logic.
class TasksPage extends ConsumerWidget {
  const TasksPage({super.key, required this.projectId});

  final String projectId;

  Future<void> _openCreateTaskDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (context) => CreateTaskDialog(projectId: projectId),
    );
  }

  Future<void> _openCreateSubtaskDialog(
    BuildContext context,
    WidgetRef ref,
    Task parent,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          CreateTaskDialog(projectId: projectId, previousTask: parent),
    );
  }

  Future<void> _openEditTaskDialog(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          EditTaskDialog(projectId: projectId, task: task),
    );
  }

  Future<void> _confirmDeleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    // Capture the messenger before any await so it stays valid regardless of
    // how the dialog / delete resolves.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result =
        await ref.read(tasksProvider(projectId).notifier).deleteTask(task.id);

    if (result.isSuccess) {
      SuccessSnackBar.show(messenger, message: 'Task "${task.name}" deleted.');
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to delete "${task.name}".',
      );
    }
  }

  Future<void> _duplicateTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final newId = await ref
        .read(tasksProvider(projectId).notifier)
        .duplicateTask(task);

    if (newId.isSuccess) {
      SuccessSnackBar.show(
        messenger,
        message: 'Duplicated "${task.name}" as "${task.name} copy".',
      );
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to duplicate "${task.name}".',
      );
    }
  }

  Future<void> _toggleComplete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? (task.completedAt ?? DateTime.now()) : null,
    );
    final result =
        await ref.read(tasksProvider(projectId).notifier).updateTask(updated);

    if (result.isFailure) {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to update "${task.name}".',
      );
    }
  }

  Future<void> _toggleFold(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = task.copyWith(isFolded: !task.isFolded);
    final result =
        await ref.read(tasksProvider(projectId).notifier).updateTask(updated);

    if (result.isFailure) {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to update "${task.name}".',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTasks = ref.watch(tasksProvider(projectId));
    final projectName =
        ref.watch(projectMetaProvider(projectId))?.name ?? 'Tasks';

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        // The page is reached via `go` (not `push`), so there is no
        // automatic back stack — provide an explicit return to the
        // project list.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to projects',
          onPressed: () => const ProjectsRoute().go(context),
        ),
        actions: [const PinWindowButton()],
      ),
      body: asyncTasks.when(
        data: (view) => _buildBody(context, ref, view),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateTaskDialog(context, ref),
        backgroundColor: Colors.teal[300],
        foregroundColor: Colors.white,
        tooltip: 'create new task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TasksView view) {
    if (view.trees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No tasks yet.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              'Tap + to create your first task.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider(projectId).notifier).reload(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: view.trees.length,
        itemBuilder: (context, index) {
          final tree = view.trees[index];
          return ChainTimeline(
            nodes: tree,
            formatDate: formatDate,
            stepCounts: view.stepCounts,
            onToggleComplete: (task) => _toggleComplete(context, ref, task),
            onEdit: (task) => _openEditTaskDialog(context, ref, task),
            onDelete: (task) => _confirmDeleteTask(context, ref, task),
            onAddSubtask: (task) => _openCreateSubtaskDialog(context, ref, task),
            onToggleFold: (task) => _toggleFold(context, ref, task),
            // Open a task by id → push its step page.
            onOpen: (task) =>
                StepsRoute(projectId, task.id).go(context),
            onDuplicate: (task) => _duplicateTask(context, ref, task),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 8),
          const Text('Failed to load tasks. Pull to retry.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(tasksProvider(projectId).notifier).reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
