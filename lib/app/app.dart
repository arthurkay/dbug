import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'theme/shadcn_theme.dart';
import 'routes.dart';
import '../core/providers/theme_provider.dart';

class DbugApp extends ConsumerWidget {
  const DbugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return shad.ShadcnApp.router(
      title: 'dbug',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      darkTheme: DbugTheme.dark,
      theme: DbugTheme.light,
      routerConfig: appRouter,
    );
  }
}
