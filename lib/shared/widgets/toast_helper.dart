import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ToastType { success, error, warning, info }

void showDbugToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
}) {
  final (icon, color) = switch (type) {
    ToastType.success => (LucideIcons.circleCheck, Colors.green),
    ToastType.error => (LucideIcons.circleX, Colors.red),
    ToastType.warning => (LucideIcons.triangleAlert, Colors.orange),
    ToastType.info => (LucideIcons.circleAlert, Colors.blue),
  };

  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 4),
    margin: const EdgeInsets.all(16),
  );

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(snackBar);
}
