import 'package:flutter/material.dart';
import 'package:project_todo/core/storage/preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Global, app-wide state of the window's always-on-top flag. A single
/// [ValueNotifier] keeps every page's pin button in sync — toggling on one
/// page instantly updates the icon on any other visible page.
final alwaysOnTopNotifier = ValueNotifier<bool>(false);

/// A pin/always-on-top toggle button for the app bar. Reflects and controls
/// the global [alwaysOnTopNotifier], persisting the choice via
/// [ConfigService] so it survives restarts.
class PinWindowButton extends StatelessWidget {
  const PinWindowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: alwaysOnTopNotifier,
      builder: (context, isOnTop, _) {
        return IconButton(
          icon: Icon(isOnTop ? Icons.push_pin : Icons.push_pin_outlined),
          tooltip: isOnTop ? 'Unpin window' : 'Pin window on top',
          onPressed: () async {
            final value = !isOnTop;
            await windowManager.setAlwaysOnTop(value);
            await ConfigService().saveAlwaysOnTop(value);
            alwaysOnTopNotifier.value = value;
          },
        );
      },
    );
  }
}
