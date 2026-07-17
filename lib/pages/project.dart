import 'package:flutter/material.dart';
import 'package:project_todo/adaptor.dart';
import 'package:project_todo/api.dart';
import 'package:project_todo/components/settingDialog.dart';
import 'package:project_todo/components/createProjectDialog.dart';
import 'package:project_todo/components/editProjectDialog.dart';
import 'package:project_todo/components/successSnackBar.dart';
import 'package:project_todo/models.dart';
import 'package:project_todo/pages/task.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final APIService _apiService = APIService();

  List<Project> _projects = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final records = await _apiService.getProjectList();
      final projects = records
          .map((r) => ProjectAdaptor.fromJson(r.toJson()))
          .toList();

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Failed to load projects. Pull to retry.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateProjectDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CreateProjectDialog();
      },
    );

    // Refresh the list once the dialog is closed so newly created
    // projects show up immediately.
    if (mounted) {
      _loadProjects();
    }
  }

  Future<void> _openEditProjectDialog(Project project) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return EditProjectDialog(project: project);
      },
    );

    // Refresh the list once the dialog is closed so edited
    // projects show up immediately.
    if (mounted) {
      _loadProjects();
    }
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: Text(
            'Are you sure you want to delete "${project.name}"? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    final isSuccess = await _apiService.deleteProject(project.id);

    if (!mounted) return;

    if (isSuccess) {
      SuccessSnackBar.show(
        messenger,
        message: 'Project "${project.name}" deleted.',
      );
      _loadProjects();
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to delete "${project.name}".',
      );
    }
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateProjectDialog,
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white, //
        tooltip: 'create new project',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 8),
            Text(_loadError!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('No projects yet.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              'Tap + to create your first project.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _projects.length,
        itemBuilder: (BuildContext context, int index) {
          final project = _projects[index];
          return Card(
            child: ListTile(
              leading: Icon(
                project.isCompleted
                    ? Icons.check_circle
                    : Icons.folder_outlined,
                color: project.isCompleted ? Colors.green : Colors.blue[600],
              ),
              title: Text(project.name),
              subtitle: Text('Created ${_formatDate(project.createdAt)}'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        TaskPage(project: project),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (project.isCompleted)
                    Chip(
                      label: const Text('Done'),
                      backgroundColor: Colors.green[100],
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'Project actions',
                    onSelected: (String value) {
                      if (value == 'edit') {
                        _openEditProjectDialog(project);
                      } else if (value == 'delete') {
                        _confirmDeleteProject(project);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                          ),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red[400]),
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
