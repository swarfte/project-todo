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
    required this.isLastChild,
    required this.hasChildren,
    required this.ancestorIsLast,
    required this.isFolded,
  });

  final Task task;

  /// 0 for a root, +1 for each level of nesting.
  final int depth;

  /// Whether this is the last successor of its parent. Determines whether
  /// the parent elbow continues down to a younger sibling.
  final bool isLastChild;

  /// Whether this node has any successors itself. Drives the drop line
  /// below the badge that connects to its first child.
  final bool hasChildren;

  /// For each ancestor level (0..depth-1), whether that ancestor was the
  /// last child of its own parent. Used to decide whether each ancestor's
  /// vertical spine should keep going past this row.
  final List<bool> ancestorIsLast;

  /// Whether this node's children are currently hidden. When true the
  /// drop-line below the badge is not drawn (children aren't rendered) and
  /// the chevron points right instead of down.
  final bool isFolded;
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
    required this.onAddSubtask,
    required this.onToggleFold,
  });

  final List<FlatTaskNode> nodes;
  final String Function(DateTime date) formatDate;
  final void Function(Task task) onToggleComplete;
  final void Function(Task task) onEdit;
  final void Function(Task task) onDelete;
  final void Function(Task task) onAddSubtask;
  final void Function(Task task) onToggleFold;

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
                  onAddSubtask: onAddSubtask,
                  onToggleFold: onToggleFold,
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
    required this.onAddSubtask,
    required this.onToggleFold,
  });

  final FlatTaskNode node;
  final String Function(DateTime date) formatDate;
  final void Function(Task task) onToggleComplete;
  final void Function(Task task) onEdit;
  final void Function(Task task) onDelete;
  final void Function(Task task) onAddSubtask;
  final void Function(Task task) onToggleFold;

  static const double cellWidth = 30;
  static const double badgeSize = 26;
  static const double badgeRadius = badgeSize / 2;

  @override
  Widget build(BuildContext context) {
    final task = node.task;
    final gutterWidth = (node.depth + 1) * cellWidth;
    final badgeCenterX = (node.depth + 0.5) * cellWidth;

    // Decide what date to show under the task title, in priority order:
    // completed tasks show their completion date, otherwise a pending task
    // shows its due date if set, falling back to the creation date.
    final String subtitle;
    final Color subtitleColor;
    if (task.isCompleted && task.completedAt != null) {
      subtitle = 'Completed ${formatDate(task.completedAt!)}';
      subtitleColor = Colors.green[700]!;
    } else if (task.dueDate != null) {
      subtitle = 'Due ${formatDate(task.dueDate!)}';
      subtitleColor = dueDateColor(task.dueDate!);
    } else {
      subtitle = 'Created ${formatDate(task.createdAt)}';
      subtitleColor = Colors.grey[600]!;
    }

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
                      isLastChild: node.isLastChild,
                      hasChildren: node.hasChildren,
                      isFolded: node.isFolded,
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
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fold/unfold shortcut. Only tasks that have children are
                  // foldable; a leaf has nothing to hide, so it shows no
                  // chevron to avoid a dead control.
                  if (node.hasChildren)
                    IconButton(
                      tooltip: node.isFolded ? 'Unfold' : 'Fold',
                      icon: Icon(
                        node.isFolded
                            ? Icons.chevron_right
                            : Icons.expand_more,
                      ),
                      iconSize: 22,
                      color: Colors.blue[600],
                      onPressed: () => onToggleFold(task),
                    ),

                  // Quick shortcut to add a subtask that comes after this
                  // task, without having to pick the predecessor manually.
                  IconButton(
                    tooltip: 'Add subtask',
                    icon: const Icon(Icons.add_task),
                    iconSize: 22,
                    color: Colors.teal[600],
                    onPressed: () => onAddSubtask(task),
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

/// Draws the indent guides and elbow connectors for one row, exactly like
/// the `tree` command's `├──` / `└──` / `│` glyphs.
///
/// The gutter is a row of equal-width cells, one per depth level. The badge
/// sits in the last cell (column [depth]); columns 0..depth-1 carry the
/// connectors. For column [i]:
///
/// - If [i] < [depth] - 1 (an ancestor above the direct parent): draw a
///   full vertical spine only while that ancestor's subtree is still open
///   below this row; otherwise leave it blank. (This is the `│` glyph.)
/// - If [i] == [depth] - 1 (the direct parent's cell): draw the elbow — a
///   half-line dropping from the parent, a horizontal arm to the badge, and
///   a continuation down to a younger sibling when one exists. (This is the
///   `├──` / `└──` glyph.)
///
/// The badge's own column is special: nothing ever sits above the badge
/// (it ties into its parent through the elbow's horizontal arm, not from
/// above), and a line drops below it only when this node has a first child
/// to connect to. Siblings never run through the badge column — they run
/// through the parent's spine — so [isLastChild] does not affect it.
class _TreeGutterPainter extends CustomPainter {
  _TreeGutterPainter({
    required this.depth,
    required this.isLastChild,
    required this.hasChildren,
    required this.isFolded,
    required this.ancestorIsLast,
    required this.cellWidth,
    required this.badgeRadius,
    required this.color,
  });

  final int depth;
  final bool isLastChild;
  final bool hasChildren;
  final bool isFolded;
  final List<bool> ancestorIsLast;
  final double cellWidth;
  final double badgeRadius;
  final Color color;

  /// Whether the ancestor at level [i] still has rows below this one inside
  /// its subtree, meaning its vertical spine must pass through this row.
  ///
  /// The current node is that ancestor's *last* descendant iff every node
  /// on the path from level `i + 1` down to this node is a last child. If
  /// any of them has a younger sibling, that sibling's subtree renders
  /// below and the spine stays open.
  bool _ancestorOpen(int i) {
    for (int k = i + 1; k <= depth - 1; k++) {
      if (!ancestorIsLast[k]) return true;
    }
    return !isLastChild;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final midY = h / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final badgeCx = (depth + 0.5) * cellWidth;

    // One pass over every connector column 0..depth-1.
    for (int i = 0; i < depth; i++) {
      final cx = (i + 0.5) * cellWidth;

      if (i == depth - 1) {
        // Direct parent's cell — the elbow.
        canvas.drawLine(Offset(cx, 0), Offset(cx, midY), paint);
        if (!isLastChild) {
          canvas.drawLine(Offset(cx, midY), Offset(cx, h), paint);
        }
        canvas.drawLine(
          Offset(cx, midY),
          Offset(badgeCx - badgeRadius, midY),
          paint,
        );
      } else {
        // Pass-through ancestor cell — full spine only while open.
        if (_ancestorOpen(i)) {
          canvas.drawLine(Offset(cx, 0), Offset(cx, h), paint);
        }
      }
    }

    // Badge cell: a single drop to this node's first child, if any.
    // Never draw above the badge; siblings use the parent's spine above.
    // When folded, the children aren't rendered, so the drop line would
    // dangle into nothing — suppress it.
    if (hasChildren && !isFolded) {
      canvas.drawLine(
        Offset(badgeCx, midY + badgeRadius),
        Offset(badgeCx, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TreeGutterPainter old) {
    if (depth != old.depth ||
        isLastChild != old.isLastChild ||
        hasChildren != old.hasChildren ||
        isFolded != old.isFolded ||
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
