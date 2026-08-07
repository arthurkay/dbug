import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);
    final envsAsync = ref.watch(userEnvironmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('Theme', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(LucideIcons.monitor, size: 16),
                              label: Text('System'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(LucideIcons.sun, size: 16),
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(LucideIcons.moon, size: 16),
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (modes) {
                            ref.read(themeModeProvider.notifier).setMode(modes.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Active Environment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Variables from the active environment are available as {{var}} in requests', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        envsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (envs) {
                            if (envs.isEmpty) {
                              return Text('No environments created yet', style: Theme.of(context).textTheme.bodySmall);
                            }
                            return Column(
                              children: envs.map((env) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: activeEnv?.id == env.id,
                                      onChanged: (v) {
                                        if (v == true) {
                                          ref.read(activeEnvironmentProvider.notifier).setActive(env);
                                        } else {
                                          ref.read(activeEnvironmentProvider.notifier).setActive(null);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(env.name, style: const TextStyle(fontSize: 13))),
                                    Text('${env.variables.length} vars', style: Theme.of(context).textTheme.bodySmall),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('dbug v${AppConstants.appVersion}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text('A local API testing tool built with Flutter', style: Theme.of(context).textTheme.bodySmall),
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
