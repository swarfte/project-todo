import 'package:flutter/material.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/errorMessageBox.dart';
import 'package:project_todo/components/successSnackBar.dart';

class ProjectDialog extends StatefulWidget {
  const ProjectDialog({super.key});

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  final TextEditingController _projectNameController = TextEditingController();

  String? _errorMessage;
  bool _isSending = false;

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    final projectName = _projectNameController.text.trim();

    if (projectName.isEmpty) {
      setState(() {
        _errorMessage = 'Project name cannot be empty.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null; // Clear previous error messages
    });

    final apiService = APIService();
    final isSuccess = await apiService.createProject(projectName);

    if (!isSuccess) {
      setState(() {
        _errorMessage = 'Failed to create project.';
      });
      return;
    }

    // Close the dialog on success.
    if (mounted && isSuccess) {
      Navigator.of(context).pop();
      final messenger = ScaffoldMessenger.of(context);
      SuccessSnackBar.show(
        messenger,
        message: 'Project $projectName created successfully.',
      );
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
