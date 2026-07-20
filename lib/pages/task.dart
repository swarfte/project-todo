import 'package:flutter/material.dart';
import 'package:project_todo/adaptor.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/createTaskDialog.dart';
import 'package:project_todo/components/editTaskDialog.dart';
import 'package:project_todo/components/successSnackBar.dart';
import 'package:project_todo/models.dart';
import 'package:project_todo/components/chainTimeline.dart';
import 'package:project_todo/pages/step.dart';

/// Returns the color for a task's due date based on its urgency:
/// - Red: overdue or due today.
/// - Orange: due within the next 72 hours (3 days).
/// - Green: due further out.

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.project});

  final Project project;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final APIService _apiService = APIService();

  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final records = await _apiService.getTaskListByProjectId(
        widget.project.id,
      );
      final tasks = records
          .map((r) => TaskAdaptor.fromJson(r.toJson()))
          .toList();

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Failed to load tasks. Pull to retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateTaskDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CreateTaskDialog(
          projectId: widget.project.id,
          existingTasks: _tasks,
        );
      },
    );

    // Refresh the list once the dialog is closed so newly created
    // tasks show up immediately.
    if (mounted) {
      _loadTasks();
    }
  }

  /// Opens the create dialog with the predecessor fixed to [parent], so the
  /// user can add a subtask directly from a task row without picking the
  /// previous task manually.
  Future<void> _openCreateSubtaskDialog(Task parent) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CreateTaskDialog(
          projectId: widget.project.id,
          previousTask: parent,
        );
      },
    );

    if (mounted) {
      _loadTasks();
    }
  }

  /// Opens the task's step page, where the user can manage the ordered
  /// list of steps that make up this task. Refreshes the task list on
  /// return, since step changes can affect the task's apparent state.
  Future<void> _openStepPage(Task task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => StepPage(task: task),
      ),
    );

    if (mounted) {
      _loadTasks();
    }
  }

  Future<void> _openEditTaskDialog(Task task) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return EditTaskDialog(task: task, existingTasks: _tasks);
      },
    );

    // Refresh the list once the dialog is closed so edited
    // tasks show up immediately.
    if (mounted) {
      _loadTasks();
    }
  }

  Future<void> _confirmDeleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    final isSuccess = await _apiService.deleteTask(task.id);

    if (!mounted) return;

    if (isSuccess) {
      SuccessSnackBar.show(messenger, message: 'Task "${task.name}" deleted.');
      _loadTasks();
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to delete "${task.name}".',
      );
    }
  }

  /// Deep-duplicates a task along with its subtasks and steps. The new root
  /// task is named "`{task.name} copy`" and becomes a sibling of the original;
  /// completion status, due date, fold state, step chains, and step statuses
  /// are all carried over so the copy mirrors the original.
  ///
  /// Shows a snackbar on success or failure and refreshes the list.
  Future<void> _duplicateTask(Task task) async {
    final messenger = ScaffoldMessenger.of(context);

    final newId = await _apiService.duplicateTask(task);

    if (!mounted) return;

    if (newId != null) {
      SuccessSnackBar.show(
        messenger,
        message: 'Duplicated "${task.name}" as "${task.name} copy".',
      );
      _loadTasks();
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to duplicate "${task.name}".',
      );
    }
  }

  /// Toggles a task's completion status. A quick way to tick a task off
  /// without opening the edit dialog.
  Future<void> _toggleComplete(Task task) async {
    final newCompleted = !task.isCompleted;
    final updated = Task(
      id: task.id,
      name: task.name,
      projectId: task.projectId,
      isCompleted: newCompleted,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      dueDate: task.dueDate,
      previousTaskId: task.previousTaskId,
      isFolded: task.isFolded,
      completedAt: newCompleted ? (task.completedAt ?? DateTime.now()) : null,
    );

    final isSuccess = await _apiService.updateTask(updated);

    if (!mounted) return;

    if (isSuccess) {
      _loadTasks();
    } else {
      SuccessSnackBar.show(
        ScaffoldMessenger.of(context),
        message: 'Failed to update "${task.name}".',
      );
    }
  }

  /// Toggles a task's folded state and persists it. Folding hides the
  /// task's descendants from view; unfolding shows them again. The
  /// preference is saved per-task so it survives reloads.
  Future<void> _toggleFold(Task task) async {
    final updated = Task(
      id: task.id,
      name: task.name,
      projectId: task.projectId,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      dueDate: task.dueDate,
      previousTaskId: task.previousTaskId,
      completedAt: task.completedAt,
      isFolded: !task.isFolded,
    );

    final isSuccess = await _apiService.updateTask(updated);

    if (!mounted) return;

    if (isSuccess) {
      _loadTasks();
    } else {
      SuccessSnackBar.show(
        ScaffoldMessenger.of(context),
        message: 'Failed to update "${task.name}".',
      );
    }
  }

  /// Builds a task forest from `previousTaskId` links and flattens it
  /// in pre-order, recording each node's depth and sibling position so
  /// the timeline can draw indent guides and elbow connectors.
  ///
  /// A predecessor can have any number of successors, so the data is a
  /// forest (each node has at most one parent). Tasks whose predecessor
  /// is missing, external to this project, or part of a cycle become
  /// their own roots so the UI never breaks.
  List<FlatTaskNode> _buildTaskForest(List<Task> tasks) {
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
      // Guard against self-loops: a task pointing at itself would never
      // be reached as a child of anything else, so treat it as a root.
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

    // Compute the set of task ids that are hidden because some ancestor is
    // folded. The folded ancestors themselves are still shown; only their
    // descendants are suppressed. This set is also used by the safety net
    // below so those descendants aren't promoted to independent roots.
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

    // depth 0 (root) has no parent; treated as a last child so no parent
    // elbow is drawn for it.
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
      // `hidden`, so the safety net below won't surface them either. They
      // stay in `tasks` and reappear as soon as the task is unfolded.
      if (task.isFolded) return;

      // Each descendant inherits this node's "last child" flag as the next
      // level down in its ancestor stack, which the gutter uses to decide
      // whether this node's spine keeps going past those rows.
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

    // Each root is rendered in its own card, so within a card there is
    // only one root; it carries no parent connector. Root ordering only
    // affects which card sorts first, not the connectors drawn inside it.
    for (final root in roots) {
      walk(root, 0, true, const []);
    }

    // Safety net: any task not reached (shouldn't normally happen unless
    // the graph is degenerate) becomes its own root. Tasks hidden under a
    // folded ancestor are skipped — they were intentionally hidden by the
    // user and must not be promoted to independent roots.
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

  /// Splits a flattened forest into per-tree groups so each root becomes
  /// its own card on screen. Groups are sorted by urgency.
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

  /// Sorts trees as single units. Each tree's priority is driven by its
  /// most urgent incomplete task, so finishing that task naturally shifts
  /// the tree to its next most urgent state.
  ///
  /// Order (top to bottom):
  /// 1. Trees with incomplete tasks that have a due date — earliest due
  ///    date first (most urgent on top).
  /// 2. Trees still incomplete but with no due dates — oldest tree
  ///    (by its earliest createdAt) first.
  /// 3. Fully completed trees — newest completion first.
  List<List<FlatTaskNode>> _sortTrees(List<List<FlatTaskNode>> trees) {
    final sorted = [...trees];
    sorted.sort(_compareTrees);
    return sorted;
  }

  /// Categories (ascending: smaller = higher priority = shown first):
  /// 0 = has an incomplete task with a due date.
  /// 1 = incomplete but no due dates.
  /// 2 = fully completed.
  ({int category, DateTime primary}) _treeSortKey(List<FlatTaskNode> tree) {
    final tasks = tree.map((n) => n.task).toList();
    final incomplete = tasks.where((t) => !t.isCompleted).toList();

    final dueDates =
        incomplete
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
    final completed =
        tasks
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

    // Categories 0 and 1 sort ascending (earliest first); category 2
    // (completed) sorts descending so the newest completion wins.
    if (ka.category == 2) {
      return kb.primary.compareTo(ka.primary);
    }
    return ka.primary.compareTo(kb.primary);
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white, // set text color to white
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTaskDialog,
        backgroundColor: Colors.teal[300],
        foregroundColor: Colors.white,
        tooltip: 'create new task',
        child: Icon(Icons.add),
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
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
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

    final trees = _sortTrees(_groupIntoTrees(_buildTaskForest(_tasks)));

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: trees.length,
        itemBuilder: (BuildContext context, int index) {
          final tree = trees[index];
          return ChainTimeline(
            nodes: tree,
            formatDate: _formatDate,
            onToggleComplete: _toggleComplete,
            onEdit: _openEditTaskDialog,
            onDelete: _confirmDeleteTask,
            onAddSubtask: _openCreateSubtaskDialog,
            onToggleFold: _toggleFold,
            onOpen: _openStepPage,
            onDuplicate: _duplicateTask,
          );
        },
      ),
    );
  }
}
