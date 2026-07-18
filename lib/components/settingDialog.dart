import 'package:flutter/material.dart';
import 'package:project_todo/preferences.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/errorMessageBox.dart';
import 'package:project_todo/components/loadingProgressBar.dart';
import 'package:project_todo/components/successSnackBar.dart';

class SettingDialog extends StatefulWidget {
  const SettingDialog({super.key});

  @override
  State<SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<SettingDialog> {
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final configService = ConfigService();

    final apiUrl = await configService.getApiUrl();
    final username = await configService.getUsername();
    final password = await configService.getPassword();

    // Check mounted after all asynchronous operations.
    if (!mounted) return;

    _apiUrlController.text = apiUrl;
    _usernameController.text = username;
    _passwordController.text = password;
  }

  Future<void> _saveSettings() async {
    // Prevent multiple submissions.
    if (_isSaving) return;

    final apiUrl = _apiUrlController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Basic validation.
    if (apiUrl.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please complete all fields.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final configService = ConfigService();

      await configService.saveApiUrl(apiUrl);
      await configService.saveUsername(username);
      await configService.savePassword(password);

      final apiService = APIService();
      final isSuccess = await apiService.connectDB();

      if (!mounted) return;

      if (!isSuccess) {
        setState(() {
          _isSaving = false;
          _errorMessage =
              'Connection failed. Please check the API URL, username, and password.';
        });

        // Do not close the dialog.
        return;
      }

      // Close only when the connection succeeds.
      Navigator.of(context).pop(true);

      // Show a success message at the bottom.
      final messenger = ScaffoldMessenger.of(context);
      SuccessSnackBar.show(
        messenger,
        message: 'Settings saved and connection successful.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'Unable to connect to the server. Please try again.';
      });

      // You can log the detailed error during development.
      debugPrint('connectDB failed: $error');
    }
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _apiUrlController,
              enabled: !_isSaving,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'API URL'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              enabled: !_isSaving,
              obscureText: true,
              onSubmitted: (_) => _saveSettings(),
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            // Display connection error inside the dialog.
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              ErrorMessageBox(errorMessage: _errorMessage!),
            ],

            if (_isSaving) ...[
              const LoadingProgressBar(
                message: 'Saving settings and testing connection...',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          child: Text(_isSaving ? 'Connecting...' : 'Save'),
        ),
      ],
    );
  }
}
