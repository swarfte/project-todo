import 'package:flutter/material.dart';
import 'package:project_todo/adaptor.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/createTaskDialog.dart';
import 'package:project_todo/models.dart';

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
        final nextId = current.previousTaskId == null
            ? null
            : _findNextOf(byId, current.id, referencedAsPrev);
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
        backgroundColor: Colors.purple[400],
        foregroundColor: Colors.white, // set text color to white
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTaskDialog,
        backgroundColor: Colors.green[300],
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

    final chains = _groupChains(_tasks);

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: chains.length,
        itemBuilder: (BuildContext context, int index) {
          final chain = chains[index];
          return _ChainTimeline(chain: chain, formatDate: _formatDate);
        },
      ),
    );
  }
}

/// Renders one task chain as a vertical timeline: a colored connector line
/// with a numbered position badge for each task (1/3, 2/3, ...).
class _ChainTimeline extends StatelessWidget {
  const _ChainTimeline({required this.chain, required this.formatDate});

  final List<Task> chain;
  final String Function(DateTime) formatDate;

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
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < total; i++)
                  _TimelineRow(
                    task: chain[i],
                    position: i + 1,
                    total: total,
                    isFirst: i == 0,
                    isLast: i == total - 1,
                    formatDate: formatDate,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.task,
    required this.position,
    required this.total,
    required this.isFirst,
    required this.isLast,
    required this.formatDate,
  });

  final Task task;
  final int position;
  final int total;
  final bool isFirst;
  final bool isLast;
  final String Function(DateTime) formatDate;

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
          // Timeline gutter: connector line + position badge.
          SizedBox(
            width: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vertical connector line(s).
                Column(
                  children: [
                    // Top half of the line (hidden for the first row).
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirst ? Colors.transparent : lineColor,
                      ),
                    ),
                    // Bottom half of the line (hidden for the last row).
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : lineColor,
                      ),
                    ),
                  ],
                ),
                // Position badge centered over the gap.
                _PositionBadge(
                  position: position,
                  total: total,
                  isCompleted: task.isCompleted,
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
                            color: Colors.grey[600],
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
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
