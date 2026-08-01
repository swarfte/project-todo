import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:project_todo/features/projects/projects_page.dart';
import 'package:project_todo/features/steps/steps_page.dart';
import 'package:project_todo/features/tasks/tasks_page.dart';

part 'routes.g.dart';

/// Type-safe, declarative route definitions for the app.
///
/// The app has a three-level hierarchy mirroring its data model:
///   `/projects`                  — the project list (home)
///   `/projects/:projectId`       — a project's task tree
///   `/projects/:projectId/tasks/:taskId` — a task's step chain
///
/// `go_router_builder` turns each [GoRouteData] subclass into a typed
/// navigation helper (e.g. `TasksRoute(projectId: id).go(context)`), so missing
/// parameters are caught at compile time rather than crashing at runtime.
@TypedGoRoute<ProjectsRoute>(path: '/projects')
class ProjectsRoute extends GoRouteData with $ProjectsRoute {
  const ProjectsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProjectsPage();
}

@TypedGoRoute<TasksRoute>(path: '/projects/:projectId')
class TasksRoute extends GoRouteData with $TasksRoute {
  TasksRoute(this.projectId);

  final String projectId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TasksPage(projectId: projectId);
}

@TypedGoRoute<StepsRoute>(path: '/projects/:projectId/tasks/:taskId')
class StepsRoute extends GoRouteData with $StepsRoute {
  StepsRoute(this.projectId, this.taskId);

  final String projectId;
  final String taskId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      StepsPage(projectId: projectId, taskId: taskId);
}
