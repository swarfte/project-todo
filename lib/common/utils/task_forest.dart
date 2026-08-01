import 'package:project_todo/core/models/task.dart';

/// One node in a flattened task tree, ready to render.
///
/// The tree is walked in pre-order; each entry remembers how deep it sits and
/// where it falls among its siblings so the gutter can draw indent guides and
/// elbow connectors (├── / └── / │) like a file-tree view.
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

  /// Whether this is the last successor of its parent. Determines whether the
  /// parent elbow continues down to a younger sibling.
  final bool isLastChild;

  /// Whether this node has any successors itself. Drives the drop line below
  /// the badge that connects to its first child.
  final bool hasChildren;

  /// For each ancestor level (0..depth-1), whether that ancestor was the last
  /// child of its own parent. Used to decide whether each ancestor's vertical
  /// spine should keep going past this row.
  final List<bool> ancestorIsLast;

  /// Whether this node's children are currently hidden. When true the drop-line
  /// below the badge is not drawn (children aren't rendered) and the chevron
  /// points right instead of down.
  final bool isFolded;
}

/// Builds the task forest from `previousTaskId` links and returns it already
/// split into per-tree groups and sorted by urgency — exactly what the task
/// page renders.
///
/// [stepCounts] is only used to keep the signature flexible for future
/// progress-driven ordering; the current ordering keys off task fields only.
///
/// A predecessor can have any number of successors, so the data is a forest
/// (each node has at most one parent). Tasks whose predecessor is missing,
/// external to this project, or part of a cycle become their own roots so the
/// UI never breaks. Folded ancestors hide their descendants from rendering.
List<List<FlatTaskNode>> buildTaskForest(
  List<Task> tasks,
  Map<String, ({int total, int completed})> stepCounts,
) =>
    _sortTrees(_groupIntoTrees(_buildForest(tasks)));

/// Builds a pre-order flattened forest (one flat list, depth-0 nodes mark tree
/// boundaries). Mirrors the old `_buildTaskForest` in the task page, including
/// the folded-descendant suppression and cycle/degenerate-data safety nets.
List<FlatTaskNode> _buildForest(List<Task> tasks) {
  final byId = {for (final t in tasks) t.id: t};

  // Map each parent id -> its direct successors.
  final children = <String, List<Task>>{};
  final roots = <Task>[];

  for (final t in tasks) {
    final prev = t.previousTaskId;
    final hasValidPrev = prev != null && byId.containsKey(prev);
    if (!hasValidPrev) {
      roots.add(t);
      continue;
    }
    // Guard against self-loops: a task pointing at itself would never be
    // reached as a child of anything else, so treat it as a root.
    if (prev == t.id) {
      roots.add(t);
      continue;
    }
    children.putIfAbsent(prev, () => []).add(t);
  }

  // Deterministic, urgency-aware ordering for siblings.
  for (final list in children.values) {
    list.sort(_compareSiblings);
  }
  roots.sort(_compareSiblings);

  // Compute the set of task ids hidden because some ancestor is folded. The
  // folded ancestors themselves are still shown; only their descendants are
  // suppressed. This set is also used by the safety net below so those
  // descendants aren't promoted to independent roots.
  final hidden = <String>{};
  void markDescendants(String parentId) {
    for (final child in children[parentId] ?? const <Task>[]) {
      // Guard against cycles: stop if we've already queued this id.
      if (!hidden.add(child.id)) continue;
      markDescendants(child.id);
    }
  }

  for (final t in tasks) {
    if (t.isFolded) {
      markDescendants(t.id);
    }
  }

  final nodes = <FlatTaskNode>[];
  final visited = <String>{};

  // depth 0 (root) has no parent; treated as a last child so no parent elbow is
  // drawn for it.
  void walk(
    Task task,
    int depth,
    bool isLastChild,
    List<bool> ancestorIsLast,
  ) {
    if (visited.contains(task.id)) return; // cycle guard
    visited.add(task.id);

    final localChildren = children[task.id] ?? const [];

    nodes.add(
      FlatTaskNode(
        task: task,
        depth: depth,
        isLastChild: isLastChild,
        hasChildren: localChildren.isNotEmpty,
        ancestorIsLast: List<bool>.unmodifiable(ancestorIsLast),
        isFolded: task.isFolded,
      ),
    );

    // A folded task hides its descendants. The descendants are also in
    // `hidden`, so the safety net below won't surface them either. They stay
    // in `tasks` and reappear as soon as the task is unfolded.
    if (task.isFolded) return;

    // Each descendant inherits this node's "last child" flag as the next level
    // down in its ancestor stack, which the gutter uses to decide whether this
    // node's spine keeps going past those rows.
    final childAncestorIsLast = [...ancestorIsLast, isLastChild];
    for (var i = 0; i < localChildren.length; i++) {
      final child = localChildren[i];
      walk(
        child,
        depth + 1,
        i == localChildren.length - 1,
        childAncestorIsLast,
      );
    }
  }

  // Each root is rendered in its own card, so within a card there is only one
  // root; it carries no parent connector. Root ordering only affects which card
  // sorts first, not the connectors drawn inside it.
  for (final root in roots) {
    walk(root, 0, true, const []);
  }

  // Safety net: any task not reached (shouldn't normally happen unless the
  // graph is degenerate) becomes its own root. Tasks hidden under a folded
  // ancestor are skipped — they were intentionally hidden by the user and must
  // not be promoted to independent roots.
  for (final t in tasks) {
    if (visited.contains(t.id)) continue;
    if (hidden.contains(t.id)) continue;

    nodes.add(
      FlatTaskNode(
        task: t,
        depth: 0,
        isLastChild: true,
        hasChildren: false,
        ancestorIsLast: const [],
        isFolded: t.isFolded,
      ),
    );
  }

  return nodes;
}

