// The logger's whole purpose is to write to the console, so `print` is
// legitimate here and the `avoid_print` lint is intentionally disabled for
// this file. The rest of the codebase logs through [apiLogger] instead.
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Sets up the global `package:logging` hierarchy.
///
/// Call [initLogging] once at startup (e.g. from `main`). It attaches a
/// listener to `Logger.root` that forwards every record at the configured
/// level to the console. This keeps the rest of the codebase free of `print`
/// calls (which trip the `avoid_print` lint) while still surfacing errors.
///
/// The level is driven by [kDebugMode]: everything in debug builds, only
/// warnings and above in release/profile builds. Individual files obtain a
/// logger via `Logger('project_todo.<area>')` — any name works, they all
/// funnel through this listener.
void initLogging() {
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}'
        '${record.error != null ? ' :: ${record.error}' : ''}'
        '${record.stackTrace != null ? '\n${record.stackTrace}' : ''}');
  });

  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
}

/// Convenience entry point for the API service's logger.
final Logger apiLogger = Logger('project_todo.api');
