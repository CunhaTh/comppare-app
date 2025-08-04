// lib/ui/molecules/snackbar_widget.dart
import 'package:flutter/material.dart';
import '../../../../../main.dart';

class AppSnackbar {
  static final AppSnackbar _instance = AppSnackbar._internal();
  factory AppSnackbar() => _instance;
  AppSnackbar._internal();

  OverlayEntry? _currentOverlay;

  void _showOverlay({
    required String message,
    required Color color,
    required IconData icon,
    bool top = true,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _currentOverlay?.remove(); // remove overlay anterior
    _currentOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: top ? 50 : null,
        bottom: top ? null : 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: () {
                      onAction();
                      _removeOverlay();
                    },
                    child: Text(
                      actionLabel,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    navigatorKey.currentState!.overlay!.insert(_currentOverlay!);

    Future.delayed(duration, _removeOverlay);
  }

  void _removeOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  void success(
    String message, {
    bool top = true,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showOverlay(
      message: message,
      color: Colors.green,
      icon: Icons.check_circle,
      top: top,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void error(
    String message, {
    bool top = true,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showOverlay(
      message: message,
      color: Colors.red,
      icon: Icons.error,
      top: top,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void info(
    String message, {
    bool top = true,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showOverlay(
      message: message,
      color: Colors.blueGrey,
      icon: Icons.info,
      top: top,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
