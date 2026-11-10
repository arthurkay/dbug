import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/widgets/page_header.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/models/environment_model.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/dbug_spinner.dart';

/// Asks the open environment editor whether it may be left (prompting about
/// unsaved changes); used by the `/environments/:envId` route's `onExit`, so
/// leaving through the sidebar is guarded as well as the Back button.
Future<bool> Function()? environmentEditorExitGuard;

class EnvironmentsScreen extends ConsumerStatefulWidget {
  /// The environment being edited (from `/environments/:envId`); null shows
  /// the list.
  final String? editingEnvId;

  const EnvironmentsScreen({super.key, this.editingEnvId});

  @override
  ConsumerState<EnvironmentsScreen> createState() => _EnvironmentsScreenState();
}

class _EnvironmentsScreenState extends ConsumerState<EnvironmentsScreen> {
  String? get _editingEnvId => widget.editingEnvId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(windowTitleProvider.notifier).state = 'Environments';
    });
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
              Expanded(child: PageHeader(title: 'Environments', subtitle: 'Manage variables for different environments')),
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
                  if (editingEnv != null) {
                    return _EnvironmentEditor(
                      key: ValueKey(editingEnv.id),
                      env: editingEnv,
                      onClose: () => context.go('/environments'),
                    );
                  }
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
                        onEdit: () => context.go('/environments/${env.id}'),
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
                          // The active environment is derived from
                          // environmentsProvider, so refreshing it is enough.
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
            Text('Create environments like dev, staging, prod', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Environment'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Environment name (e.g. dev, staging)'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    // Disposed only after the dialog (and its exit animation) is gone.
    nameController.dispose();
    if (name == null || name.isEmpty) return;

    await ref.read(environmentRepositoryProvider).createEnvironment(name: name);
    ref.invalidate(environmentsProvider);
  }
}

/// Edits one environment's variables. Owns its entries so edits survive
/// rebuilds of the parent (provider refreshes, switching the active
/// environment from the sidebar) until saved or discarded.
class _EnvironmentEditor extends ConsumerStatefulWidget {
  final Environment env;
  final VoidCallback onClose;

  const _EnvironmentEditor({super.key, required this.env, required this.onClose});

  @override
  ConsumerState<_EnvironmentEditor> createState() => _EnvironmentEditorState();
}

class _EnvironmentEditorState extends ConsumerState<_EnvironmentEditor> {
  late final List<KeyValueEntry> _entries;
  late Map<String, String> _saved;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _saved = Map.of(widget.env.variables);
    _entries = mapToEntries(_saved);
    if (_entries.isEmpty) _entries.add(KeyValueEntry());
    environmentEditorExitGuard = _confirmLeave;
  }

  @override
  void dispose() {
    if (environmentEditorExitGuard == _confirmLeave) environmentEditorExitGuard = null;
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  bool get _isDirty => !_mapEquals(entriesToMap(_entries), _saved);

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final vars = entriesToMap(_entries);
    try {
      await ref.read(environmentRepositoryProvider).updateEnvironment(widget.env.copyWith(variables: vars));
      ref.invalidate(environmentsProvider);
      if (!mounted) return;
      setState(() => _saved = vars);
      showDbugToast(context, message: 'Environment saved', type: ToastType.success);
    } catch (e) {
      if (mounted) showDbugToast(context, message: 'Failed to save: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// True when the editor may be left: nothing unsaved, or the user agreed
  /// to discard it.
  Future<bool> _confirmLeave() async {
    if (!_isDirty || !mounted) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: Text('"${widget.env.name}" has unsaved variable changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    return discard == true;
  }

  // The route's onExit runs _confirmLeave.
  void _close() => widget.onClose();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dirty = _isDirty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.env.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (dirty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.circleDot, size: 12, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text('Unsaved changes', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                TextButton(onPressed: _close, child: const Text('Back')),
              ],
            ),
            const SizedBox(height: 4),
            Text('${entriesToMap(_entries).length} variables', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: KeyValueEditor(
                  entries: _entries,
                  keyHint: 'Variable name',
                  valueHint: 'Value',
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: dirty && !_saving ? _save : null,
              child: Text(_saving ? 'Saving…' : 'Save Variables'),
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
      onTap: onEdit,
      mouseCursor: SystemMouseCursors.click,
      // Every state uses the same IconButton footprint so names line up.
      leading: IconButton(
        tooltip: isActive ? 'Active environment' : (canActivate ? 'Make active' : null),
        icon: Icon(
          isActive ? LucideIcons.circleCheck : (canActivate ? LucideIcons.circle : LucideIcons.link),
          size: 16,
          color: isActive ? colorScheme.primary : colorScheme.outline,
        ),
        onPressed: !isActive && canActivate ? onActivate : null,
        visualDensity: VisualDensity.compact,
      ),
      title: Row(
        children: [
          Text(env.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          if (env.isOpenApiDefined) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('From spec', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
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
