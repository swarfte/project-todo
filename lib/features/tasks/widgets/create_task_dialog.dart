import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/common/widgets/error_message_box.dart';
import 'package:project_todo/common/widgets/success_snackbar.dart';
import 'package:project_todo/core/models/task.dart';
import 'package:project_todo/features/tasks/tasks_vm.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  const CreateTaskDialog({
    super.key,
    required this.projectId,
    this.previousTask,
  });

  final String projectId;

  /// When set, the dialog creates a subtask that comes after this task and
  /// the "previous task" selector is hidden — the predecessor is fixed by
  /// the caller (e.g. the per-task "add subtask" shortcut).
  final Task? previousTask;

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final TextEditingController _taskNameController = TextEditingController();

  String? _errorMessage;
  bool _isSending = false;

  // The task that comes immediately before the new one. null means the new
  // task is a starting point (no predecessor). Pre-seeded from
  // widget.previousTask when the dialog is opened as a subtask creator.
  late Task? _selectedPreviousTask;

  // Optional due date. null means the task has no deadline.
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _selectedPreviousTask = widget.previousTask;
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  // Opens a date picker so the user can choose an optional due date.
  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select due date (optional)',
    );

    if (!mounted) return;

    setState(() {
      _dueDate = picked;
    });
  }

  void _clearDueDate() {
    setState(() {
      _dueDate = null;
    });
  }

  Future<void> _createTask() async {
    // Avoid duplicate submissions.
    if (_isSending) return;

    final taskName = _taskNameController.text.trim();

    if (taskName.isEmpty) {
      setState(() {
        _errorMessage = 'Task name cannot be empty.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(tasksProvider(widget.projectId).notifier)
        .createTask(
          taskName,
          previousTaskId: _selectedPreviousTask?.id,
          dueDate: _dueDate,
        );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to create task.';
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(context).pop();

    SuccessSnackBar.show(
      messenger,
      message: 'Task $taskName created successfully.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // The predecessor is fixed when the dialog is opened as a subtask
    // creator; only show the selector when it is free to choose. When free,
    // populate it from the project's loaded task list.
    final hasFixedPrevious = widget.previousTask != null;
    final existingTasks = ref.watch(taskListProvider(widget.projectId));

    return AlertDialog(
      title: Text(hasFixedPrevious ? 'Create Subtask' : 'Create New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _taskNameController,
              enabled: !_isSending,
              decoration: const InputDecoration(labelText: 'Task Name'),
              onSubmitted: (_) => _createTask(),
            ),
            const SizedBox(height: 16),

            // Subtask mode: predecessor is fixed, just show the context.
            if (hasFixedPrevious) ...[
              Text(
                'This task will come after "${_selectedPreviousTask!.name}".',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ] else if (existingTasks.isNotEmpty) ...[
              // Previous task selector.
              DropdownButtonFormField<Task?>(
                initialValue: _selectedPreviousTask,
                decoration: const InputDecoration(
                  labelText: 'Previous Task',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<Task?>(
                    value: null,
                    child: Text(
                      'None (start of chain)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  ...existingTasks.map(
                    (task) => DropdownMenuItem<Task?>(
                      value: task,
                      child: Text(task.name),
                    ),
                  ),
                ],
                onChanged: _isSending
                    ? null
                    : (value) {
                        setState(() {
                          _selectedPreviousTask = value;
                        });
                      },
              ),
              const SizedBox(height: 8),
              Text(
                _selectedPreviousTask == null
                    ? 'This task will start a new chain.'
                    : 'This task will come after "${_selectedPreviousTask!.name}".',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ] else ...[
              Text(
                'This will be the first task in the project.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],

            const SizedBox(height: 16),

            // Optional due date selector.
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'No due date'
                        : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                    style: TextStyle(
                      color: _dueDate == null ? Colors.grey[600] : null,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSending ? null : _pickDueDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dueDate == null ? 'Set' : 'Change'),
                ),
                if (_dueDate != null)
                  IconButton(
                    tooltip: 'Remove due date',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isSending ? null : _clearDueDate,
                  ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              ErrorMessageBox(errorMessage: _errorMessage!),
            ],

            if (_isSending) ...[const LinearProgressIndicator()],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _createTask,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
