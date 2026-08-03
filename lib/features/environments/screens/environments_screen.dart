import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/models/environment_model.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/toast_helper.dart';

class EnvironmentsScreen extends ConsumerStatefulWidget {
  const EnvironmentsScreen({super.key});

  @override
  ConsumerState<EnvironmentsScreen> createState() => _EnvironmentsScreenState();
}

class _EnvironmentsScreenState extends ConsumerState<EnvironmentsScreen> {
  String? _editingEnvId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;
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
                    Text('Environments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.foreground)),
                    const SizedBox(height: 4),
                    Text('Manage variables for different environments', style: TextStyle(fontSize: 13, color: colorScheme.mutedForeground)),
                  ],
                ),
              ),
              if (activeEnv != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Active: ${activeEnv.name}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                  ),
                ),
              shad.Button.primary(
                onPressed: () => _showCreateDialog(context),
                leading: const Icon(Icons.add, size: 16),
                child: const Text('New Environment'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: envsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (envs) {
                if (envs.isEmpty) return _buildEmptyState(colorScheme);
                if (_editingEnvId != null) {
                  final editingEnv = envs.where((e) => e.id == _editingEnvId).firstOrNull;
                  if (editingEnv != null) return _buildEditor(colorScheme, editingEnv);
                }
                return shad.Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: envs.length,
                    itemBuilder: (context, index) {
                      final env = envs[index];
                      return _EnvironmentTile(
                        env: env,
                        isActive: activeEnv?.id == env.id,
                        onActivate: () {
                          ref.read(activeEnvironmentProvider.notifier).state = env;
                          ref.read(environmentRepositoryProvider).setActive(env.id);
                        },
                        onEdit: () => setState(() => _editingEnvId = env.id),
                        onDelete: () async {
                          if (activeEnv?.id == env.id) {
                            ref.read(activeEnvironmentProvider.notifier).state = null;
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

  Widget _buildEditor(shad.ColorScheme colorScheme, Environment env) {
    final entries = mapToEntries(env.variables);
    if (entries.isEmpty) entries.add(KeyValueEntry());

    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(env.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
                ),
                shad.Button.ghost(
                  onPressed: () => setState(() => _editingEnvId = null),
                  child: const Text('Back'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${env.variables.length} variables', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
            const Divider(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: KeyValueEditor(entries: entries, keyHint: 'Variable name', valueHint: 'Value'),
              ),
            ),
            const SizedBox(height: 12),
            shad.Button.primary(
              onPressed: () async {
                final vars = entriesToMap(entries);
                final updated = env.copyWith(variables: vars);
                await ref.read(environmentRepositoryProvider).updateEnvironment(updated);
                ref.invalidate(environmentsProvider);
                if (ref.read(activeEnvironmentProvider)?.id == env.id) {
                  ref.read(activeEnvironmentProvider.notifier).state = updated.copyWith(isActive: true);
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

  Widget _buildEmptyState(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code, size: 48, color: colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text('No environments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const SizedBox(height: 8),
            Text('Create environments like dev, staging, prod', style: TextStyle(color: colorScheme.mutedForeground)),
            const SizedBox(height: 16),
            shad.Button.primary(
              onPressed: () => _showCreateDialog(context),
              leading: const Icon(Icons.add, size: 16),
              child: const Text('New Environment'),
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
      builder: (context) => shad.AlertDialog(
        title: const Text('New Environment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            shad.TextField(controller: nameController, placeholder: const Text('Environment name (e.g. dev, staging)')),
          ],
        ),
        actions: [
          shad.Button.ghost(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          shad.Button.primary(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(environmentRepositoryProvider).createEnvironment(name: nameController.text);
                ref.invalidate(environmentsProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentTile extends StatelessWidget {
  final Environment env;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EnvironmentTile({
    required this.env,
    required this.isActive,
    required this.onActivate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          if (isActive)
            Icon(Icons.check_circle, size: 16, color: colorScheme.primary)
          else
            shad.IconButton.ghost(
              icon: Icon(Icons.circle_outlined, size: 16, color: colorScheme.mutedForeground),
              onPressed: onActivate,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(env.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.foreground)),
                Text('${env.variables.length} variables', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
              ],
            ),
          ),
          shad.Button.ghost(onPressed: onEdit, child: const Text('Edit', style: TextStyle(fontSize: 12))),
          shad.IconButton.ghost(icon: const Icon(Icons.delete_outline, size: 14), onPressed: onDelete),
        ],
      ),
    );
  }
}
