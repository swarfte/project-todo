import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_todo/core/router/routes.dart';

/// Provides the application's [GoRouter].
///
/// The route tree itself is declarative — the typed [TypedGoRoute] classes in
/// [routes.dart] generate `GoRouteData.$route`, which we hand to [GoRouter].
/// This app has no dedicated login screen, so there is no auth redirect: the
/// home page is always `/projects`, and connectivity is established at startup
/// and re-attempted lazily by the network layer when a request runs.
final Provider<GoRouter> goRouterProvider = Provider((ref) {
  final router = GoRouter(
    initialLocation: const ProjectsRoute().location,
    routes: $appRoutes,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Text('No route for ${state.uri}'),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
