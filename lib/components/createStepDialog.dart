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
    this.onSubmit,
  });

  final String taskId;

  /// When set, the new step is appended after the step with this id. null
  /// means the new step starts the chain (used for the first step).
  final String? previousStepId;

  /// Display name of the previous step, used only for the hint line.
  final String? previousStepName;

  /// When provided, the dialog delegates the actual creation to this
  /// callback instead of calling `createStep` directly. Used for insert
  /// mode, where the caller needs to splice the new step into the middle
  /// of the chain (create + re-link successor). The callback returns true
  /// on success; the dialog handles the success snackbar + pop.
  final Future<bool> Function(String name)? onSubmit;

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
      // Delegate to the caller's callback when provided (insert mode);
      // otherwise do a plain append via the API service.
      final isSuccess = widget.onSubmit != null
          ? await widget.onSubmit!(name)
          : await APIService().createStep(
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
    // Insert mode is signalled by the caller passing an onSubmit callback;
    // it changes the title and hint to describe a mid-chain splice rather
    // than a plain append.
    final isInsert = widget.onSubmit != null;

    return AlertDialog(
      title: Text(isInsert ? 'Insert Step' : 'Create New Step'),
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
                  : isInsert
                      ? 'Inserting after "${widget.previousStepName}". The steps that follow will shift down.'
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
