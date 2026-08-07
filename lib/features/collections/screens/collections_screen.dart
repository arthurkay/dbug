import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/utils/method_colors.dart';

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
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
        final folderName = item['name'] ?? 'Folder';
        final subCollection = await ref.read(collectionRepositoryProvider).createCollection(
          name: '$prefix$folderName',
          description: 'Subfolder',
          sourceType: 'postman',
        );
        await _parsePostmanItems(item['item'] as List, requestRepo, subCollection.id, '');
      } else if (item.containsKey('request')) {
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

  void _openRequest(RequestModel request, Map<String, String> collectionHeaders, {String? collectionId, String? collectionAuthType, String? collectionAuthData}) {
    context.go('/request', extra: {'request': request, 'collectionHeaders': collectionHeaders, 'collectionId': collectionId, 'collectionAuthType': collectionAuthType, 'collectionAuthData': collectionAuthData});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                    Text('Collections', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Organize your requests into collections', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (_showFileExplorer)
                TextButton.icon(onPressed: () => setState(() => _showFileExplorer = false), icon: const Icon(LucideIcons.x, size: 16), label: const Text('Close Explorer'))
              else ...[
                OutlinedButton.icon(onPressed: _importFromFile, icon: const Icon(LucideIcons.upload, size: 16), label: const Text('Import')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () => setState(() => _showFileExplorer = true), icon: const Icon(LucideIcons.folderOpen, size: 16), label: const Text('Browse')),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(LucideIcons.plus, size: 16), label: const Text('New Collection')),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildEnvSection(colorScheme),
          const SizedBox(height: 12),
          if (!_showFileExplorer)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search requests by name, method, or URL...',
                  isDense: true,
                  prefixIcon: Icon(LucideIcons.search, size: 16),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              ),
            ),
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
                    loading: () => const Center(child: DbugSpinner()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (collections) {
                      if (collections.isEmpty) return _buildEmptyState(colorScheme);
                      return Card(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: collections.length,
                          itemBuilder: (context, index) {
                            final collection = collections[index];
                            final isExpanded = _expandedCollections.contains(collection.id);
                            return _CollectionExpandable(
                              collection: collection,
                              isExpanded: isExpanded || _searchQuery.isNotEmpty,
                              onToggle: () => _toggleExpand(collection.id),
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Collection'),
                                    content: Text('Delete "${collection.name}" and all its requests?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                final requestRepo = ref.read(requestRepositoryProvider);
                                await requestRepo.deleteByCollection(collection.id);
                                await ref.read(collectionRepositoryProvider).deleteCollection(collection.id);
                                ref.invalidate(collectionsProvider);
                              },
                              onRequestTap: _openRequest,
                              searchQuery: _searchQuery,
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

  Widget _buildEnvSection(ColorScheme colorScheme) {
    final activeEnv = ref.watch(activeEnvironmentProvider);

    if (activeEnv == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(LucideIcons.triangleAlert, size: 16, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No active environment — {{variables}} will not be substituted',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              OutlinedButton(
                onPressed: () => context.go('/environments'),
                child: const Text('Set Up', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      );
    }

    final variables = activeEnv.variables;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.braces, size: 14, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(activeEnv.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text('${variables.length} var${variables.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showQuickAddVarDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Add Var', style: TextStyle(fontSize: 11)),
                ),
                TextButton(
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
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('{{${e.key}}}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary, fontFamily: 'monospace')),
                        const SizedBox(width: 4),
                        Text('= ${e.value}', style: TextStyle(fontSize: 11, color: colorScheme.outline, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Variable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Variable name')),
              const SizedBox(height: 12),
              TextField(controller: valueController, decoration: const InputDecoration(hintText: 'Value')),
            ],
          ),
          actions: [
            TextButton(onPressed: () { nameController.dispose(); valueController.dispose(); Navigator.pop(context); }, child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final env = ref.read(activeEnvironmentProvider);
                  if (env != null) {
                    final updated = Map<String, String>.from(env.variables);
                    updated[nameController.text] = valueController.text;
                    final updatedEnv = env.copyWith(variables: updated);
                    await ref.read(environmentRepositoryProvider).updateEnvironment(updatedEnv);
                    ref.read(activeEnvironmentProvider.notifier).setActive(updatedEnv);
                    ref.invalidate(environmentsProvider);
                  }
                  nameController.dispose();
                  valueController.dispose();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add'),
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
            Icon(LucideIcons.folderOpen, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No collections yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Create a collection or import an OpenAPI spec', style: TextStyle(color: colorScheme.outline)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(onPressed: () => _showCreateDialog(context), icon: const Icon(LucideIcons.plus, size: 16), label: const Text('New Collection')),
                const SizedBox(width: 8),
                OutlinedButton.icon(onPressed: _importFromFile, icon: const Icon(LucideIcons.upload, size: 16), label: const Text('Import File')),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Collection name')),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () { nameController.dispose(); descController.dispose(); Navigator.pop(context); }, child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await ref.read(collectionRepositoryProvider).createCollection(
                    name: nameController.text,
                    description: descController.text.isNotEmpty ? descController.text : null,
                  );
                  ref.invalidate(collectionsProvider);
                  nameController.dispose();
                  descController.dispose();
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

class _CollectionExpandable extends ConsumerWidget {
  final Collection collection;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final void Function(RequestModel request, Map<String, String> headers, {String? collectionId, String? collectionAuthType, String? collectionAuthData}) onRequestTap;
  final String searchQuery;

  const _CollectionExpandable({
    required this.collection,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onRequestTap,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerCount = collection.globalHeaders.length;
    final hasAuth = collection.authType != 'none';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(isExpanded ? LucideIcons.folderOpen : LucideIcons.folder, size: 16, color: Colors.orange),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(collection.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              if (collection.description != null)
                Text(collection.description!, style: TextStyle(fontSize: 11, color: colorScheme.outline), overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (headerCount > 0 || hasAuth)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (headerCount > 0) ...[
                        Icon(LucideIcons.key, size: 10, color: colorScheme.outline),
                        const SizedBox(width: 3),
                        Text('$headerCount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorScheme.outline)),
                      ],
                      if (headerCount > 0 && hasAuth) const SizedBox(width: 6),
                      if (hasAuth) ...[
                        Icon(LucideIcons.shield, size: 10, color: colorScheme.outline),
                        const SizedBox(width: 3),
                        Text(collection.authType.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colorScheme.outline)),
                      ],
                    ],
                  ),
                ),
              IconButton(
                icon: Icon(LucideIcons.key, size: 16, color: headerCount > 0 ? colorScheme.primary : colorScheme.outline),
                onPressed: () => _showHeadersDialog(context, ref),
                visualDensity: VisualDensity.compact,
              ),
              Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18, color: colorScheme.outline),
              const SizedBox(width: 4),
              IconButton(icon: const Icon(LucideIcons.trash2, size: 14), onPressed: onDelete, visualDensity: VisualDensity.compact),
            ],
          ),
          onTap: onToggle,
        ),
        if (isExpanded) ...[
          if (headerCount > 0)
            _buildHeadersPreview(colorScheme),
          _RequestList(
            collectionId: collection.id,
            onRequestTap: onRequestTap,
            collectionHeaders: collection.globalHeaders,
            collectionAuthType: collection.authType != 'none' ? collection.authType : null,
            collectionAuthData: collection.authType != 'none' ? collection.authData : null,
            searchQuery: searchQuery,
          ),
        ],
      ],
    );
  }

  Widget _buildHeadersPreview(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.key, size: 12, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text('Collection Headers', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.outline, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          ...collection.globalHeaders.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: 'monospace')),
                Text(': ', style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                Expanded(
                  child: Text(e.value, style: TextStyle(fontSize: 11, color: colorScheme.outline, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
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

    String authType = collection.authType;
    final bearerController = TextEditingController();
    final basicUserController = TextEditingController();
    final basicPassController = TextEditingController();
    final apiKeyNameController = TextEditingController();
    final apiKeyValueController = TextEditingController();
    String apiKeyLocation = 'header';

    // Parse existing auth data
    try {
      final data = Map<String, dynamic>.from(jsonDecode(collection.authData));
      bearerController.text = data['token'] ?? '';
      basicUserController.text = data['username'] ?? '';
      basicPassController.text = data['password'] ?? '';
      apiKeyNameController.text = data['name'] ?? '';
      apiKeyValueController.text = data['value'] ?? '';
      apiKeyLocation = data['location'] ?? 'header';
    } catch (_) {}

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.settings2, size: 18, color: Theme.of(dialogContext).colorScheme.outline),
              const SizedBox(width: 8),
              Expanded(child: Text('${collection.name}')),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    tabs: const [Tab(text: 'Headers'), Tab(text: 'Auth')],
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                              style: Theme.of(dialogContext).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Expanded(
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
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Auth is applied to all requests. Request-level auth takes precedence.',
                                style: Theme.of(dialogContext).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: ['None', 'Bearer', 'Basic', 'API Key'].map((t) {
                                  final typeMap = {'None': 'none', 'Bearer': 'bearer', 'Basic': 'basic', 'API Key': 'apikey'};
                                  final isSelected = authType == typeMap[t];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: isSelected
                                        ? FilledButton.tonal(
                                            onPressed: () => setDialogState(() => authType = typeMap[t]!),
                                            child: Text(t, style: const TextStyle(fontSize: 11)),
                                          )
                                        : OutlinedButton(
                                            onPressed: () => setDialogState(() => authType = typeMap[t]!),
                                            child: Text(t, style: const TextStyle(fontSize: 11)),
                                          ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              if (authType == 'bearer') ...[
                                Text('Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(dialogContext).colorScheme.onSurface)),
                                const SizedBox(height: 6),
                                TextField(controller: bearerController, decoration: const InputDecoration(hintText: 'Enter bearer token', border: OutlineInputBorder())),
                              ] else if (authType == 'basic') ...[
                                Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(dialogContext).colorScheme.onSurface)),
                                const SizedBox(height: 6),
                                TextField(controller: basicUserController, decoration: const InputDecoration(hintText: 'Username', border: OutlineInputBorder())),
                                const SizedBox(height: 12),
                                Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(dialogContext).colorScheme.onSurface)),
                                const SizedBox(height: 6),
                                TextField(controller: basicPassController, obscureText: true, decoration: const InputDecoration(hintText: 'Password', border: OutlineInputBorder())),
                              ] else if (authType == 'apikey') ...[
                                Text('Key Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(dialogContext).colorScheme.onSurface)),
                                const SizedBox(height: 6),
                                TextField(controller: apiKeyNameController, decoration: const InputDecoration(hintText: 'X-API-Key', border: OutlineInputBorder())),
                                const SizedBox(height: 12),
                                Text('Key Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(dialogContext).colorScheme.onSurface)),
                                const SizedBox(height: 6),
                                TextField(controller: apiKeyValueController, decoration: const InputDecoration(hintText: 'Your API key', border: OutlineInputBorder())),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text('Add to:', style: TextStyle(fontSize: 12, color: Theme.of(dialogContext).colorScheme.onSurface)),
                                    const SizedBox(width: 8),
                                    apiKeyLocation == 'header'
                                        ? FilledButton.tonal(onPressed: () => setDialogState(() => apiKeyLocation = 'header'), child: const Text('Header', style: TextStyle(fontSize: 11)))
                                        : OutlinedButton(onPressed: () => setDialogState(() => apiKeyLocation = 'header'), child: const Text('Header', style: TextStyle(fontSize: 11))),
                                    const SizedBox(width: 4),
                                    apiKeyLocation == 'query'
                                        ? FilledButton.tonal(onPressed: () => setDialogState(() => apiKeyLocation = 'query'), child: const Text('Query Param', style: TextStyle(fontSize: 11)))
                                        : OutlinedButton(onPressed: () => setDialogState(() => apiKeyLocation = 'query'), child: const Text('Query Param', style: TextStyle(fontSize: 11))),
                                  ],
                                ),
                              ] else ...[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text('No collection auth', style: TextStyle(color: Theme.of(dialogContext).colorScheme.outline)),
                                  ),
                                ),
                              ],
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final headers = entriesToMap(entries);

                String authData = '{}';
                if (authType == 'bearer') {
                  authData = jsonEncode({'token': bearerController.text});
                } else if (authType == 'basic') {
                  authData = jsonEncode({'username': basicUserController.text, 'password': basicPassController.text});
                } else if (authType == 'apikey') {
                  authData = jsonEncode({'name': apiKeyNameController.text, 'value': apiKeyValueController.text, 'location': apiKeyLocation});
                }

                final updated = collection.copyWith(
                  globalHeaders: headers,
                  authType: authType,
                  authData: authData,
                );
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
  final void Function(RequestModel request, Map<String, String> headers, {String? collectionId, String? collectionAuthType, String? collectionAuthData}) onRequestTap;
  final Map<String, String> collectionHeaders;
  final String? collectionAuthType;
  final String? collectionAuthData;
  final String searchQuery;

  const _RequestList({required this.collectionId, required this.onRequestTap, this.collectionHeaders = const {}, this.collectionAuthType, this.collectionAuthData, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final requestsAsync = ref.watch(requestsByCollectionProvider(collectionId));

    return requestsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: SizedBox(width: 16, height: 16, child: DbugSpinner(strokeWidth: 2))),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Error: $e', style: TextStyle(color: colorScheme.outline)),
      ),
      data: (requests) {
        final filtered = searchQuery.isEmpty ? requests : requests.where((req) {
          return req.name.toLowerCase().contains(searchQuery) ||
              req.method.toLowerCase().contains(searchQuery) ||
              req.url.toLowerCase().contains(searchQuery);
        }).toList();
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(searchQuery.isEmpty ? 'No requests' : 'No matching requests', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: filtered.map((req) => ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: methodColor(req.method).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(req.method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: methodColor(req.method)), textAlign: TextAlign.center),
              ),
              title: Text(req.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              onTap: () => onRequestTap(req, collectionHeaders, collectionId: collectionId, collectionAuthType: collectionAuthType, collectionAuthData: collectionAuthData),
            )).toList(),
          ),
        );
      },
    );
  }
}
