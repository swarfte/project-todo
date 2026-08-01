import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/common/widgets/pin_window_button.dart';
import 'package:project_todo/common/widgets/success_snackbar.dart';
import 'package:project_todo/core/models/task_step.dart';
import 'package:project_todo/features/steps/steps_vm.dart';
import 'package:project_todo/features/steps/widgets/create_step_dialog.dart';
import 'package:project_todo/features/steps/widgets/edit_step_dialog.dart';

/// Shows the ordered list of steps that make up a single task.
///
/// Subscribes to [stepsProvider] (parameterised by `taskId`) and renders the
/// reconstructed linear chain. The AppBar title comes from [taskMetaProvider]
/// since the router only carries the id. All mutations go through the VM.
///
/// Unlike the task page (a tree), steps form a linear chain: each step has at
/// most one predecessor and one successor. The chain is reconstructed from
/// `previousStepId` links (inside the VM via `orderSteps`) and rendered
/// top-to-bottom with a vertical connector line so the order reads as "do
/// this, then this, then this".
class StepsPage extends ConsumerWidget {
  const StepsPage({super.key, required this.projectId, required this.taskId});

  final String projectId;
  final String taskId;

  Future<void> _openCreateStepDialog(BuildContext context, WidgetRef ref) async {
    // Append: the new step comes after the current last step (if any).
    final steps = ref.read(stepsProvider(taskId)).value;
    final last = steps != null && steps.steps.isNotEmpty
        ? steps.steps.last
        : null;

    await showDialog<void>(
      context: context,
      builder: (context) => CreateStepDialog(
        taskId: taskId,
        previousStepId: last?.id,
        previousStepName: last?.name,
      ),
    );
  }

