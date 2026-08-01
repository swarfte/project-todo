import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/common/utils/date_formatter.dart';
import 'package:project_todo/common/widgets/pin_window_button.dart';
import 'package:project_todo/common/widgets/success_snackbar.dart';
import 'package:project_todo/core/router/routes.dart';
import 'package:project_todo/features/projects/projects_vm.dart';
import 'package:project_todo/features/projects/widgets/create_project_dialog.dart';
import 'package:project_todo/features/projects/widgets/edit_project_dialog.dart';
import 'package:project_todo/features/projects/widgets/project_progress_indicator.dart';
import 'package:project_todo/features/projects/widgets/setting_dialog.dart';

/// The projects list — the app's home screen.
///
/// Subscribes to [projectsProvider] (the feature's view-model) and renders the
/// resulting [ProjectsView]. All data access and mutations go through the VM,
/// so this widget holds no API or business logic — it only maps state to UI
/// and forwards user actions back to the VM.
class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  Future<void> _openCreateProjectDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );
  }

  Future<void> _openEditProjectDialog(
    BuildContext context,
    WidgetRef ref,
    ProjectRow row,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => EditProjectDialog(project: row.project),
    );
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    WidgetRef ref,
    ProjectRow row,
  ) async {
    // Capture the messenger before any await so it stays valid regardless of
    // how the dialog / delete resolves.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${row.project.name}"? '
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
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(projectsProvider.notifier).deleteProject(
          row.project.id,
        );

    if (result.isSuccess) {
      SuccessSnackBar.show(
        messenger,
        message: 'Project "${row.project.name}" deleted.',
      );
    } else {
      SuccessSnackBar.show(
        messenger,
        message: 'Failed to delete "${row.project.name}".',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProjects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Todo'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          const PinWindowButton(),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              // SettingDialog pops with `true` only when the connection
              // succeeds, `false` when cancelled.
              final saved = await showDialog<bool>(
                context: context,
                builder: (context) => const SettingDialog(),
              );

              // Refresh the project list when settings were saved and the
              // connection succeeded, so the new user's projects load.
              if (saved == true) {
                ref.read(projectsProvider.notifier).reload();
              }
            },
          ),
        ],
      ),
      body: asyncProjects.when(
        data: (view) => _buildBody(context, ref, view),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateProjectDialog(context),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        tooltip: 'create new project',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProjectsView view) {
    if (view.rows.isEmpty) {
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
      onRefresh: () => ref.read(projectsProvider.notifier).reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: view.rows.length,
        itemBuilder: (context, index) {
          final row = view.rows[index];
          return Card(
            child: ListTile(
              leading: ProjectProgressIndicator(
                completed: row.completed,
                total: row.total,
              ),
              title: Text(row.project.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    row.total == 0
                        ? 'No tasks'
                        : '${row.completed} / ${row.total} tasks done',
                    style: TextStyle(
                      fontSize: 13,
                      color: row.total == 0
                          ? Colors.grey[600]
                          : (row.completed == row.total
                                ? Colors.green[700]
                                : Colors.blue[700]),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${formatDate(row.project.updatedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              // Navigate by id only — the task page looks the project up via
              // projectMetaProvider, so a deep link or refresh still resolves.
              onTap: () =>
                  TasksRoute(row.project.id).go(context),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Project actions',
                onSelected: (value) {
                  if (value == 'edit') {
                    _openEditProjectDialog(context, ref, row);
                  } else if (value == 'delete') {
                    _confirmDeleteProject(context, ref, row);
                  }
                },
                itemBuilder: (context) => [
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 8),
          const Text('Failed to load projects. Pull to retry.'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(projectsProvider.notifier).reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
