import 'package:shadcn_flutter/shadcn_flutter.dart';

class DbugTheme {
  DbugTheme._();

  static ThemeData get light => const ThemeData(
        colorScheme: ColorSchemes.lightSlate,
      );

  static ThemeData get dark => ThemeData.dark(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          background: Color(0xFF09090B),
          foreground: Color(0xFFFAFAFA),
          card: Color(0xFF09090B),
          cardForeground: Color(0xFFFAFAFA),
          popover: Color(0xFF09090B),
          popoverForeground: Color(0xFFFAFAFA),
          primary: Color(0xFFFAFAFA),
          primaryForeground: Color(0xFF18181B),
          secondary: Color(0xFF27272A),
          secondaryForeground: Color(0xFFFAFAFA),
          muted: Color(0xFF27272A),
          mutedForeground: Color(0xFFA1A1AA),
          accent: Color(0xFF27272A),
          accentForeground: Color(0xFFFAFAFA),
          destructive: Color(0xFF7F1D1D),
          destructiveForeground: Color(0xFFFAFAFA),
          border: Color(0xFF27272A),
          input: Color(0xFF27272A),
          ring: Color(0xFFD4D4D8),
          chart1: Color(0xFF4ADE80),
          chart2: Color(0xFF60A5FA),
          chart3: Color(0xFFFBBF24),
          chart4: Color(0xFFF87171),
          chart5: Color(0xFFA78BFA),
        ),
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
