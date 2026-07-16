import 'package:flutter/material.dart';
import 'package:project_todo/components/settingDialog.dart';
import 'package:project_todo/components/projectDialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Todo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white, // set text color to white
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // show settingDialog when the settings button is pressed
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SettingDialog();
                },
              );
            },
          ),
        ],
      ),
      body: Center(child: Column()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return ProjectDialog();
            },
          );
        },
        backgroundColor: Colors.green[300],
        foregroundColor: Colors.white, //
        tooltip: 'create new project',
        child: Icon(Icons.add),
      ),
    );
  }
}
