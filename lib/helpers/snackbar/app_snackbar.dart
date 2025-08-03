import 'package:flutter/material.dart';

import '../app_screen_size.dart';

void appSnackBar({
  required BuildContext context,
  required String message,
  Color backgroundColor = Colors.white,
  IconData icon = Icons.info_outline,
  Duration duration = const Duration(seconds: 3),
}) {
  final scaffoldMessenger = ScaffoldMessenger.of(
    context,
  );

  scaffoldMessenger.hideCurrentSnackBar();

  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    backgroundColor: backgroundColor,
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      bottom: AppScreenSize.height - 200,
      left: 10,
      right: 10,
    ),
    duration: duration,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(
        color: Colors.green,
      ),
    ),
  );

  scaffoldMessenger.showSnackBar(snackBar);
}
