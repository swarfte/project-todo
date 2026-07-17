import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/errorMessageBox.dart';
import 'package:project_todo/components/successSnackBar.dart';
import 'package:project_todo/models.dart';

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({
    super.key,
    required this.projectId,
    required this.existingTasks,
  });

  final String projectId;

  // Tasks already belonging to this project. Used to populate the
  // "previous task" selector so the dialog doesn't need to refetch.
  final List<Task> existingTasks;

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final TextEditingController _taskNameController = TextEditingController();

  String? _errorMessage;
  bool _isSending = false;

  // The task that comes immediately before the new one. null means the
  // new task is a starting point (no predecessor).
  Task? _selectedPreviousTask;

  // Optional due date. null means the task has no deadline.
  DateTime? _dueDate;

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  // Opens a date picker so the user can choose an optional due date.
  // Selecting the same date as the current value clears it (treats the
  // tap as a toggle), letting the user opt out of a due date.
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

    try {
      final apiService = APIService();
      final isSuccess = await apiService.createTask(
        taskName,
        widget.projectId,
        previousTaskId: _selectedPreviousTask?.id,
        dueDate: _dueDate,
      );

      // The dialog may have been removed while waiting for the API.
      if (!mounted) return;

      if (!isSuccess) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to create task.';
        });
        return;
      }

      // Get the messenger before closing the dialog.
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      SuccessSnackBar.show(
        messenger,
        message: 'Task $taskName created successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to create task. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // When there are no existing tasks yet, there is nothing to select.
    final canSelectPrevious = widget.existingTasks.isNotEmpty;

    return AlertDialog(
      title: const Text('Create New Task'),
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

            // Previous task selector.
            if (canSelectPrevious) ...[
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
                  ...widget.existingTasks.map(
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
