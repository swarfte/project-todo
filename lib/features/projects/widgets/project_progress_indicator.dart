import 'package:flutter/material.dart';

/// A circular progress ring that doubles as a project row's leading icon.
///
/// - Fully completed project (all tasks done): a green check.
/// - Project with tasks: a ring filled to `completed / total`, with the
///   remaining count drawn in the centre.
/// - Project with no tasks yet: an empty folder outline.
class ProjectProgressIndicator extends StatelessWidget {
  const ProjectProgressIndicator({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  static const double _size = 40;
  static const double _stroke = 4;

  @override
  Widget build(BuildContext context) {
    // Fully done: show a check, no ring math needed.
    if (total > 0 && completed == total) {
      return Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 22, color: Colors.white),
      );
    }

    // No tasks yet: an empty folder outline as before.
    if (total == 0) {
      return Icon(Icons.folder_outlined, size: 30, color: Colors.blue[600]);
    }

    final progress = completed / total;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track ring.
          SizedBox(
            width: _size,
            height: _size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: _stroke,
              color: Colors.grey[300],
            ),
          ),
          // Progress ring.
          SizedBox(
            width: _size,
            height: _size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: _stroke,
              color: Colors.blue[600],
              backgroundColor: Colors.transparent,
            ),
          ),
          // Remaining count in the centre.
          Text(
            '${total - completed}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
}
