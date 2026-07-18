import 'package:flutter/material.dart';
import 'package:project_todo/adaptor.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/createStepDialog.dart';
import 'package:project_todo/components/editStepDialog.dart';
import 'package:project_todo/components/successSnackBar.dart';
// `models.dart` declares a `Step` class that collides with Flutter's own
// `Step` (from the Stepper widget), so import it under a prefix.
import 'package:project_todo/models.dart' as models;

/// Shows the ordered list of steps that make up a single task.
///
/// Unlike the task page (a tree), steps form a linear chain: each step has
/// at most one predecessor and one successor. The chain is reconstructed
/// from `previousStepId` links and rendered top-to-bottom with a vertical
/// connector line so the order reads as "do this, then this, then this".
class StepPage extends StatefulWidget {
  const StepPage({super.key, required this.task});

  final models.Task task;

  @override
  State<StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<StepPage> {
  final APIService _apiService = APIService();

  List<models.Step> _steps = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final records = await _apiService.getStepListByTaskId(widget.task.id);
      final steps = records
          .map((r) => StepAdaptor.fromJson(r.toJson()))
          .toList();

      if (!mounted) return;

      setState(() {
        _steps = _orderSteps(steps);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Failed to load steps. Pull to retry.';
        _isLoading = false;
      });
    }
  }

  /// Reconstructs the linear chain from `previousStepId` links.
  ///
  /// A step is a chain head if its predecessor is null, points outside this
  /// task's step set, or is itself (self-loop guard). We then walk forward
  /// following the inverse predecessor map. Cycle guard + safety net ensure
  /// the UI never breaks on degenerate data — any unreached step is appended
  /// at the end so nothing is silently dropped.
  List<models.Step> _orderSteps(List<models.Step> steps) {
    if (steps.isEmpty) return steps;

    final byId = {for (final s in steps) s.id: s};

    // parent id -> the step that comes directly after it. A linear chain has
    // at most one successor per predecessor, but we collect defensively.
    final successorOf = <String, models.Step>{};
    final heads = <models.Step>[];

    for (final s in steps) {
      final prev = s.previousStepId;
      final hasValidPrev = prev != null && byId.containsKey(prev) && prev != s.id;
      if (!hasValidPrev) {
        heads.add(s);
      } else {
        // First writer wins; duplicates would indicate data corruption and
        // are handled by the safety net below.
        successorOf.putIfAbsent(prev, () => s);
      }
    }

    final ordered = <models.Step>[];
    final visited = <String>{};

    // Walk forward from each head until we hit a cycle or a dead end.
    void walk(models.Step current) {
      var node = current;
      while (true) {
        if (visited.contains(node.id)) return; // cycle guard
        visited.add(node.id);
        ordered.add(node);
        final next = successorOf[node.id];
        if (next == null) return;
        node = next;
      }
    }

    // Heads are walked in stable insertion order so the chain stays
    // deterministic when there are multiple roots.
    for (final head in heads) {
      walk(head);
    }

    // Safety net: any step not reached (shouldn't normally happen unless the
    // graph is degenerate) is appended so it still appears.
    for (final s in steps) {
      if (!visited.contains(s.id)) {
        ordered.add(s);
      }
    }

    return ordered;
  }

  Future<void> _openCreateStepDialog() async {
    // Append: the new step comes after the current last step (if any).
    final last = _steps.isNotEmpty ? _steps.last : null;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CreateStepDialog(
          taskId: widget.task.id,
          previousStepId: last?.id,
          previousStepName: last?.name,
        );
      },
    );

    // Refresh the list once the dialog is closed so newly created
    // steps show up immediately.
    if (mounted) {
      _loadSteps();
    }
  }

  Future<void> _openEditStepDialog(models.Step step) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return EditStepDialog(step: step);
      },
    );

    // Refresh the list once the dialog is closed so edited
    // steps show up immediately.
    if (mounted) {
      _loadSteps();
    }
  }

  Future<void> _confirmDeleteStep(models.Step step) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    final isSuccess = await _apiService.deleteStep(step.id);

    if (!mounted) return;

    if (isSuccess) {
      SuccessSnackBar.show(messenger, message: 'Step "${step.name}" deleted.');
      _loadSteps();
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to delete "${step.name}".',
      );
    }
  }

  /// Toggles a step's completion status. A quick way to tick a step off
  /// without opening the edit dialog.
  Future<void> _toggleComplete(models.Step step) async {
    final updated = models.Step(
      id: step.id,
      name: step.name,
      taskId: step.taskId,
      isCompleted: !step.isCompleted,
      createdAt: step.createdAt,
      updatedAt: step.updatedAt,
      previousStepId: step.previousStepId,
    );

    final isSuccess = await _apiService.updateStep(updated);

    if (!mounted) return;

    if (isSuccess) {
      _loadSteps();
    } else {
      SuccessSnackBar.show(
        ScaffoldMessenger.of(context),
        message: 'Failed to update "${step.name}".',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.name),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateStepDialog,
        backgroundColor: Colors.amber[400],
        foregroundColor: Colors.white,
        tooltip: 'create new step',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 8),
            Text(_loadError!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSteps,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_steps.isEmpty) {
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

    final total = _steps.length;
    final completed = _steps.where((s) => s.isCompleted).length;

    return RefreshIndicator(
      onRefresh: _loadSteps,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: _steps.length + 1, // +1 for the header summary.
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _StepHeader(completed: completed, total: total);
          }
          final step = _steps[index - 1];
          final isFirst = index - 1 == 0;
          final isLast = index - 1 == _steps.length - 1;
          return _StepRow(
            step: step,
            number: index,
            isFirst: isFirst,
            isLast: isLast,
            onToggleComplete: _toggleComplete,
            onEdit: _openEditStepDialog,
            onDelete: _confirmDeleteStep,
          );
        },
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

/// One row in the step chain. The left gutter draws a vertical connector
/// line linking each step to the next, with a numbered/tappable badge at
/// each joint so the linear order is obvious at a glance.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.number,
    required this.isFirst,
    required this.isLast,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final models.Step step;
  final int number;
  final bool isFirst;
  final bool isLast;
  final void Function(models.Step step) onToggleComplete;
  final void Function(models.Step step) onEdit;
  final void Function(models.Step step) onDelete;

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
                // Connector spine. A line runs down the badge column
                // joining this step to the next; the very last step has no
                // drop line below it.
                if (!isLast)
                  Positioned(
                    left: _gutterWidth / 2,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.amber[300],
                    ),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Step actions',
                    onSelected: (String value) {
                      switch (value) {
                        case 'edit':
                          onEdit(step);
                          break;
                        case 'delete':
                          onDelete(step);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
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
