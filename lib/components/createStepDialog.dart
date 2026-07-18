import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/errorMessageBox.dart';
import 'package:project_todo/components/successSnackBar.dart';

class CreateStepDialog extends StatefulWidget {
  const CreateStepDialog({
    super.key,
    required this.taskId,
    this.previousStepId,
    this.previousStepName,
  });

  final String taskId;

  /// When set, the new step is appended after the step with this id. null
  /// means the new step starts the chain (used for the first step).
  final String? previousStepId;

  /// Display name of the previous step, used only for the hint line.
  final String? previousStepName;

  @override
  State<CreateStepDialog> createState() => _CreateStepDialogState();
}

class _CreateStepDialogState extends State<CreateStepDialog> {
  final TextEditingController _nameController = TextEditingController();

  String? _errorMessage;
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createStep() async {
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
      final isSuccess = await apiService.createStep(
        name,
        widget.taskId,
        previousStepId: widget.previousStepId,
      );

      // The dialog may have been removed while waiting for the API.
      if (!mounted) return;

      if (!isSuccess) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to create step.';
        });
        return;
      }

      // Get the messenger before closing the dialog.
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      SuccessSnackBar.show(
        messenger,
        message: 'Step "$name" created successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to create step. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Step'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isSending,
              decoration: const InputDecoration(labelText: 'Step Name'),
              onSubmitted: (_) => _createStep(),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              widget.previousStepId == null
                  ? 'This will be the first step in the chain.'
                  : 'This step will come after "${widget.previousStepName}".',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
          onPressed: _isSending ? null : _createStep,
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
