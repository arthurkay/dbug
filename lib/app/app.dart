import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import '../core/providers/theme_provider.dart';
import 'theme/app_theme.dart';

class DbugApp extends ConsumerWidget {
  const DbugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'dbug',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: DbugTheme.light,
      darkTheme: DbugTheme.dark,
      routerConfig: appRouter,
    );
  }
}
