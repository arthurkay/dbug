import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;

enum ToastType { success, error, warning, info }

void showDbugToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
}) {
  final (icon, destructive) = switch (type) {
    ToastType.success => (LucideIcons.circleCheck, false),
    ToastType.error => (LucideIcons.circleX, true),
    ToastType.warning => (LucideIcons.triangleAlert, false),
    ToastType.info => (LucideIcons.circleAlert, false),
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
            icon: const Icon(LucideIcons.x, size: 14),
            onPressed: overlay.close,
          ),
        ),
      );
    },
    location: shad.ToastLocation.topRight,
    showDuration: const Duration(seconds: 4),
  );
}
