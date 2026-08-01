import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionText extends StatefulWidget {
  const AppVersionText({super.key});

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  String _version = 'Reading version……';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) {
      return;
    }

    setState(() {
      _version =
          'Version ${packageInfo.version} '
          '(Build ${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_version);
  }
}
