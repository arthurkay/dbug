import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

class DbugTheme {
  DbugTheme._();

  // cal.com-inspired color palette
  static const Color bgDark = Color(0xFF09090B);
  static const Color surfaceDark = Color(0xFF18181B);
  static const Color surfaceHoverDark = Color(0xFF1F1F23);
  static const Color surface2Dark = Color(0xFF27272A);
  static const Color textDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);
  static const Color textTertiaryDark = Color(0xFF71717A);

  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceHoverLight = Color(0xFFF4F4F5);
  static const Color surface2Light = Color(0xFFE4E4E7);
  static const Color textLight = Color(0xFF09090B);
  static const Color textSecondaryLight = Color(0xFF71717A);
  static const Color textTertiaryLight = Color(0xFFA1A1AA);

  static ThemeData get light => createYaruTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        ).copyWith(
          surface: surfaceLight,
          onSurface: textLight,
          outline: const Color(0xFFE4E4E7),
        ),
      ).copyWith(
        scaffoldBackgroundColor: bgLight,
      );

  static ThemeData get dark => createYaruTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ).copyWith(
          surface: surfaceDark,
          onSurface: textDark,
          outline: const Color(0xFF27272A),
        ),
      ).copyWith(
        scaffoldBackgroundColor: bgDark,
      );
}
