import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/syntax_theme_provider.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/syntax_highlighter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(windowTitleProvider.notifier).state = 'Settings';
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        Text('Response Viewer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('Syntax Theme', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: ref.watch(syntaxThemeNameProvider),
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: syntaxThemeNames.map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) ref.read(syntaxThemeNameProvider.notifier).setTheme(v);
                          },
                        ),
                        const SizedBox(height: 12),
                        Text('Preview', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Text.rich(TextSpan(
                            children: SyntaxHighlighter.highlight(
                              '{\n  "name": "dbug",\n  "version": 1,\n  "active": true,\n  "tags": null\n}',
                              'application/json',
                              Theme.of(context).brightness,
                              themeName: ref.watch(syntaxThemeNameProvider),
                            ),
                          )),
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
