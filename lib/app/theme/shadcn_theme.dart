import 'package:shadcn_flutter/shadcn_flutter.dart';

class DbugTheme {
  DbugTheme._();

  static ThemeData get light => const ThemeData(
        colorScheme: ColorSchemes.lightSlate,
      );

  static ThemeData get dark => ThemeData.dark(
        colorScheme: ColorSchemes.darkSlate,
      );

  static final Map<String, Color> methodColors = {
    'GET': const Color(0xFF22C55E),
    'POST': const Color(0xFF3B82F6),
    'PUT': const Color(0xFFF59E0B),
    'PATCH': const Color(0xFFF97316),
    'DELETE': const Color(0xFFEF4444),
    'HEAD': const Color(0xFF8B5CF6),
    'OPTIONS': const Color(0xFF6B7280),
  };

  static Color getMethodColor(String method) {
    return methodColors[method.toUpperCase()] ?? const Color(0xFF6B7280);
  }
}
