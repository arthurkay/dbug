import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'theme/shadcn_theme.dart';
import 'routes.dart';

class DbugApp extends StatelessWidget {
  const DbugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return shad.ShadcnApp.router(
      title: 'dbug',
      themeMode: shad.ThemeMode.system,
      darkTheme: DbugTheme.dark,
      theme: DbugTheme.light,
      routerConfig: appRouter,
    );
  }
}
