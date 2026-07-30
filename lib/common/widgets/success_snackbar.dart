import 'package:flutter/material.dart';

class SuccessSnackBar extends StatelessWidget {
  const SuccessSnackBar({super.key, required this.message});

  final String message;

  static void show(
    ScaffoldMessengerState messenger, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: SuccessSnackBar(message: message),
          behavior: SnackBarBehavior.floating,
          duration: duration,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    );
  }
}
