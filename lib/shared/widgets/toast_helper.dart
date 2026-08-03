import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

enum ToastType { success, error, warning, info }

void showDbugToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
}) {
  final (icon, destructive) = switch (type) {
    ToastType.success => (Icons.check_circle_outline, false),
    ToastType.error => (Icons.error_outline, true),
    ToastType.warning => (Icons.warning_amber_outlined, false),
    ToastType.info => (Icons.info_outline, false),
  };

  shad.showToast(
    context: context,
    builder: (context, overlay) {
      return GestureDetector(
        onTap: overlay.close,
        child: shad.Alert(
          leading: Icon(icon, size: 16),
          destructive: destructive,
          title: Text(message, style: const TextStyle(fontSize: 13)),
          trailing: shad.IconButton.ghost(
            icon: const Icon(Icons.close, size: 14),
            onPressed: overlay.close,
          ),
        ),
      );
    },
    location: shad.ToastLocation.topRight,
    showDuration: const Duration(seconds: 4),
  );
}
