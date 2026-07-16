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

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  /// Builds the chain leading up to the new task, e.g.
  /// "Task A  ->  Task B  ->  New Task".
  List<Task> _buildChain(Task leaf) {
    final byId = {for (final t in widget.existingTasks) t.id: t};
    final chain = <Task>[leaf];
    Task? current = leaf;
    final visited = <String>{leaf.id};

    while (current?.previousTaskId != null) {
      final prev = byId[current!.previousTaskId!];
      if (prev == null || visited.contains(prev.id)) break;
      chain.insert(0, prev);
      visited.add(prev.id);
      current = prev;
    }

    return chain;
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

  Widget _buildChainPreview() {
    final newTaskName = _taskNameController.text.trim();
    final displayNewName =
        newTaskName.isEmpty ? 'New Task' : newTaskName;

    final children = <Widget>[];

    if (_selectedPreviousTask != null) {
      final chain = _buildChain(_selectedPreviousTask!);
      children.add(_chainChip(_selectedPreviousTask!.name,
          isPlaceholder: false, icon: Icons.adjust));
      // Show the full ancestor chain collapsed as a count if there is one.
      if (chain.length > 1) {
        children.insert(
          0,
          _chainChip('+${chain.length - 1} before', faded: true),
        );
      }
    }

    children.add(_chainChip(displayNewName,
        isPlaceholder: newTaskName.isEmpty, highlight: true));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: _interleave(children),
      ),
    );
  }

  /// Inserts arrow separators between each chip.
  List<Widget> _interleave(List<Widget> chips) {
    final result = <Widget>[];
    final arrow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.arrow_forward, size: 16, color: Colors.blue[400]),
    );
    for (var i = 0; i < chips.length; i++) {
      result.add(chips[i]);
      if (i < chips.length - 1) result.add(arrow);
    }
    return result;
  }

  Widget _chainChip(
    String label, {
    bool isPlaceholder = false,
    bool faded = false,
    bool highlight = false,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.blue[600]
            : (faded ? Colors.grey[200] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? Colors.blue[600]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon,
                  size: 14,
                  color: highlight ? Colors.white : Colors.blue[400]),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: highlight
                  ? Colors.white
                  : (faded ? Colors.grey[500] : Colors.blue[800]),
              fontStyle: isPlaceholder ? FontStyle.italic : null,
              fontWeight: highlight ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
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
              onChanged: (_) => setState(() {}),
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
              const SizedBox(height: 16),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'This will be the first task in the project.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ],

            // Live chain preview.
            Text(
              'Resulting order',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildChainPreview(),

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
