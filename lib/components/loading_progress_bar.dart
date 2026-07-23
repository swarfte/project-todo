import 'package:flutter/material.dart';

class LoadingProgressBar extends StatelessWidget {
  const LoadingProgressBar({
    super.key,
    this.message = 'Waiting for the server response...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}
