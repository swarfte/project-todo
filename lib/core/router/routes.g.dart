// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$projectsRoute, $tasksRoute, $stepsRoute];

RouteBase get $projectsRoute => GoRouteData.$route(
  path: '/projects',
  hasOverriddenOnExit: false,
  factory: $ProjectsRoute._fromState,
);

mixin $ProjectsRoute on GoRouteData {
  static ProjectsRoute _fromState(GoRouterState state) => const ProjectsRoute();

  @override
  String get location => GoRouteData.$location('/projects');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $tasksRoute => GoRouteData.$route(
  path: '/projects/:projectId',
  hasOverriddenOnExit: false,
  factory: $TasksRoute._fromState,
);

mixin $TasksRoute on GoRouteData {
  static TasksRoute _fromState(GoRouterState state) =>
      TasksRoute(state.pathParameters['projectId']!);

  TasksRoute get _self => this as TasksRoute;

  @override
  String get location => GoRouteData.$location(
    '/projects/${Uri.encodeComponent(_self.projectId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $stepsRoute => GoRouteData.$route(
  path: '/projects/:projectId/tasks/:taskId',
  hasOverriddenOnExit: false,
  factory: $StepsRoute._fromState,
);

mixin $StepsRoute on GoRouteData {
  static StepsRoute _fromState(GoRouterState state) => StepsRoute(
    state.pathParameters['projectId']!,
    state.pathParameters['taskId']!,
  );

  StepsRoute get _self => this as StepsRoute;

  @override
  String get location => GoRouteData.$location(
    '/projects/${Uri.encodeComponent(_self.projectId)}/tasks/${Uri.encodeComponent(_self.taskId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
