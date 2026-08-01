import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/core/state/app_providers.dart';

/// A pin/always-on-top toggle button for the app bar.
///
/// Subscribes to [alwaysOnTopProvider] — the single source of truth for the
/// window's always-on-top flag — so toggling on any page instantly updates the
/// icon everywhere. The choice is persisted by the notifier, so it survives
/// restarts.
///
/// Renders nothing on platforms that don't support always-on-top (Android,
/// web), where the underlying `window_manager` plugin isn't available.
class PinWindowButton extends ConsumerWidget {
  const PinWindowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide entirely where the feature is unsupported; the pages embed this
    // unconditionally so returning an empty widget keeps their AppBar code
    // unchanged.
    if (!windowPin.supportsAlwaysOnTop) return const SizedBox.shrink();
    final isOnTop = ref.watch(alwaysOnTopProvider);
    return IconButton(
      icon: Icon(isOnTop ? Icons.push_pin : Icons.push_pin_outlined),
      tooltip: isOnTop ? 'Unpin window' : 'Pin window on top',
      onPressed: () => ref.read(alwaysOnTopProvider.notifier).toggle(),
    );
  }
}
