import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/core/models/project.dart';
import 'package:project_todo/core/network/handler.dart';
import 'package:project_todo/core/state/network_providers.dart';

/// A project row plus its derived task counts, ready for display.
class ProjectRow {
  const ProjectRow({
    required this.project,
    required this.total,
    required this.completed,
  });

  final Project project;
  final int total;
  final int completed;

  /// A project is "completed" iff it has at least one task and all of them
  /// are done. A project with no tasks is treated as incomplete. Mirrors the
  /// old `_isProjectCompleted` helper in the project page.
  bool get isCompleted => total > 0 && completed == total;
}

/// The ordered list of project rows shown on the projects page.
class ProjectsView {
  const ProjectsView(this.rows);
  final List<ProjectRow> rows;

  static const empty = ProjectsView([]);
}

/// Loads the projects list together with per-project task counts and exposes
/// create/update/delete operations.
///
/// This is the projects feature's view-model. The page subscribes to the
/// [AsyncValue] it emits and never talks to [ApiService] directly. Reads fetch
/// the project list and the global task-count map in parallel and join them;
/// writes re-run the load so the UI always reflects the server state.
class ProjectsNotifier extends AsyncNotifier<ProjectsView> {
  @override
  Future<ProjectsView> build() async {
    final api = ref.read(apiServiceProvider);

    // Fetch projects and task counts in parallel to keep latency low.
    final results = await Future.wait([
      api.getProjectList(),
      api.getTaskCountsByProject(),
    ]);
    final projectsResult = results[0] as ApiResult<List<Project>>;
    final countsResult =
        results[1] as ApiResult<Map<String, ({int total, int completed})>>;

    final projects = projectsResult.dataOrNull ?? const [];
    final counts = countsResult.dataOrNull ?? const {};

    return ProjectsView(_buildRows(projects, counts));
  }

  /// Joins projects with their counts and orders them for display:
  ///   1. Incomplete projects first; completed projects last.
  ///   2. Within each group, newest `updatedAt` first, so the project the
  ///      user (or the app, via a task-create bump) most recently touched sits
  ///      on top.
  List<ProjectRow> _buildRows(
    List<Project> projects,
    Map<String, ({int total, int completed})> counts,
  ) {
    final rows = projects.map((p) {
      final c = counts[p.id];
      return ProjectRow(
        project: p,
        total: c?.total ?? 0,
        completed: c?.completed ?? 0,
      );
    }).toList();

    rows.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return b.project.updatedAt.compareTo(a.project.updatedAt);
    });
    return rows;
  }

  /// Re-fetches the list. Called after mutations (and pull-to-refresh) so the
  /// UI reflects the new server state. `ref.invalidateSelf()` re-runs [build]
  /// while preserving the previous data as the loading fallback, so the UI
  /// doesn't flash empty during a refresh.
  Future<void> reload() async {
    ref.invalidateSelf();
  }

  Future<ApiResult<bool>> createProject(String name) async {
    final result = await ref.read(apiServiceProvider).createProject(name);
    if (result.isSuccess) await reload();
    return result;
  }

  Future<ApiResult<bool>> updateProject(Project project) async {
    final result = await ref.read(apiServiceProvider).updateProject(project);
    if (result.isSuccess) await reload();
    return result;
  }

  Future<ApiResult<bool>> deleteProject(String projectId) async {
    final result = await ref.read(apiServiceProvider).deleteProject(projectId);
    if (result.isSuccess) await reload();
    return result;
  }

  /// Re-establishes connectivity after settings are saved (new URL/creds).
  /// Returns the connect result and, on success, reloads the list so the new
  /// user's projects show up.
  Future<ApiResult<bool>> reconnect() async {
    final result = await ref.read(apiServiceProvider).connect();
    if (result.isSuccess) await reload();
    return result;
  }
}

/// The projects feature's provider. Non-family (no parameter).
final AsyncNotifierProvider<ProjectsNotifier, ProjectsView> projectsProvider =
    AsyncNotifierProvider(ProjectsNotifier.new);
