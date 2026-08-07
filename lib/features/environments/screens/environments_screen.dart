import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/models/environment_model.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/dbug_spinner.dart';

class EnvironmentsScreen extends ConsumerStatefulWidget {
  const EnvironmentsScreen({super.key});

  @override
  ConsumerState<EnvironmentsScreen> createState() => _EnvironmentsScreenState();
}

class _EnvironmentsScreenState extends ConsumerState<EnvironmentsScreen> {
  String? _editingEnvId;

  @override
  void initState() {
    super.initState();
    ref.read(windowTitleProvider.notifier).state = 'Environments';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final envsAsync = ref.watch(environmentsProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Environments', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Manage variables for different environments', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (activeEnv != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Active: ${activeEnv.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  ),
                ),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('New Environment'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: envsAsync.when(
              loading: () => const Center(child: DbugSpinner()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (envs) {
                if (envs.isEmpty) return _buildEmptyState(colorScheme);
                if (_editingEnvId != null) {
                  final editingEnv = envs.where((e) => e.id == _editingEnvId).firstOrNull;
                  if (editingEnv != null) return _buildEditor(colorScheme, editingEnv);
                }
                return Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: envs.length,
                    itemBuilder: (context, index) {
                      final env = envs[index];
                      return _EnvironmentTile(
                        env: env,
                        isActive: activeEnv?.id == env.id,
                        canActivate: true,
                        onActivate: () {
                          ref.read(activeEnvironmentProvider.notifier).setActive(env);
                        },
                        onEdit: () => setState(() => _editingEnvId = env.id),
                        onDelete: env.isOpenApiDefined ? null : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Environment'),
                              content: Text('Delete "${env.name}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          if (activeEnv?.id == env.id) {
                            ref.read(activeEnvironmentProvider.notifier).setActive(null);
                          }
                          await ref.read(environmentRepositoryProvider).deleteEnvironment(env.id);
                          ref.invalidate(environmentsProvider);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(ColorScheme colorScheme, Environment env) {
    final entries = mapToEntries(env.variables);
    if (entries.isEmpty) entries.add(KeyValueEntry());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(env.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () => setState(() => _editingEnvId = null),
                  child: const Text('Back'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${env.variables.length} variables', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: KeyValueEditor(entries: entries, keyHint: 'Variable name', valueHint: 'Value'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final vars = entriesToMap(entries);
                final updated = env.copyWith(variables: vars);
                await ref.read(environmentRepositoryProvider).updateEnvironment(updated);
                ref.invalidate(environmentsProvider);
                if (ref.read(activeEnvironmentProvider)?.id == env.id) {
                  ref.read(activeEnvironmentProvider.notifier).setActive(updated.copyWith(isActive: true));
                }
                setState(() => _editingEnvId = null);
                if (mounted) {
                  showDbugToast(context, message: 'Environment saved', type: ToastType.success);
                }
              },
              child: const Text('Save Variables'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.code, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No environments yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Create environments like dev, staging, prod', style: TextStyle(color: colorScheme.outline)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('New Environment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Environment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Environment name (e.g. dev, staging)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () { nameController.dispose(); Navigator.pop(context); }, child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await ref.read(environmentRepositoryProvider).createEnvironment(name: nameController.text);
                  ref.invalidate(environmentsProvider);
                  ref.invalidate(userEnvironmentsProvider);
                  nameController.dispose();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvironmentTile extends StatelessWidget {
  final Environment env;
  final bool isActive;
  final bool canActivate;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _EnvironmentTile({
    required this.env,
    required this.isActive,
    required this.canActivate,
    required this.onActivate,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: isActive
          ? Icon(LucideIcons.circleCheck, size: 16, color: colorScheme.primary)
          : canActivate
              ? IconButton(
                  icon: Icon(LucideIcons.circle, size: 16, color: colorScheme.outline),
                  onPressed: onActivate,
                  visualDensity: VisualDensity.compact,
                )
              : Icon(LucideIcons.link, size: 16, color: colorScheme.outline),
      title: Row(
        children: [
          Text(env.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          if (env.isOpenApiDefined) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text('Collection', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blue)),
            ),
          ],
        ],
      ),
      subtitle: Text('${env.variables.length} variables', style: Theme.of(context).textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit', style: TextStyle(fontSize: 12)),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 14),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
