import 'package:flutter/material.dart';
import 'package:project_todo/preferences.dart';

class SettingDialog extends StatefulWidget {
  SettingDialog({super.key});

  @override
  State<SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<SettingDialog> {
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final configService = ConfigService();
    if (!mounted) return;
    _apiUrlController.text = await configService.getApiUrl();
    _usernameController.text = await configService.getUsername();
    _passwordController.text = await configService.getPassword();
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _apiUrlController,
            decoration: const InputDecoration(labelText: 'API URL'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final configService = ConfigService();
            String apiUrl = _apiUrlController.text;
            String username = _usernameController.text;
            String password = _passwordController.text;

            await configService.saveApiUrl(apiUrl);
            await configService.saveUsername(username);
            await configService.savePassword(password);

            if (!mounted) return;
            Navigator.of(context).pop(true);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
