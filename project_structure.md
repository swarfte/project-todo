```
C:\USERS\SWARFTE\DESKTOP\CODING\PROJECT-TODO\LIB
│   app.dart                        # MaterialApp.router (GoRouter)
│   main.dart                       # ProviderScope + window_manager init
│
├───common
│   ├───utils                       # shared, feature-agnostic helpers
│   │       date_formatter.dart     #   formatDate() (shared by all pages)
│   │       step_orderer.dart       #   orderSteps() (network + step page)
│   │       task_forest.dart        #   FlatTaskNode + buildTaskForest()
│   │
│   └───widgets                     # reusable UI widgets
│           app_version.dart
│           error_message_box.dart
│           loading_progress_bar.dart
│           pin_window_button.dart  #   subscribes to alwaysOnTopProvider
│           success_snackbar.dart
│
├───core
│   ├───log
│   │       logger.dart             # initLogging() + apiLogger
│   │
│   ├───models                      # freezed + json_serializable models
│   │       project.dart            #   @freezed Project
│   │       task.dart               #   @freezed Task (nullable-date aware)
│   │       task_step.dart          #   @freezed TaskStep (created/updated fallback)
│   │
│   ├───network
│   │       api.dart                # ApiService — business logic only
│   │       handler.dart            # ApiResult<T> + guard() (200/400/401/404/500)
│   │       interceptor.dart        # AuthInterceptor — connection/auth readiness
│   │
│   ├───router
│   │       app_router.dart         # GoRouter provider ($appRoutes)
│   │       routes.dart             # TypedGoRoute (type-safe navigation)
│   │
│   ├───state                       # Riverpod providers
│   │       app_providers.dart      #   alwaysOnTopProvider
│   │       network_providers.dart  #   apiServiceProvider / configServiceProvider
│   │
│   └───storage
│           preferences.dart        # ConfigService (SharedPreferences)
│
└───features                        # feature-first + MVVM
    ├───projects
    │       projects_page.dart      #   ConsumerWidget (UI only)
    │       projects_vm.dart        #   ProjectsNotifier (AsyncNotifier) + providers
    │       └───widgets
    │               create_project_dialog.dart
    │               edit_project_dialog.dart
    │               project_progress_indicator.dart
    │               setting_dialog.dart
    │
    ├───tasks
    │       tasks_page.dart         #   ConsumerWidget
    │       tasks_vm.dart           #   TasksNotifier (family: projectId)
    │       └───widgets
    │               chain_timeline.dart
    │               create_task_dialog.dart
    │               edit_task_dialog.dart
    │
    └───steps
            steps_page.dart         #   ConsumerWidget
            steps_vm.dart           #   StepsNotifier (family: taskId)
            └───widgets
                    create_step_dialog.dart
                    edit_step_dialog.dart
```

## Architecture

**Layering** (`core/` is depended-on, `features/` depends on it):

- `core/models` — immutable, freezed-generated data classes. Replace the old
  hand-written `models.dart` + `adaptor.dart`; `fromJson`/`toJson`/`copyWith`
  are generated, and mutations use `copyWith`.
- `core/network` — `handler.dart` wraps every call in an `ApiResult<T>`
  (classifying `ClientException` status codes into `ApiError`); `interceptor.dart`
  owns the PocketBase client and guarantees a connected/authenticated state via
  `ensureReady()`; `api.dart` holds only business logic and returns `ApiResult`s.
- `core/router` — `go_router` + `go_router_builder` for type-safe, declarative
  routing. Navigation passes ids (not whole objects); pages look up metadata via
  providers.
- `core/state` — Riverpod providers for cross-cutting dependencies (`apiService`,
  `configService`) and app-wide state (`alwaysOnTop`).

**Feature-first + MVVM** (`features/<name>/`):

- `*_vm.dart` — an `AsyncNotifier` exposing an `AsyncValue` of the view state
  plus CRUD methods. The single source of truth for that screen.
- `*_page.dart` — a `ConsumerWidget`/`ConsumerStatefulWidget` that subscribes to
  the VM via `ref.watch` and forwards user actions back to it. No API or
  business logic lives here.
- `widgets/` — the feature's dialogs and bespoke widgets.

**Code generation**: `dart run build_runner build` regenerates the freezed
models (`*.freezed.dart` / `*.g.dart`) and the typed routes (`routes.g.dart`).
