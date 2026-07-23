import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/error_message_box.dart';
import 'package:project_todo/components/success_snackbar.dart';
import 'package:project_todo/models.dart';

class EditProjectDialog extends StatefulWidget {
  const EditProjectDialog({super.key, required this.project});

  final Project project;

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  late final TextEditingController _nameController;

  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Avoid duplicate submissions.
    if (_isSending) return;

    final projectName = _nameController.text.trim();

    if (projectName.isEmpty) {
      setState(() {
        _errorMessage = 'Project name cannot be empty.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final apiService = APIService();
      final updated = Project(
        id: widget.project.id,
        name: projectName,
        userId: widget.project.userId,
        createdAt: widget.project.createdAt,
        updatedAt: widget.project.updatedAt,
      );

      final isSuccess = await apiService.updateProject(updated);

      // The dialog may have been removed while waiting for the API.
      if (!mounted) return;

      if (!isSuccess) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to update project.';
        });
        return;
      }

      // Get the messenger before closing the dialog.
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      SuccessSnackBar.show(
        messenger,
        message: 'Project "$projectName" updated successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to update project. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isSending,
              decoration: const InputDecoration(labelText: 'Project Name'),
              onSubmitted: (_) => _save(),
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
