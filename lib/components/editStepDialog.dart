import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/errorMessageBox.dart';
import 'package:project_todo/components/successSnackBar.dart';
// `models.dart` declares a `Step` class that collides with Flutter's own
// `Step` (from the Stepper widget), so import it under a prefix.
import 'package:project_todo/models.dart' as models;

class EditStepDialog extends StatefulWidget {
  const EditStepDialog({super.key, required this.step});

  final models.Step step;

  @override
  State<EditStepDialog> createState() => _EditStepDialogState();
}

class _EditStepDialogState extends State<EditStepDialog> {
  late final TextEditingController _nameController;
  late bool _isCompleted;

  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.step.name);
    _isCompleted = widget.step.isCompleted;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Avoid duplicate submissions.
    if (_isSending) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Step name cannot be empty.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final apiService = APIService();
      final updated = models.Step(
        id: widget.step.id,
        name: name,
        taskId: widget.step.taskId,
        isCompleted: _isCompleted,
        createdAt: widget.step.createdAt,
        updatedAt: widget.step.updatedAt,
        previousStepId: widget.step.previousStepId,
      );

      final isSuccess = await apiService.updateStep(updated);

      // The dialog may have been removed while waiting for the API.
      if (!mounted) return;

      if (!isSuccess) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to update step.';
        });
        return;
      }

      // Get the messenger before closing the dialog.
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      SuccessSnackBar.show(
        messenger,
        message: 'Step "$name" updated successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to update step. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Step'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isSending,
              decoration: const InputDecoration(labelText: 'Step Name'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),

            // Completion toggle. Steps have no due date or fold state.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Completed'),
              value: _isCompleted,
              onChanged: _isSending
                  ? null
                  : (value) {
                      setState(() {
                        _isCompleted = value;
                      });
                    },
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
