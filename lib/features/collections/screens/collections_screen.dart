import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/utils/secret_display.dart';
import '../../../core/models/auth_config.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/utils/syntax_highlighter.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/utils/method_colors.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/window_title_provider.dart';
import '../data/postman_importer.dart';
import '../data/postman_exporter.dart';
import '../../environments/spec_environment_activation.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../core/models/collection_model.dart';
import '../../../core/models/request_model.dart';
import '../../../shared/widgets/file_explorer.dart';
import '../widgets/collection_settings_dialog.dart';
import '../../../shared/widgets/toast_helper.dart';

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  bool _revealSecrets = false;
  bool _showFileExplorer = false;
  final Set<String> _expandedCollections = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(windowTitleProvider.notifier).state = 'Collections';
    });
  }

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
      final result = await PostmanImporter(
        collections: ref.read(collectionRepositoryProvider),
        requests: ref.read(requestRepositoryProvider),
      ).importJson(content, fileName: fileName);
      ref.invalidate(collectionsProvider);
      if (mounted) {
        showDbugToast(context, message: 'Imported "${result.rootName}" — ${result.requestCount} requests', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        final message = e is FormatException ? e.message : '$e';
        showDbugToast(context, message: 'Failed to import: $message', type: ToastType.error);
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

  Future<void> _openRequest(RequestModel request, Map<String, String> collectionHeaders, {String? collectionId, String? collectionAuthType, String? collectionAuthData}) async {
    // Requests of an imported spec use {{baseUrl}}; select the spec's
    // environment when the user hasn't chosen one yet.
    if (collectionId != null) {
      await activateSpecEnvironmentIfNone(ref, context, collectionId);
      if (!mounted) return;
    }
    context.go('/request', extra: {'request': request, 'collectionHeaders': collectionHeaders, 'collectionId': collectionId, 'collectionAuthType': collectionAuthType, 'collectionAuthData': collectionAuthData});
  }

  Future<void> _exportCollection(Collection collection) async {
    try {
      final requests = await ref.read(requestRepositoryProvider).getRequestsByCollection(collection.id);
      final json = exportPostmanCollectionJson(collection, requests);
      final safeName = collection.name.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export collection',
        fileName: '${safeName.isEmpty ? 'collection' : safeName}.postman_collection.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return;
      await File(path).writeAsString(json);
      if (mounted) {
        showDbugToast(context, message: 'Exported ${requests.length} requests to ${path.split(Platform.pathSeparator).last}', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) showDbugToast(context, message: 'Export failed: $e', type: ToastType.error);
    }
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
              Expanded(child: PageHeader(title: 'Collections', subtitle: 'Organize your requests into collections')),
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
                                // Family providers aren't autoDispose: drop the
                                // cached copies so nothing keeps using them.
                                ref.invalidate(collectionByIdProvider(collection.id));
                                ref.invalidate(requestsByCollectionProvider(collection.id));
                              },
                              onExport: () => _exportCollection(collection),
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
    final hasSensitive = variables.keys.any(looksSensitive);

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
                if (hasSensitive)
                  IconButton(
                    tooltip: _revealSecrets ? 'Hide secret values' : 'Show secret values',
                    icon: Icon(_revealSecrets ? LucideIcons.eyeOff : LucideIcons.eye, size: 15),
                    onPressed: () => setState(() => _revealSecrets = !_revealSecrets),
                    visualDensity: VisualDensity.compact,
                  ),
                TextButton.icon(
                  onPressed: () => _showQuickAddVarDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Add Var', style: TextStyle(fontSize: 11)),
                ),
                TextButton(
                  onPressed: () => context.go('/environments/${activeEnv.id}'),
                  child: const Text('Edit', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            if (variables.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: variables.entries.map((e) {
                  final shown = !_revealSecrets && looksSensitive(e.key) ? maskSecret(e.value) : e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('{{${e.key}}}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary, fontFamily: codeFontFamily)),
                        const SizedBox(width: 4),
                        Text(shown.isEmpty ? '= (empty)' : '= $shown', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: codeFontFamily), overflow: TextOverflow.ellipsis),
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

  Future<void> _showQuickAddVarDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final valueController = TextEditingController();

    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Variable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(hintText: 'Variable name')),
            const SizedBox(height: 12),
            TextField(controller: valueController, decoration: const InputDecoration(hintText: 'Value')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, (name, valueController.text));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    // Disposed only after the dialog (and its exit animation) is gone.
    nameController.dispose();
    valueController.dispose();
    if (result == null) return;

    final env = ref.read(activeEnvironmentProvider);
    if (env == null) return;
    final updated = {...env.variables, result.$1: result.$2};
    await ref.read(environmentRepositoryProvider).updateEnvironment(env.copyWith(variables: updated));
    // The active environment is derived from this provider.
    ref.invalidate(environmentsProvider);
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.folderOpen, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No collections yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Create a collection or import an OpenAPI spec', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(hintText: 'Collection name')),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(hintText: 'Description (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, (name, descController.text.trim()));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    descController.dispose();
    if (result == null) return;

    await ref.read(collectionRepositoryProvider).createCollection(
      name: result.$1,
      description: result.$2.isNotEmpty ? result.$2 : null,
    );
    ref.invalidate(collectionsProvider);
  }
}

class _CollectionExpandable extends ConsumerWidget {
  final Collection collection;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final void Function(RequestModel request, Map<String, String> headers, {String? collectionId, String? collectionAuthType, String? collectionAuthData}) onRequestTap;
  final String searchQuery;

  const _CollectionExpandable({
    required this.collection,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onExport,
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
                Text(collection.description!, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (headerCount > 0 || hasAuth)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (headerCount > 0) ...[
                        Icon(LucideIcons.list, size: 11, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text('$headerCount header${headerCount == 1 ? '' : 's'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                      ],
                      if (headerCount > 0 && hasAuth) const SizedBox(width: 6),
                      if (hasAuth) ...[
                        Icon(LucideIcons.shield, size: 10, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(AuthType.fromStored(collection.authType).label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Collection actions',
                icon: Icon(LucideIcons.ellipsis, size: 16, color: colorScheme.onSurfaceVariant),
                onSelected: (action) {
                  switch (action) {
                    case 'settings':
                      showCollectionSettingsDialog(context, ref, collection);
                    case 'export':
                      onExport();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'settings', child: _MenuRow(LucideIcons.keyRound, 'Headers & auth')),
                  PopupMenuItem(value: 'export', child: _MenuRow(LucideIcons.download, 'Export (Postman v2.1)')),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: _MenuRow(LucideIcons.trash2, 'Delete collection')),
                ],
              ),
              Icon(isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: colorScheme.onSurfaceVariant),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => _showAddRequestDialog(context, ref),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('New Request', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
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
              Text('Collection Headers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          ...collection.globalHeaders.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: codeFontFamily)),
                Text(': ', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                Expanded(
                  child: Text(e.value, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: codeFontFamily), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _showAddRequestDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    var method = 'GET';

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New Request'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(hintText: 'Request name')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: method,
                      isDense: true,
                      items: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(fontSize: 12, color: methodColor(m)))))
                          .toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => method = v); },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: urlController,
                        decoration: const InputDecoration(hintText: 'URL (e.g. /api/users)'),
                        style: TextStyle(fontFamily: codeFontFamily, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final url = urlController.text.trim();
                if (url.isEmpty) return;
                final name = nameController.text.trim().isNotEmpty ? nameController.text.trim() : '$method $url';
                await ref.read(requestRepositoryProvider).createRequest(
                  collectionId: collection.id,
                  name: name,
                  method: method,
                  url: url,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    urlController.dispose();
    if (created == true) {
      ref.invalidate(collectionsProvider);
      ref.invalidate(requestsByCollectionProvider(collection.id));
    }
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
        child: Text('Error: $e', style: TextStyle(color: colorScheme.onSurfaceVariant)),
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
            child: Text(searchQuery.isEmpty ? 'No requests' : 'No matching requests', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            children: filtered.map((req) => GestureDetector(
              onSecondaryTapDown: (d) => _showRequestMenu(context, ref, req, d.globalPosition),
              child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: methodColor(req.method).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(req.method, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: methodColor(req.method)), textAlign: TextAlign.center),
              ),
              title: Text(req.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              trailing: Builder(
                builder: (buttonContext) => IconButton(
                  icon: const Icon(LucideIcons.ellipsis, size: 16),
                  tooltip: 'Request actions',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final box = buttonContext.findRenderObject() as RenderBox;
                    _showRequestMenu(context, ref, req, box.localToGlobal(box.size.bottomLeft(Offset.zero)));
                  },
                ),
              ),
              onTap: () => onRequestTap(req, collectionHeaders, collectionId: collectionId, collectionAuthType: collectionAuthType, collectionAuthData: collectionAuthData),
            ))).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showRequestMenu(BuildContext context, WidgetRef ref, RequestModel req, Offset position) async {
    // Positions are relative to the navigator's overlay (beside the sidebar).
    final overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final local = overlay.globalToLocal(position);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(local & Size.zero, Offset.zero & overlay.size),
      items: const [
        PopupMenuItem(value: 'rename', child: _MenuRow(LucideIcons.pencil, 'Rename')),
        PopupMenuItem(value: 'duplicate', child: _MenuRow(LucideIcons.copy, 'Duplicate')),
        PopupMenuItem(value: 'move', child: _MenuRow(LucideIcons.folderInput, 'Move to collection…')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: _MenuRow(LucideIcons.trash2, 'Delete')),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'rename':
        await _renameRequest(context, ref, req);
      case 'duplicate':
        await _duplicateRequest(context, ref, req);
      case 'move':
        await _moveRequest(context, ref, req);
      case 'delete':
        await _deleteRequest(context, ref, req);
    }
  }

  void _refresh(WidgetRef ref, Iterable<String?> collectionIds) {
    ref.invalidate(collectionsProvider);
    for (final id in collectionIds.whereType<String>().toSet()) {
      ref.invalidate(requestsByCollectionProvider(id));
    }
  }

  Future<void> _renameRequest(BuildContext context, WidgetRef ref, RequestModel req) async {
    final controller = TextEditingController(text: req.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Request'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Request name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Rename')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || name == req.name) return;
    await ref.read(requestRepositoryProvider).updateRequest(req.copyWith(name: name));
    _refresh(ref, [req.collectionId]);
  }

  Future<void> _duplicateRequest(BuildContext context, WidgetRef ref, RequestModel req) async {
    await ref.read(requestRepositoryProvider).createRequest(
      collectionId: req.collectionId,
      name: '${req.name} (copy)',
      method: req.method,
      url: req.url,
      headers: req.headers,
      bodyType: req.bodyType,
      body: req.body,
      queryParams: req.queryParams,
      authType: req.authType,
      authData: req.authData,
    );
    _refresh(ref, [req.collectionId]);
    if (context.mounted) showDbugToast(context, message: 'Duplicated "${req.name}"', type: ToastType.success);
  }

  Future<void> _moveRequest(BuildContext context, WidgetRef ref, RequestModel req) async {
    final collections = (await ref.read(collectionRepositoryProvider).getAllCollections())
        .where((c) => c.id != req.collectionId)
        .toList();
    if (!context.mounted) return;
    if (collections.isEmpty) {
      showDbugToast(context, message: 'There is no other collection to move it to', type: ToastType.warning);
      return;
    }
    final target = await showCollectionPickerDialog(
      context,
      collections: collections,
      message: 'Move "${req.name}" to:',
    );
    if (target == null) return;
    await ref.read(requestRepositoryProvider).updateRequest(req.copyWith(collectionId: target));
    _refresh(ref, [req.collectionId, target]);
    if (context.mounted) {
      final name = collections.firstWhere((c) => c.id == target).name;
      showDbugToast(context, message: 'Moved to $name', type: ToastType.success);
    }
  }

  Future<void> _deleteRequest(BuildContext context, WidgetRef ref, RequestModel req) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: Text('Delete "${req.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(requestRepositoryProvider).deleteRequest(req.id);
    _refresh(ref, [req.collectionId]);
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
