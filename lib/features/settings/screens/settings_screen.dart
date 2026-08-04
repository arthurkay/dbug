import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/repository_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envsAsync = ref.watch(userEnvironmentsProvider);

    final isDark = themeMode == shad.ThemeMode.dark ||
        (themeMode == shad.ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.foreground)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                shad.Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dark Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.foreground)),
                                  Text('Use dark theme', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
                                ],
                              ),
                            ),
                            shad.Switch(
                              value: isDark,
                              onChanged: (v) {
                                ref.read(themeModeProvider.notifier).setMode(
                                    v ? shad.ThemeMode.dark : shad.ThemeMode.light);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                shad.Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Active Environment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
                        const SizedBox(height: 4),
                        Text('Variables from the active environment are available as {{var}} in requests', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
                        const SizedBox(height: 12),
                        envsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (envs) {
                            if (envs.isEmpty) {
                              return Text('No environments created yet', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground));
                            }
                            return Column(
                              children: envs.map((env) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    shad.Checkbox(
                                      state: activeEnv?.id == env.id ? shad.CheckboxState.checked : shad.CheckboxState.unchecked,
                                      onChanged: (v) {
                                        if (v == shad.CheckboxState.checked) {
                                          ref.read(activeEnvironmentProvider.notifier).setActive(env);
                                        } else {
                                          ref.read(activeEnvironmentProvider.notifier).setActive(null);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(env.name, style: const TextStyle(fontSize: 13))),
                                    Text('${env.variables.length} vars', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
                                  ],
                                ),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                shad.Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
                        const SizedBox(height: 12),
                        Text('dbug v1.0.0', style: TextStyle(fontSize: 13, color: colorScheme.foreground)),
                        const SizedBox(height: 4),
                        Text('A local API testing tool built with Flutter', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
