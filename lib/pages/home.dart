import 'package:flutter/material.dart';
import 'package:project_todo/components/settingDialog.dart';

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
          // action when the button is pressed
        },
        backgroundColor: Colors.green[300], // 2. 設定按鈕背景顏色
        foregroundColor: Colors.white, // 1. 設定按鈕圖示顏色
        tooltip: 'create new project', // 4. 長按時顯示的提示文字
        child: Icon(Icons.add), // 3. 設定中間的加號圖示
      ),
    );
  }
}
