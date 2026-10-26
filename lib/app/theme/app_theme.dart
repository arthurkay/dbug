import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

class DbugTheme {
  DbugTheme._();

  // cal.com-inspired monochrome palette (zinc scale).
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

  static const double radius = 10;

  static ThemeData get light => _build(
        ColorScheme(
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
          onSurfaceVariant: const Color(0xFF52525B),
          // outline is used for secondary icons and labels, so it needs real
          // contrast; outlineVariant is the hairline border colour.
          outline: textTertiaryLight,
          outlineVariant: surface2Light,
          surfaceDim: const Color(0xFFF4F4F5),
          surfaceBright: surfaceLight,
          surfaceContainerLowest: surfaceLight,
          surfaceContainerLow: const Color(0xFFFAFAFA),
          surfaceContainer: const Color(0xFFF4F4F5),
          surfaceContainerHigh: const Color(0xFFF1F1F3),
          surfaceContainerHighest: const Color(0xFFEDEDF0),
        ),
        scaffold: bgLight,
      );

  static ThemeData get dark => _build(
        ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFFFAFAFA),
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
          surface: const Color(0xFF111113),
          onSurface: textDark,
          onSurfaceVariant: textSecondaryDark,
          outline: textTertiaryDark,
          outlineVariant: surface2Dark,
          surfaceDim: bgDark,
          surfaceBright: surface2Dark,
          surfaceContainerLowest: bgDark,
          surfaceContainerLow: const Color(0xFF111113),
          surfaceContainer: surfaceDark,
          surfaceContainerHigh: surfaceHoverDark,
          surfaceContainerHighest: const Color(0xFF232327),
        ),
        scaffold: bgDark,
      );

  static ThemeData _build(ColorScheme scheme, {required Color scaffold}) {
    final base = createYaruTheme(colorScheme: scheme);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final hairline = BorderSide(color: scheme.outlineVariant);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: hairline,
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    const buttonText = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      // Content sits on bordered, flat cards rather than filled grey panels.
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: hairline,
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.outline,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surface,
          side: hairline,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.outline, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: inputBorder,
        enabledBorder: inputBorder,
        // dbug default: no focus ring on text inputs — a focused field keeps
        // the same border it has when enabled.
        focusedBorder: inputBorder,
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outlineVariant,
        overlayColor: WidgetStatePropertyAll(scheme.onSurface.withValues(alpha: 0.04)),
      ),
      listTileTheme: base.listTileTheme.copyWith(shape: shape),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: hairline,
        ),
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: hairline),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
