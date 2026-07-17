import 'package:flutter/material.dart';
import 'package:project_todo/models.dart';

/// Returns the color for a task's due date based on its urgency:
/// - Red: overdue or due today.
/// - Orange: due within the next 72 hours.
/// - Green: due further out.
Color dueDateColor(DateTime dueDate) {
  final now = DateTime.now();
  final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);

  // Due today or in the past.
  if (dueDate.isBefore(startOfTomorrow)) {
    return Colors.red;
  }

  // Due within the next 72 hours.
  if (dueDate.difference(now) <= const Duration(hours: 72)) {
    return Colors.orange;
  }

  return Colors.green;
}

/// Renders one task chain as a vertical timeline.
class ChainTimeline extends StatelessWidget {
  const ChainTimeline({
    super.key,
    required this.chain,
    required this.formatDate,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Task> chain;
  final String Function(DateTime date) formatDate;
  final void Function(Task task) onToggleComplete;
  final void Function(Task task) onEdit;
  final void Function(Task task) onDelete;

  @override
  Widget build(BuildContext context) {
    final total = chain.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < total; i++)
                TimelineRow(
                  task: chain[i],
                  position: i + 1,
                  total: total,
                  isFirst: i == 0,
                  isLast: i == total - 1,
                  formatDate: formatDate,
                  onToggleComplete: onToggleComplete,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders one task inside a chain timeline.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.task,
    required this.position,
    required this.total,
    required this.isFirst,
    required this.isLast,
    required this.formatDate,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final int position;
  final int total;
  final bool isFirst;
  final bool isLast;
  final String Function(DateTime date) formatDate;
  final void Function(Task task) onToggleComplete;
  final void Function(Task task) onEdit;
  final void Function(Task task) onDelete;

  @override
  Widget build(BuildContext context) {
    final lineColor = Colors.blue[300]!;

    final subtitle = task.dueDate != null
        ? 'Due ${formatDate(task.dueDate!)}'
        : 'Created ${formatDate(task.createdAt)}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline gutter: connector line and position badge.
          SizedBox(
            width: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    // Top half of the timeline connector.
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirst ? Colors.transparent : lineColor,
                      ),
                    ),

                    // Bottom half of the timeline connector.
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : lineColor,
                      ),
                    ),
                  ],
                ),

                GestureDetector(
                  onTap: () => onToggleComplete(task),
                  child: Tooltip(
                    message: task.isCompleted
                        ? 'Mark as not done'
                        : 'Mark as done',
                    child: PositionBadege(
                      position: position,
                      total: total,
                      isCompleted: task.isCompleted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Task content.
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
                          task.name,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: task.dueDate != null && !task.isCompleted
                                ? dueDateColor(task.dueDate!)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (task.isCompleted)
                    Chip(
                      label: const Text('Done'),
                      backgroundColor: Colors.green[100],
                    ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Task actions',
                    onSelected: (String value) {
                      switch (value) {
                        case 'edit':
                          onEdit(task);
                          break;
                        case 'delete':
                          onDelete(task);
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

/// Displays the task's position within its chain.
class PositionBadege extends StatelessWidget {
  const PositionBadege({
    super.key,
    required this.position,
    required this.total,
    required this.isCompleted,
  });

  final int position;
  final int total;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? Colors.green : Colors.blue[600]!;

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        '$position/$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
