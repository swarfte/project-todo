import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/errorMessageBox.dart';
import 'package:project_todo/components/successSnackBar.dart';
import 'package:project_todo/models.dart';

class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({super.key, required this.task});

  final Task task;

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _nameController;
  late bool _isCompleted;

  // Optional due date. null means the task has no deadline.
  DateTime? _dueDate;

  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _isCompleted = widget.task.isCompleted;
    _dueDate = widget.task.dueDate;
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
        previousTaskId: widget.task.previousTaskId,
        completedAt: _isCompleted
            ? (widget.task.completedAt ?? DateTime.now())
            : null,
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
            const SizedBox(height: 8),

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
