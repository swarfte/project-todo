import 'package:flutter/material.dart';
import 'package:project_todo/adaptor.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/createTaskDialog.dart';
import 'package:project_todo/components/editTaskDialog.dart';
import 'package:project_todo/components/successSnackBar.dart';
import 'package:project_todo/models.dart';
import 'package:project_todo/components/chainTimeline.dart';

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

  Future<void> _openEditTaskDialog(Task task) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return EditTaskDialog(task: task);
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

  /// Groups tasks into ordered chains by following `previousTaskId`.
  ///
  /// Each returned list is one chain in execution order (predecessor
  /// first). Tasks whose predecessor is missing or whose chain forms a
  /// cycle are treated as their own chain heads so the UI never breaks.
  List<List<Task>> _groupChains(List<Task> tasks) {
    final byId = {for (final t in tasks) t.id: t};

    // Find every task that is referenced as someone's predecessor.
    final referencedAsPrev = <String>{
      for (final t in tasks)
        if (t.previousTaskId != null) t.previousTaskId!,
    };

    // Chain heads: tasks with no predecessor, or whose predecessor is
    // not in this project's task set.
    final heads = <Task>[];
    for (final t in tasks) {
      final hasValidPrev =
          t.previousTaskId != null && byId.containsKey(t.previousTaskId);
      if (!hasValidPrev) heads.add(t);
    }

    final result = <List<Task>>[];
    final visited = <String>{};

    for (final head in heads) {
      final chain = <Task>[];
      Task? current = head;

      while (current != null && !visited.contains(current.id)) {
        visited.add(current.id);
        chain.add(current);

        final nextId = _findNextOf(byId, current.id, referencedAsPrev);

        current = nextId == null ? null : byId[nextId];
      }

      if (chain.isNotEmpty) result.add(chain);
    }

    // Safety net: any task not yet placed (shouldn't normally happen
    // unless the graph is degenerate) becomes its own chain.
    for (final t in tasks) {
      if (!visited.contains(t.id)) result.add([t]);
    }

    return result;
  }

  /// Returns the id of the task whose predecessor is [prevId], i.e. the
  /// "next" task after [prevId] in its chain. null if there is none.
  String? _findNextOf(
    Map<String, Task> byId,
    String prevId,
    Set<String> referencedAsPrev,
  ) {
    if (!referencedAsPrev.contains(prevId)) return null;
    for (final entry in byId.entries) {
      if (entry.value.previousTaskId == prevId) return entry.key;
    }
    return null;
  }

  /// Sorts chains as single units. Each chain's priority is driven by its
  /// most urgent incomplete task, so finishing that task naturally shifts
  /// the chain to its next most urgent state.
  ///
  /// Order (top to bottom):
  /// 1. Chains with incomplete tasks that have a due date — earliest due
  ///    date first (most urgent on top).
  /// 2. Chains still incomplete but with no due dates — oldest chain
  ///    (by its earliest createdAt) first.
  /// 3. Fully completed chains — newest completion first.
  List<List<Task>> _sortChains(List<List<Task>> chains) {
    final sorted = [...chains];
    sorted.sort(_compareChains);
    return sorted;
  }

  /// Categories (ascending: smaller = higher priority = shown first):
  /// 0 = has an incomplete task with a due date.
  /// 1 = incomplete but no due dates.
  /// 2 = fully completed.
  ({int category, DateTime primary}) _chainSortKey(List<Task> chain) {
    final incomplete = chain.where((t) => !t.isCompleted).toList();

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
      final oldest = chain
          .map((t) => t.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      return (category: 1, primary: oldest);
    }

    // Fully done: newest completion first.
    final completed =
        chain
            .where((t) => t.completedAt != null)
            .map((t) => t.completedAt!)
            .toList()
          ..sort();
    final latest = completed.isNotEmpty
        ? completed.last
        : chain.first.createdAt;
    return (category: 2, primary: latest);
  }

  int _compareChains(List<Task> a, List<Task> b) {
    final ka = _chainSortKey(a);
    final kb = _chainSortKey(b);

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
        backgroundColor: Colors.purple[500],
        foregroundColor: Colors.white, // set text color to white
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTaskDialog,
        backgroundColor: Colors.purple[300],
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

    final chains = _sortChains(_groupChains(_tasks));

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: chains.length,
        itemBuilder: (BuildContext context, int index) {
          final chain = chains[index];
          return ChainTimeline(
            chain: chain,
            formatDate: _formatDate,
            onToggleComplete: _toggleComplete,
            onEdit: _openEditTaskDialog,
            onDelete: _confirmDeleteTask,
          );
        },
      ),
    );
  }
}
