import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:yaru/yaru.dart';
import 'routes.dart';
import '../core/providers/theme_provider.dart';

class DbugApp extends ConsumerWidget {
  const DbugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightBase = ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        );
        final darkBase = ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        );

        final lightColorScheme = lightDynamic != null
            ? lightBase.copyWith(
                primary: lightDynamic.primary,
                onPrimary: lightDynamic.onPrimary,
                primaryContainer: lightDynamic.primaryContainer,
                onPrimaryContainer: lightDynamic.onPrimaryContainer,
              )
            : lightBase;
        final darkColorScheme = darkDynamic != null
            ? darkBase.copyWith(
                primary: darkDynamic.primary,
                onPrimary: darkDynamic.onPrimary,
                primaryContainer: darkDynamic.primaryContainer,
                onPrimaryContainer: darkDynamic.onPrimaryContainer,
              )
            : darkBase;

        return MaterialApp.router(
          title: 'dbug',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: createYaruTheme(colorScheme: lightColorScheme),
          darkTheme: createYaruTheme(colorScheme: darkColorScheme),
          routerConfig: appRouter,
        );
      },
    );
  }
}
