import 'package:flutter/material.dart';
import 'package:project_todo/logger.dart';
import 'package:project_todo/pages/project.dart';

void main() {
  initLogging();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Todo',
      theme: ThemeData(),
      home: const HomePage(),
    );
  }
}
