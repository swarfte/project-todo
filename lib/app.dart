import 'package:flutter/material.dart';
import 'package:project_todo/pages/project.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Todo',
      theme: ThemeData(),
      home: const ProjectPage(),
    );
  }
}
