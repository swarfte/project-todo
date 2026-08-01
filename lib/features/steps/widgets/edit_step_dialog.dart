import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/common/widgets/error_message_box.dart';
import 'package:project_todo/common/widgets/success_snackbar.dart';
import 'package:project_todo/core/models/task_step.dart';
import 'package:project_todo/features/steps/steps_vm.dart';

class EditStepDialog extends ConsumerStatefulWidget {
  const EditStepDialog({
    super.key,
    required this.taskId,
    required this.step,
  });

  final String taskId;
  final TaskStep step;

  @override
  ConsumerState<EditStepDialog> createState() => _EditStepDialogState();
}

class _EditStepDialogState extends ConsumerState<EditStepDialog> {
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

    final result = await ref
        .read(stepsProvider(widget.taskId).notifier)
        .updateStep(
          widget.step.copyWith(name: name, isCompleted: _isCompleted),
        );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to update step.';
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    Navigator.of(context).pop();

    SuccessSnackBar.show(
      messenger,
      message: 'Step "$name" updated successfully.',
    );
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
