import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/core/router/app_router.dart';

/// The app shell.
///
/// Uses [MaterialApp.router] wired to the go_router from [goRouterProvider],
/// so navigation is declarative and type-safe (see `routes.dart`). There is no
/// home/nav logic here — that all lives in the router.
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Project Todo',
      theme: ThemeData(),
      routerConfig: router,
    );
  }
}