  /// Opens the create dialog in insert mode, splicing a new step directly
  /// after [afterStep] instead of appending at the tail.
  Future<void> _openInsertStepDialog(
    BuildContext context,
    WidgetRef ref,
    TaskStep afterStep,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => CreateStepDialog(
        taskId: taskId,
        previousStepId: afterStep.id,
        previousStepName: afterStep.name,
        onSubmit: (name) async {
          final result = await ref
              .read(stepsProvider(taskId).notifier)
              .insertStep(name, afterStep);
          if (result.isFailure) {
            // Best-effort: the create may have partially succeeded, so surface
            // the failure but let the reload reconcile the view.
            SuccessSnackBar.show(
              messenger,
              message:
                  'Step created, but the chain could not be fully '
                  're-linked. Please review.',
            );
          }
          return result.isSuccess;
        },
      ),
    );
  }

  Future<void> _openEditStepDialog(
    BuildContext context,
    WidgetRef ref,
    TaskStep step,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditStepDialog(taskId: taskId, step: step),
    );
  }

  Future<void> _confirmDeleteStep(
    BuildContext context,
    WidgetRef ref,
    TaskStep step,
  ) async {
    // Capture the messenger before any await so it stays valid regardless of
    // how the dialog / delete resolves.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Step'),
        content: Text(
          'Are you sure you want to delete "${step.name}"? '
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
        await ref.read(stepsProvider(taskId).notifier).deleteStep(step.id);

    if (result.isSuccess) {
      SuccessSnackBar.show(messenger, message: 'Step "${step.name}" deleted.');
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to delete "${step.name}".',
      );
    }
  }

  Future<void> _toggleComplete(
    BuildContext context,
    WidgetRef ref,
    TaskStep step,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = step.copyWith(isCompleted: !step.isCompleted);
    final result =
        await ref.read(stepsProvider(taskId).notifier).updateStep(updated);

    if (result.isFailure) {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to update "${step.name}".',
      );
    }
  }

  /// Marks every completed step in this task as pending again. Confirms first
  /// since it reverses all progress on the chain.
  Future<void> _unfinishAllSteps(BuildContext context, WidgetRef ref) async {
    final steps = ref.read(stepsProvider(taskId)).value;
    final completedCount =
        steps?.steps.where((s) => s.isCompleted).length ?? 0;
    if (completedCount == 0) return;

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all steps'),
        content: Text(
          'Mark all $completedCount completed step'
          '${completedCount == 1 ? '' : 's'} as not done?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(stepsProvider(taskId).notifier).unfinishAll();
    final resetCount = result.dataOrNull ?? 0;

    SuccessSnackBar.show(
      messenger,
      message: resetCount > 0
          ? '$resetCount step${resetCount == 1 ? '' : 's'} reset to not done.'
          : 'No steps were reset.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSteps = ref.watch(stepsProvider(taskId));
    final taskName = ref.watch(taskMetaProvider(taskId))?.name ?? 'Steps';

    return Scaffold(
      appBar: AppBar(
        title: Text(taskName),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset all steps',
            // Only meaningful when at least one step is done; disabled
            // otherwise so the icon reads as inert, not broken.
            onPressed: (asyncSteps.value?.steps.any((s) => s.isCompleted) ??
                    false)
                ? () => _unfinishAllSteps(context, ref)
                : null,
          ),
          const PinWindowButton(),
        ],
      ),
      body: asyncSteps.when(
        data: (view) => _buildBody(context, ref, view.steps),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateStepDialog(context, ref),
        backgroundColor: Colors.amber[400],
        foregroundColor: Colors.white,
        tooltip: 'create new step',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<TaskStep> steps) {
    if (steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No steps yet.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              'Tap + to add the first step.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    final total = steps.length;
    final completed = steps.where((s) => s.isCompleted).length;

    return RefreshIndicator(
      onRefresh: () => ref.read(stepsProvider(taskId).notifier).reload(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: steps.length + 1, // +1 for the header summary.
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StepHeader(completed: completed, total: total);
          }
          final step = steps[index - 1];
          final isFirst = index - 1 == 0;
          final isLast = index - 1 == steps.length - 1;
          return _StepRow(
            step: step,
            number: index,
            isFirst: isFirst,
            isLast: isLast,
            onToggleComplete: (step) => _toggleComplete(context, ref, step),
            onEdit: (step) => _openEditStepDialog(context, ref, step),
            onDelete: (step) => _confirmDeleteStep(context, ref, step),
            onInsert: (step) => _openInsertStepDialog(context, ref, step),
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
          const Text('Failed to load steps. Pull to retry.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(stepsProvider(taskId).notifier).reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Compact progress summary shown at the top of the step list.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      child: Row(
        children: [
          Icon(Icons.checklist_rtl, size: 18, color: Colors.amber[800]),
          const SizedBox(width: 8),
          Text(
            '$completed / $total steps done',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: completed == total && total > 0
                  ? Colors.green[700]
                  : Colors.amber[900],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the step chain. The left gutter draws a vertical connector line
/// linking each step to the next, with a numbered/tappable badge at each joint
/// so the linear order is obvious at a glance.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.number,
    required this.isFirst,
    required this.isLast,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    required this.onInsert,
  });

  final TaskStep step;
  final int number;
  final bool isFirst;
  final bool isLast;
  final void Function(TaskStep step) onToggleComplete;
  final void Function(TaskStep step) onEdit;
  final void Function(TaskStep step) onDelete;
  final void Function(TaskStep step) onInsert;

  static const double _gutterWidth = 36;
  static const double _badgeSize = 28;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gutter: the connector line + the numbered badge.
          SizedBox(
            width: _gutterWidth,
            child: Stack(
              children: [
                // Connector spine. A line runs down the badge column joining
                // this step to the next; the very last step has no drop line
                // below it.
                if (!isLast)
                  Positioned(
                    left: _gutterWidth / 2,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.amber[300]),
                  ),
                // A half-line from the top of the row into the badge,
                // connecting from the previous step (skipped for the first).
                if (!isFirst)
                  Positioned(
                    left: _gutterWidth / 2,
                    top: 0,
                    height: 24,
                    child: Container(width: 2, color: Colors.amber[300]),
                  ),
                // Numbered/tappable badge, centered in the gutter.
                Positioned(
                  left: (_gutterWidth - _badgeSize) / 2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => onToggleComplete(step),
                      child: Tooltip(
                        message: step.isCompleted
                            ? 'Mark as not done'
                            : 'Mark as done',
                        child: _StepBadge(
                          number: number,
                          isCompleted: step.isCompleted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Step content + actions.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.name,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: step.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: step.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Step $number',
                          style: TextStyle(
                            fontSize: 13,
                            color: step.isCompleted
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dedicated insert shortcut: splices a new step directly
                  // after this one, shifting everything below down.
                  IconButton(
                    tooltip: 'Insert step after',
                    icon: const Icon(Icons.post_add),
                    iconSize: 22,
                    color: Colors.amber[800],
                    onPressed: () => onInsert(step),
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Step actions',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit(step);
                          break;
                        case 'delete':
                          onDelete(step);
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red[400]),
                            ),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The numbered circle marker for a step. Pending steps show their position
/// number on an amber background; completed steps show a green check.
/// Tap toggles completion (handled by the parent).
class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.isCompleted});

  final int number;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : Colors.amber[700],
        shape: BoxShape.circle,
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text(
              '$number',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
