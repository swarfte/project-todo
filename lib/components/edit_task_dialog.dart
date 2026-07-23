import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/error_message_box.dart';
import 'package:project_todo/components/success_snackbar.dart';
import 'package:project_todo/models.dart';

class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({
    super.key,
    required this.task,
    this.existingTasks = const [],
  });

  final Task task;

  // Other tasks in the same project. Used to populate the
  // "previous task" selector so the dialog doesn't need to refetch.
  final List<Task> existingTasks;

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _nameController;
  late bool _isCompleted;

  // Optional due date. null means the task has no deadline.
  DateTime? _dueDate;

  // The task that comes immediately before this one. null means the
  // task is a starting point (no predecessor). Pre-seeded from the
  // task's current previousTaskId if it points to a known task.
  late Task? _selectedPreviousTask;

  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _isCompleted = widget.task.isCompleted;
    _dueDate = widget.task.dueDate;
    _selectedPreviousTask = _resolveInitialPreviousTask();
  }

  // Finds the Task object matching the task's current previousTaskId, so
  // the dropdown can show the existing predecessor. Falls back to null
  // (start of chain) if the id is missing or no longer exists.
  Task? _resolveInitialPreviousTask() {
    final prevId = widget.task.previousTaskId;
    if (prevId == null) return null;
    for (final t in widget.existingTasks) {
      if (t.id == prevId) return t;
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _save() async {
    // Avoid duplicate submissions.
    if (_isSending) return;

    final taskName = _nameController.text.trim();

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

    try {
      final apiService = APIService();
      final updated = Task(
        id: widget.task.id,
        name: taskName,
        projectId: widget.task.projectId,
        isCompleted: _isCompleted,
        createdAt: widget.task.createdAt,
        updatedAt: widget.task.updatedAt,
        dueDate: _dueDate,
        previousTaskId: _selectedPreviousTask?.id,
        completedAt: _isCompleted
            ? (widget.task.completedAt ?? DateTime.now())
            : null,
        isFolded: widget.task.isFolded,
      );

      final isSuccess = await apiService.updateTask(updated);

      // The dialog may have been removed while waiting for the API.
      if (!mounted) return;

      if (!isSuccess) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to update task.';
        });
        return;
      }

      // Get the messenger before closing the dialog.
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      SuccessSnackBar.show(
        messenger,
        message: 'Task "$taskName" updated successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to update task. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Candidate predecessors: every task in the project except the one
    // being edited (a task can't be its own predecessor).
    final candidates = widget.existingTasks
        .where((t) => t.id != widget.task.id)
        .toList();

    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isSending,
              decoration: const InputDecoration(labelText: 'Task Name'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            // Previous task selector.
            if (candidates.isNotEmpty) ...[
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
                  ...candidates.map(
                    (task) => DropdownMenuItem<Task?>(
                      value: task,
                      child: Text(task.name),
                    ),
                  ),
                ],
                onChanged: _isSending
                    ? null
                    : (Task? value) {
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
                'No other tasks to link as a predecessor.',
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
          onPressed: _isSending ? null : _save,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
