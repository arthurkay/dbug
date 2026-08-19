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
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF18181B),
          onPrimary: surfaceLight,
          primaryContainer: surface2Light,
          onPrimaryContainer: textLight,
          secondary: const Color(0xFF71717A),
          onSecondary: surfaceLight,
          secondaryContainer: surfaceHoverLight,
          onSecondaryContainer: textLight,
          tertiary: const Color(0xFFA1A1AA),
          onTertiary: surfaceLight,
          tertiaryContainer: surface2Light,
          onTertiaryContainer: textLight,
          error: const Color(0xFFDC2626),
          onError: surfaceLight,
          errorContainer: const Color(0xFFFEE2E2),
          onErrorContainer: const Color(0xFF991B1B),
          surface: surfaceLight,
          onSurface: textLight,
          onSurfaceVariant: textSecondaryLight,
          outline: const Color(0xFFE4E4E7),
          outlineVariant: surface2Light,
          surfaceDim: surfaceLight,
          surfaceBright: const Color(0xFFF8F8FA),
          surfaceContainerLowest: surfaceLight,
          surfaceContainerLow: const Color(0xFFF8F8FA),
          surfaceContainer: surfaceHoverLight,
          surfaceContainerHigh: surface2Light,
          surfaceContainerHighest: const Color(0xFFD4D4D8),
        ),
      ).copyWith(
        scaffoldBackgroundColor: bgLight,
      ).withoutInputFocusBorder();

  static ThemeData get dark => createYaruTheme(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFFD4D4D8),
          onPrimary: bgDark,
          primaryContainer: surface2Dark,
          onPrimaryContainer: textDark,
          secondary: const Color(0xFFA1A1AA),
          onSecondary: bgDark,
          secondaryContainer: surfaceDark,
          onSecondaryContainer: textDark,
          tertiary: const Color(0xFF71717A),
          onTertiary: bgDark,
          tertiaryContainer: surface2Dark,
          onTertiaryContainer: textDark,
          error: const Color(0xFFEF4444),
          onError: bgDark,
          errorContainer: const Color(0xFF7F1D1D),
          onErrorContainer: const Color(0xFFFCA5A5),
          surface: surfaceDark,
          onSurface: textDark,
          onSurfaceVariant: textSecondaryDark,
          outline: const Color(0xFF27272A),
          outlineVariant: surface2Dark,
          surfaceDim: bgDark,
          surfaceBright: surface2Dark,
          surfaceContainerLowest: bgDark,
          surfaceContainerLow: const Color(0xFF111113),
          surfaceContainer: surfaceDark,
          surfaceContainerHigh: surface2Dark,
          surfaceContainerHighest: const Color(0xFF2E2E32),
        ),
      ).copyWith(
        scaffoldBackgroundColor: bgDark,
      ).withoutInputFocusBorder();
}

extension on ThemeData {
  /// dbug default: no focus ring on text inputs — a focused field keeps the
  /// exact same border it has when enabled but unfocused.
  ThemeData withoutInputFocusBorder() {
    return copyWith(
      inputDecorationTheme: inputDecorationTheme.copyWith(
        focusedBorder: inputDecorationTheme.enabledBorder,
        focusedErrorBorder: inputDecorationTheme.errorBorder,
      ),
    );
  }
}
