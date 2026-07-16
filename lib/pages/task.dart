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
        return CreateTaskDialog(projectId: widget.project.id);
      },
    );

    // Refresh the list once the dialog is closed so newly created
    // tasks show up immediately.
    if (mounted) {
      _loadTasks();
    }
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
        backgroundColor: Colors.blue[600],
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

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _tasks.length,
        itemBuilder: (BuildContext context, int index) {
          final task = _tasks[index];
          final subtitle = task.dueDate != null
              ? 'Due ${_formatDate(task.dueDate!)}'
              : 'Created ${_formatDate(task.createdAt)}';

          return Card(
            child: ListTile(
              leading: Icon(
                task.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: task.isCompleted ? Colors.green : Colors.blue[600],
              ),
              title: Text(
                task.name,
                style: TextStyle(
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.isCompleted ? Colors.grey : null,
                ),
              ),
              subtitle: Text(subtitle),
              trailing: task.isCompleted
                  ? Chip(
                      label: const Text('Done'),
                      backgroundColor: Colors.green[100],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
