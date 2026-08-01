import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/core/state/app_providers.dart';

/// A pin/always-on-top toggle button for the app bar.
///
/// Subscribes to [alwaysOnTopProvider] — the single source of truth for the
/// window's always-on-top flag — so toggling on any page instantly updates the
/// icon everywhere. The choice is persisted by the notifier, so it survives
/// restarts.
class PinWindowButton extends ConsumerWidget {
  const PinWindowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnTop = ref.watch(alwaysOnTopProvider);
    return IconButton(
      icon: Icon(isOnTop ? Icons.push_pin : Icons.push_pin_outlined),
      tooltip: isOnTop ? 'Unpin window' : 'Pin window on top',
      onPressed: () => ref.read(alwaysOnTopProvider.notifier).toggle(),
    );
  }
}
