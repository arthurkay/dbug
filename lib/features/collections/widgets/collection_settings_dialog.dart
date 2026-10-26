import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/auth_config.dart';
import '../../../core/models/collection_model.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../shared/widgets/auth_editor.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/toast_helper.dart';

/// Edits a collection's global headers and auth. Shared between the
/// collections screen and the request builder so both stay in sync.
Future<void> showCollectionSettingsDialog(
  BuildContext context,
  WidgetRef ref,
  Collection collection, {
  int initialTab = 0,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CollectionSettingsDialog(
      collection: collection,
      initialTab: initialTab,
    ),
  );
}

class _CollectionSettingsDialog extends ConsumerStatefulWidget {
  final Collection collection;
  final int initialTab;

  const _CollectionSettingsDialog({required this.collection, required this.initialTab});

  @override
  ConsumerState<_CollectionSettingsDialog> createState() => _CollectionSettingsDialogState();
}

class _CollectionSettingsDialogState extends ConsumerState<_CollectionSettingsDialog> {
  late final List<KeyValueEntry> _entries;
  late AuthConfig _auth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.collection.globalHeaders.entries
        .map((e) => KeyValueEntry(key: e.key, value: e.value))
        .toList();
    if (_entries.isEmpty) _entries.add(KeyValueEntry());
    _auth = AuthConfig.fromStored(widget.collection.authType, widget.collection.authData);
  }

  @override
  void dispose() {
    // Runs after the route (and its exit animation) is gone, so the fields
    // never see a disposed controller.
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.collection.copyWith(
      globalHeaders: entriesToMap(_entries),
      authType: _auth.storedType,
      authData: _auth.storedData,
    );
    try {
      await ref.read(collectionRepositoryProvider).updateCollection(updated);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showDbugToast(context, message: 'Failed to save: $e', type: ToastType.error);
      }
      return;
    }
    if (!mounted) return;
    ref.invalidate(collectionsProvider);
    ref.invalidate(collectionByIdProvider(widget.collection.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.settings2, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.collection.name)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: DefaultTabController(
          length: 2,
          initialIndex: widget.initialTab,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TabBar(
                tabs: [Tab(text: 'Headers'), Tab(text: 'Auth')],
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                labelPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: TabBarView(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'These headers are automatically included in every request in this collection.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: KeyValueEditor(
                              entries: _entries,
                              keyHint: 'Header name',
                              valueHint: 'Value',
                              onChanged: () => setState(() {}),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Auth is applied to all requests. Request-level auth takes precedence.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          AuthEditor(
                            value: _auth,
                            noneMessage: 'No collection auth',
                            onChanged: (next) => _auth = next,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
