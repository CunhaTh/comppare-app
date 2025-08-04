// lib/ui/atoms/snackbar_container.dart
import 'package:flutter/material.dart';

class SnackbarContainer extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData? icon;

  const SnackbarContainer({
    super.key,
    required this.message,
    required this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
