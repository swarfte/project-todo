import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/error_message_box.dart';
import 'package:project_todo/components/success_snackbar.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final TextEditingController _projectNameController = TextEditingController();

  String? _errorMessage;
  bool _isSending = false;

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    // Avoid duplicate submissions.
    if (_isSending) return;

    final projectName = _projectNameController.text.trim();

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
      final isSuccess = await apiService.createProject(projectName);

      // The dialog may have been removed while waiting for the API.
      if (!mounted) return;

      if (!isSuccess) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to create project.';
        });
        return;
      }

      // Get the messenger before closing the dialog.
      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      SuccessSnackBar.show(
        messenger,
        message: 'Project $projectName created successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to create project. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _projectNameController,
              enabled: !_isSending,
              decoration: const InputDecoration(labelText: 'Project Name'),
              onSubmitted: (_) => _createProject(),
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
          onPressed: _isSending ? null : _createProject,
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
