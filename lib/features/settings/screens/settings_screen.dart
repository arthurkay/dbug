import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/page_header.dart';
import '../../../core/security/secret_cipher.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/syntax_theme_provider.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/settings_provider.dart';
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
          const PageHeader(title: 'Settings', subtitle: 'Appearance, network, history and credential storage'),
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
                            style: codeTextStyle(color: Theme.of(context).colorScheme.onSurface),
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
                _buildNetworkCard(context),
                const SizedBox(height: 12),
                _buildHistoryCard(context),
                const SizedBox(height: 12),
                _buildSecurityCard(context),
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
                          error: (_, _) => const SizedBox.shrink(),
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

  Widget _settingsCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  /// A labelled dropdown over [options]; the current value is always listed,
  /// even if it isn't one of the presets.
  Widget _choiceRow<T>(
    BuildContext context, {
    required String label,
    String? subtitle,
    required T value,
    required List<T> options,
    required String Function(T) format,
    required ValueChanged<T> onChanged,
  }) {
    final all = {...options, value}.toList();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall) : null,
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: all.map((o) => DropdownMenuItem(value: o, child: Text(format(o), style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildNetworkCard(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    return _settingsCard(context, 'Network', [
      _choiceRow<int>(
        context,
        label: 'Request timeout',
        value: settings.timeoutSeconds,
        options: const [10, 30, 60, 120, 300],
        format: (s) => s < 60 ? '$s s' : '${s ~/ 60} min',
        onChanged: (v) => notifier.update(settings.copyWith(timeoutSeconds: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Allow self-signed certificates', style: TextStyle(fontSize: 13)),
        subtitle: Text(
          settings.allowInsecureTls
              ? 'Certificate checks are OFF — any server can impersonate the API you call. Only use this for local or internal hosts.'
              : 'Accept untrusted TLS certificates (for local or internal APIs).',
          style: TextStyle(
            fontSize: 12,
            color: settings.allowInsecureTls ? colorScheme.error : colorScheme.onSurfaceVariant,
          ),
        ),
        value: settings.allowInsecureTls,
        onChanged: (v) => notifier.update(settings.copyWith(allowInsecureTls: v)),
      ),
    ]);
  }

  Widget _buildSecurityCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (IconData icon, String title, String detail, Color color) = switch (Secrets.storage) {
      SecretStorage.keychain => (
          LucideIcons.shieldCheck,
          'Encrypted, key in the system keychain',
          'Auth, headers, environment variables and history credentials are encrypted with AES-256-GCM.',
          colorScheme.primary,
        ),
      SecretStorage.keyFile => (
          LucideIcons.shieldAlert,
          'Encrypted, key stored in a file',
          'No system keychain was available, so the key is in a private file next to the database. Anyone who can read your files can read your credentials.',
          Colors.orange,
        ),
      SecretStorage.locked => (
          LucideIcons.shieldOff,
          'Locked: encryption key unavailable',
          "Saved credentials can't be read. Unlock your system keyring and restart dbug; credentials you edit meanwhile are not saved.",
          colorScheme.error,
        ),
    };
    return _settingsCard(context, 'Credential storage', [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        subtitle: Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ),
    ]);
  }

  Widget _buildHistoryCard(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return _settingsCard(context, 'History', [
      _choiceRow<int>(
        context,
        label: 'Entries to keep',
        subtitle: 'Older entries are removed when new requests are sent.',
        value: settings.historyMaxEntries,
        options: const [100, 250, 500, 1000, 5000],
        format: (n) => '$n',
        onChanged: (v) => notifier.update(settings.copyWith(historyMaxEntries: v)),
      ),
      _choiceRow<int>(
        context,
        label: 'Response body size limit',
        subtitle: 'Larger response bodies are truncated when saved to history.',
        value: settings.historyMaxBodyKb,
        options: const [256, 1024, 5120, 10240],
        format: (kb) => kb < 1024 ? '$kb KB' : '${kb ~/ 1024} MB',
        onChanged: (v) => notifier.update(settings.copyWith(historyMaxBodyKb: v)),
      ),
    ]);
  }
}
