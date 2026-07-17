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

/// One node in a flattened task tree, ready to render.
///
/// The tree is walked in pre-order; each entry remembers how deep it sits
/// and where it falls among its siblings so the gutter can draw indent
/// guides and elbow connectors (├── / └── / │) like a file-tree view.
class FlatTaskNode {
  const FlatTaskNode({
    required this.task,
    required this.depth,
    required this.isFirstChild,
    required this.isLastChild,
    required this.hasChildren,
    required this.ancestorIsLast,
  });

  final Task task;

  /// 0 for a root, +1 for each level of nesting.
  final int depth;

  /// Whether this is the first successor of its parent.
  final bool isFirstChild;

  /// Whether this is the last successor of its parent.
  final bool isLastChild;

  /// Whether this node has any successors itself.
  final bool hasChildren;

  /// For each ancestor level (0..depth-1), whether that ancestor was the
  /// last child of its own parent. Used to decide whether each ancestor's
  /// vertical spine should keep going past this row.
  final List<bool> ancestorIsLast;
}

/// Renders one task tree as an indented timeline. A predecessor can have
/// many successors, so branches are drawn with elbow connectors instead
/// of a single vertical line.
class ChainTimeline extends StatelessWidget {
  const ChainTimeline({
    super.key,
    required this.nodes,
    required this.formatDate,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final List<FlatTaskNode> nodes;
  final String Function(DateTime date) formatDate;
  final void Function(Task task) onToggleComplete;
  final void Function(Task task) onEdit;
  final void Function(Task task) onDelete;

  @override
  Widget build(BuildContext context) {
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
              for (final node in nodes)
                TreeRow(
                  node: node,
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

/// Renders one task inside the tree, with an indent gutter that draws the
/// connector lines linking it to its parent and siblings.
class TreeRow extends StatelessWidget {
  const TreeRow({
    super.key,
    required this.node,
    required this.formatDate,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final FlatTaskNode node;
  final String Function(DateTime date) formatDate;
  final void Function(Task task) onToggleComplete;
  final void Function(Task task) onEdit;
  final void Function(Task task) onDelete;

  static const double cellWidth = 30;
  static const double badgeSize = 26;
  static const double badgeRadius = badgeSize / 2;

  @override
  Widget build(BuildContext context) {
    final task = node.task;
    final gutterWidth = (node.depth + 1) * cellWidth;
    final badgeCenterX = (node.depth + 0.5) * cellWidth;

    final subtitle = task.dueDate != null
        ? 'Due ${formatDate(task.dueDate!)}'
        : 'Created ${formatDate(task.createdAt)}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gutter: connector lines + the toggle badge.
          SizedBox(
            width: gutterWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TreeGutterPainter(
                      depth: node.depth,
                      isFirstChild: node.isFirstChild,
                      isLastChild: node.isLastChild,
                      hasChildren: node.hasChildren,
                      ancestorIsLast: node.ancestorIsLast,
                      cellWidth: cellWidth,
                      badgeRadius: badgeRadius,
                      color: Colors.blue[300]!,
                    ),
                  ),
                ),
                Positioned(
                  left: badgeCenterX - badgeRadius,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => onToggleComplete(task),
                      child: Tooltip(
                        message: task.isCompleted
                            ? 'Mark as not done'
                            : 'Mark as done',
                        child: _NodeBadge(isCompleted: task.isCompleted),
                      ),
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

/// The circular node marker. A solid dot for pending tasks, a green check
/// for completed ones. Tap toggles completion (handled by the parent).
class _NodeBadge extends StatelessWidget {
  const _NodeBadge({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: TreeRow.badgeSize,
      height: TreeRow.badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : Colors.blue[600],
        shape: BoxShape.circle,
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}

/// Draws the indent guides and elbow connectors for one row.
///
/// Layout (per ancestor level = one cell of [cellWidth]):
/// - Ancestors above the direct parent: a full vertical spine while their
///   subtree is still open below this row; nothing once it has closed.
/// - The direct parent's cell: the elbow — a vertical half-line coming down
///   from the parent (plus another going down to a younger sibling if any)
///   and a horizontal arm reaching the badge.
/// - The badge cell: short verticals linking to older / younger siblings or
///   to this node's own first child.
class _TreeGutterPainter extends CustomPainter {
  _TreeGutterPainter({
    required this.depth,
    required this.isFirstChild,
    required this.isLastChild,
    required this.hasChildren,
    required this.ancestorIsLast,
    required this.cellWidth,
    required this.badgeRadius,
    required this.color,
  });

  final int depth;
  final bool isFirstChild;
  final bool isLastChild;
  final bool hasChildren;
  final List<bool> ancestorIsLast;
  final double cellWidth;
  final double badgeRadius;
  final Color color;

  /// Whether the ancestor at level [i] still has descendants below this
  /// row, i.e. its vertical spine should keep going through this row.
  /// True unless this node is that ancestor's last descendant.
  bool _ancestorOpen(int i) {
    // This node is the ancestor's last descendant when every step from the
    // ancestor's child down to this node is a "last child".
    for (int k = i + 1; k <= depth - 1; k++) {
      if (!ancestorIsLast[k]) return true;
    }
    return !isLastChild;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Pass-through spines for ancestors above the direct parent.
    for (int i = 0; i < depth - 1; i++) {
      if (!_ancestorOpen(i)) continue;
      final cx = (i + 0.5) * cellWidth;
      canvas.drawLine(Offset(cx, 0), Offset(cx, h), paint);
    }

    final badgeCx = (depth + 0.5) * cellWidth;

    // Elbow in the direct parent's cell.
    if (depth > 0) {
      final cx = (depth - 0.5) * cellWidth;
      // Come down from the parent.
      canvas.drawLine(Offset(cx, 0), Offset(cx, h / 2), paint);
      // Continue down to a younger sibling, if any.
      if (!isLastChild) {
        canvas.drawLine(Offset(cx, h / 2), Offset(cx, h), paint);
      }
      // Horizontal arm reaching the badge.
      canvas.drawLine(
        Offset(cx, h / 2),
        Offset(badgeCx - badgeRadius, h / 2),
        paint,
      );
    }

    // Badge cell: link up to an older sibling, down to a younger sibling
    // or to this node's own first child.
    if (!isFirstChild) {
      canvas.drawLine(
        Offset(badgeCx, 0),
        Offset(badgeCx, h / 2 - badgeRadius),
        paint,
      );
    }
    if (hasChildren || !isLastChild) {
      canvas.drawLine(
        Offset(badgeCx, h / 2 + badgeRadius),
        Offset(badgeCx, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreeGutterPainter old) {
    if (depth != old.depth ||
        isFirstChild != old.isFirstChild ||
        isLastChild != old.isLastChild ||
        hasChildren != old.hasChildren ||
        color != old.color ||
        cellWidth != old.cellWidth ||
        badgeRadius != old.badgeRadius) {
      return true;
    }
    if (ancestorIsLast.length != old.ancestorIsLast.length) return true;
    for (int i = 0; i < ancestorIsLast.length; i++) {
      if (ancestorIsLast[i] != old.ancestorIsLast[i]) return true;
    }
    return false;
  }
}
