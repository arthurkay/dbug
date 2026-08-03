import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/repositories/request_repository.dart';
import '../../../core/models/collection_model.dart';
import '../../../core/models/request_model.dart';
import '../../../shared/widgets/file_explorer.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/toast_helper.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  bool _showFileExplorer = false;
  final Set<String> _expandedCollections = {};

  Future<void> _importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      await _parseCollection(content, result.files.single.name);
    }
  }

  Future<void> _parseCollection(String content, String fileName) async {
    try {
      final json = jsonDecode(content);
      final collectionRepo = ref.read(collectionRepositoryProvider);
      final requestRepo = ref.read(requestRepositoryProvider);

      if (json is Map<String, dynamic> && json.containsKey('info')) {
        // Postman Collection v2.1
        final name = json['info']['name'] ?? fileName.replaceAll('.json', '');
        final desc = json['info']['description']?.toString();

        final collection = await collectionRepo.createCollection(
          name: name,
          description: desc ?? 'Imported from $fileName',
          sourceType: 'postman',
        );

        final items = json['item'] as List? ?? [];
        await _parsePostmanItems(items, requestRepo, collection.id, '');

        ref.invalidate(collectionsProvider);
        if (mounted) {
          showDbugToast(context, message: 'Imported "$name"', type: ToastType.success);
        }
      } else {
        // Unknown format — create empty collection
        await collectionRepo.createCollection(
          name: fileName.replaceAll('.json', ''),
          description: 'Imported from $fileName',
          sourceType: 'import',
        );
        ref.invalidate(collectionsProvider);
        if (mounted) {
          showDbugToast(context, message: 'Imported "$fileName" (no requests parsed)', type: ToastType.warning);
        }
      }
    } catch (e) {
      if (mounted) {
        showDbugToast(context, message: 'Failed to import: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _parsePostmanItems(List items, RequestRepository requestRepo, String collectionId, String prefix) async {
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      if (item.containsKey('item') && item['item'] is List) {
        // It's a folder — recurse
        final folderName = item['name'] ?? 'Folder';
        final subCollection = await ref.read(collectionRepositoryProvider).createCollection(
          name: '$prefix$folderName',
          description: 'Subfolder',
          sourceType: 'postman',
        );
        await _parsePostmanItems(item['item'] as List, requestRepo, subCollection.id, '');
      } else if (item.containsKey('request')) {
        // It's a request
        final req = item['request'] as Map<String, dynamic>;
        final name = item['name'] ?? 'Untitled';
        final method = (req['method'] ?? 'GET').toString().toUpperCase();

        String url = '';
        final urlData = req['url'];
        if (urlData is String) {
          url = urlData;
        } else if (urlData is Map<String, dynamic>) {
          final raw = urlData['raw']?.toString() ?? '';
          url = raw;
        }

        final headers = <String, String>{};
        for (final h in (req['header'] as List? ?? [])) {
          if (h is Map<String, dynamic> && h['key'] != null && h['value'] != null) {
            headers[h['key'].toString()] = h['value'].toString();
          }
        }

        String? body;
        String? bodyType;
        final bodyData = req['body'];
        if (bodyData is Map<String, dynamic>) {
          bodyType = bodyData['mode']?.toString();
          if (bodyType == 'raw') {
            body = bodyData['raw']?.toString();
          }
        }

        final queryParams = <String, String>{};
        if (urlData is Map<String, dynamic>) {
          for (final q in (urlData['query'] as List? ?? [])) {
            if (q is Map<String, dynamic> && q['key'] != null) {
              queryParams[q['key'].toString()] = q['value']?.toString() ?? '';
            }
          }
        }

        await requestRepo.createRequest(
          collectionId: collectionId,
          name: name,
          method: method,
          url: url,
          headers: headers,
          bodyType: bodyType,
          body: body,
          queryParams: queryParams,
        );
      }
    }
  }

  void _toggleExpand(String collectionId) {
    setState(() {
      if (_expandedCollections.contains(collectionId)) {
        _expandedCollections.remove(collectionId);
      } else {
        _expandedCollections.add(collectionId);
      }
    });
  }

  void _openRequest(RequestModel request, Map<String, String> collectionHeaders) {
    context.go('/request', extra: {'request': request, 'collectionHeaders': collectionHeaders});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final collectionsAsync = ref.watch(collectionsProvider);

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
                    Text('Collections', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.foreground)),
                    const SizedBox(height: 4),
                    Text('Organize your requests into collections', style: TextStyle(fontSize: 13, color: colorScheme.mutedForeground)),
                  ],
                ),
              ),
              if (_showFileExplorer)
                shad.Button.ghost(onPressed: () => setState(() => _showFileExplorer = false), leading: const Icon(Icons.close, size: 16), child: const Text('Close Explorer'))
              else ...[
                shad.Button.outline(onPressed: _importFromFile, leading: const Icon(Icons.file_upload_outlined, size: 16), child: const Text('Import')),
                const SizedBox(width: 8),
                shad.Button.outline(onPressed: () => setState(() => _showFileExplorer = true), leading: const Icon(Icons.folder_open, size: 16), child: const Text('Browse')),
                const SizedBox(width: 8),
                shad.Button.primary(onPressed: () => _showCreateDialog(context), leading: const Icon(Icons.add, size: 16), child: const Text('New Collection')),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildEnvSection(colorScheme),
          const SizedBox(height: 12),
          Expanded(
            child: _showFileExplorer
                ? FileExplorer(
                    allowedExtensions: ['json'],
                    onFileSelected: (file) async {
                      final content = await file.readAsString();
                      await _parseCollection(content, file.path.split('/').last);
                    },
                  )
                : collectionsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (collections) {
                      if (collections.isEmpty) return _buildEmptyState(colorScheme);
                      return shad.Card(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: collections.length,
                          itemBuilder: (context, index) {
                            final collection = collections[index];
                            final isExpanded = _expandedCollections.contains(collection.id);
                            return _CollectionExpandable(
                              collection: collection,
                              isExpanded: isExpanded,
                              onToggle: () => _toggleExpand(collection.id),
                              onDelete: () async {
                                final requestRepo = ref.read(requestRepositoryProvider);
                                await requestRepo.deleteByCollection(collection.id);
                                await ref.read(collectionRepositoryProvider).deleteCollection(collection.id);
                                ref.invalidate(collectionsProvider);
                              },
                              onRequestTap: _openRequest,
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

  Widget _buildEnvSection(shad.ColorScheme colorScheme) {
    final activeEnv = ref.watch(activeEnvironmentProvider);

    if (activeEnv == null) {
      return shad.Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No active environment — {{variables}} will not be substituted',
                  style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground),
                ),
              ),
              shad.Button.outline(
                onPressed: () => context.go('/environments'),
                child: const Text('Set Up', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      );
    }

    final variables = activeEnv.variables;

    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 14, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  activeEnv.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.foreground),
                ),
                const SizedBox(width: 6),
                Text(
                  '${variables.length} var${variables.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground),
                ),
                const Spacer(),
                shad.Button.ghost(
                  onPressed: () => _showQuickAddVarDialog(context),
                  leading: const Icon(Icons.add, size: 14),
                  child: const Text('Add Var', style: TextStyle(fontSize: 11)),
                ),
                shad.Button.ghost(
                  onPressed: () => context.go('/environments'),
                  child: const Text('Manage', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            if (variables.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: variables.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '{{${e.key}}}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary, fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '= ${e.value}',
                          style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground, fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickAddVarDialog(BuildContext context) {
    final nameController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => shad.AlertDialog(
        title: const Text('Add Variable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            shad.TextField(controller: nameController, placeholder: const Text('Variable name')),
            const SizedBox(height: 12),
            shad.TextField(controller: valueController, placeholder: const Text('Value')),
          ],
        ),
        actions: [
          shad.Button.ghost(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          shad.Button.primary(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final env = ref.read(activeEnvironmentProvider);
                if (env != null) {
                  final updated = Map<String, String>.from(env.variables);
                  updated[nameController.text] = valueController.text;
                  final updatedEnv = env.copyWith(variables: updated);
                  await ref.read(environmentRepositoryProvider).updateEnvironment(updatedEnv);
                  ref.read(activeEnvironmentProvider.notifier).state = updatedEnv;
                  ref.invalidate(environmentsProvider);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text('No collections yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const SizedBox(height: 8),
            Text('Create a collection or import an OpenAPI spec', style: TextStyle(color: colorScheme.mutedForeground)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                shad.Button.primary(onPressed: () => _showCreateDialog(context), leading: const Icon(Icons.add, size: 16), child: const Text('New Collection')),
                const SizedBox(width: 8),
                shad.Button.outline(onPressed: _importFromFile, leading: const Icon(Icons.file_upload_outlined, size: 16), child: const Text('Import File')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => shad.AlertDialog(
        title: const Text('New Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            shad.TextField(controller: nameController, placeholder: const Text('Collection name')),
            const SizedBox(height: 12),
            shad.TextField(controller: descController, placeholder: const Text('Description (optional)')),
          ],
        ),
        actions: [
          shad.Button.ghost(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          shad.Button.primary(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await ref.read(collectionRepositoryProvider).createCollection(
                  name: nameController.text,
                  description: descController.text.isNotEmpty ? descController.text : null,
                );
                ref.invalidate(collectionsProvider);
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

class _CollectionExpandable extends ConsumerWidget {
  final Collection collection;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final void Function(RequestModel request, Map<String, String> headers) onRequestTap;

  const _CollectionExpandable({
    required this.collection,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final headerCount = collection.globalHeaders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(isExpanded ? Icons.folder_open : Icons.folder, size: 16, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(collection.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.foreground), overflow: TextOverflow.ellipsis),
                      if (collection.description != null)
                        Text(collection.description!, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (headerCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.key, size: 10, color: colorScheme.primary),
                        const SizedBox(width: 3),
                        Text('$headerCount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorScheme.primary)),
                      ],
                    ),
                  ),
                shad.IconButton.ghost(
                  icon: Icon(Icons.vpn_key_outlined, size: 16, color: headerCount > 0 ? colorScheme.primary : colorScheme.mutedForeground),
                  onPressed: () => _showHeadersDialog(context, ref),
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: colorScheme.mutedForeground),
                const SizedBox(width: 4),
                shad.IconButton.ghost(icon: const Icon(Icons.delete_outline, size: 14), onPressed: onDelete),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          if (headerCount > 0)
            _buildHeadersPreview(colorScheme),
          _RequestList(
            collectionId: collection.id,
            onRequestTap: onRequestTap,
            collectionHeaders: collection.globalHeaders,
          ),
        ],
      ],
    );
  }

  Widget _buildHeadersPreview(shad.ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_outlined, size: 12, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text('Collection Headers', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.mutedForeground, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          ...collection.globalHeaders.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.foreground, fontFamily: 'monospace')),
                Text(': ', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
                Expanded(
                  child: Text(e.value, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showHeadersDialog(BuildContext context, WidgetRef ref) {
    final entries = collection.globalHeaders.entries
        .map((e) => KeyValueEntry(key: e.key, value: e.value))
        .toList();
    if (entries.isEmpty) entries.add(KeyValueEntry());

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => shad.AlertDialog(
          title: Row(
            children: [
              Icon(Icons.vpn_key_outlined, size: 18, color: shad.Theme.of(dialogContext).colorScheme.primary),
              const SizedBox(width: 8),
              Text('${collection.name} Headers'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'These headers are automatically included in every request in this collection. Request-level headers take precedence.',
                  style: TextStyle(fontSize: 12, color: shad.Theme.of(dialogContext).colorScheme.mutedForeground),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: KeyValueEditor(
                      entries: entries,
                      keyHint: 'Header name',
                      valueHint: 'Value',
                      onChanged: () => setDialogState(() {}),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            shad.Button.ghost(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            shad.Button.primary(
              onPressed: () async {
                final headers = entriesToMap(entries);
                final updated = collection.copyWith(globalHeaders: headers);
                await ref.read(collectionRepositoryProvider).updateCollection(updated);
                ref.invalidate(collectionsProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends ConsumerWidget {
  final String collectionId;
  final void Function(RequestModel request, Map<String, String> headers) onRequestTap;
  final Map<String, String> collectionHeaders;

  const _RequestList({required this.collectionId, required this.onRequestTap, this.collectionHeaders = const {}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final requestsAsync = ref.watch(requestsByCollectionProvider(collectionId));

    return requestsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Error: $e', style: TextStyle(color: colorScheme.mutedForeground)),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No requests', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: requests.map((req) => InkWell(
            onTap: () => onRequestTap(req, collectionHeaders),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _methodColor(req.method).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(req.method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _methodColor(req.method)), textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(req.name, style: TextStyle(fontSize: 12, color: colorScheme.foreground), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Color _methodColor(String method) {
    const colors = {
      'GET': Color(0xFF22C55E), 'POST': Color(0xFF3B82F6), 'PUT': Color(0xFFF59E0B),
      'PATCH': Color(0xFFF97316), 'DELETE': Color(0xFFEF4444),
    };
    return colors[method.toUpperCase()] ?? const Color(0xFF6B7280);
  }
}