int _compareSiblings(Task a, Task b) {
  // Incomplete tasks before completed ones.
  if (a.isCompleted != b.isCompleted) {
    return a.isCompleted ? 1 : -1;
  }

  // Earliest due date first (tasks with a due date beat those without).
  if (a.dueDate != null && b.dueDate != null) {
    return a.dueDate!.compareTo(b.dueDate!);
  }
  if (a.dueDate != null) return -1;
  if (b.dueDate != null) return 1;

  // Fall back to creation order.
  return a.createdAt.compareTo(b.createdAt);
}

/// Splits a flattened forest into per-tree groups so each root becomes its own
/// card on screen.
List<List<FlatTaskNode>> _groupIntoTrees(List<FlatTaskNode> forest) {
  final trees = <List<FlatTaskNode>>[];
  var current = <FlatTaskNode>[];
  for (final node in forest) {
    if (node.depth == 0) {
      if (current.isNotEmpty) trees.add(current);
      current = [node];
    } else {
      current.add(node);
    }
  }
  if (current.isNotEmpty) trees.add(current);
  return trees;
}

/// Categories (ascending: smaller = higher priority = shown first):
/// 0 = has an incomplete task with a due date.
/// 1 = incomplete but no due dates.
/// 2 = fully completed.
({int category, DateTime primary}) _treeSortKey(List<FlatTaskNode> tree) {
  final tasks = tree.map((n) => n.task).toList();
  final incomplete = tasks.where((t) => !t.isCompleted).toList();

  final dueDates = incomplete
      .where((t) => t.dueDate != null)
      .map((t) => t.dueDate!)
      .toList()
    ..sort();

  if (dueDates.isNotEmpty) {
    return (category: 0, primary: dueDates.first);
  }

  if (incomplete.isNotEmpty) {
    final oldest = tasks
        .map((t) => t.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return (category: 1, primary: oldest);
  }

  // Fully done: newest completion first.
  final completed = tasks
      .where((t) => t.completedAt != null)
      .map((t) => t.completedAt!)
      .toList()
    ..sort();
  final latest = completed.isNotEmpty
      ? completed.last
      : tasks.first.createdAt;
  return (category: 2, primary: latest);
}

int _compareTrees(List<FlatTaskNode> a, List<FlatTaskNode> b) {
  final ka = _treeSortKey(a);
  final kb = _treeSortKey(b);

  if (ka.category != kb.category) {
    return ka.category.compareTo(kb.category);
  }

  // Categories 0 and 1 sort ascending (earliest first); category 2 (completed)
  // sorts descending so the newest completion wins.
  if (ka.category == 2) {
    return kb.primary.compareTo(ka.primary);
  }
  return ka.primary.compareTo(kb.primary);
}

/// Sorts trees as single units. Each tree's priority is driven by its most
/// urgent incomplete task, so finishing that task naturally shifts the tree to
/// its next most urgent state.
List<List<FlatTaskNode>> _sortTrees(List<List<FlatTaskNode>> trees) {
  final sorted = [...trees];
  sorted.sort(_compareTrees);
  return sorted;
}
