import 'package:project_todo/core/models/task_step.dart';

/// Reconstructs the linear step chain from `previousStepId` links.
///
/// Heads (no valid predecessor) are walked forward in stable insertion order,
/// with a cycle guard and a safety net that appends any unreached step so
/// nothing is silently dropped. Shared by the network layer (which uses it when
/// duplicating a task's step chain) and the step page (which uses it to order
/// the fetched list for display).
List<TaskStep> orderSteps(List<TaskStep> steps) {
  if (steps.isEmpty) return steps;

  final byId = {for (final s in steps) s.id: s};

  // parent id -> the step that comes directly after it. A linear chain has at
  // most one successor per predecessor, but we collect defensively.
  final successorOf = <String, TaskStep>{};
  final heads = <TaskStep>[];

  for (final s in steps) {
    final prev = s.previousStepId;
    final hasValidPrev =
        prev != null && byId.containsKey(prev) && prev != s.id;
    if (!hasValidPrev) {
      heads.add(s);
    } else {
      // First writer wins; duplicates would indicate data corruption and are
      // handled by the safety net below.
      successorOf.putIfAbsent(prev, () => s);
    }
  }

  final ordered = <TaskStep>[];
  final visited = <String>{};

  // Walk forward from each head until we hit a cycle or a dead end.
  void walk(TaskStep current) {
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

  // Heads are walked in stable insertion order so the chain stays deterministic
  // when there are multiple roots.
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
