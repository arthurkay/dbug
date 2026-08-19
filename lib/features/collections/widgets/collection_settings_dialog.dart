import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/collection_model.dart';
import '../../../core/providers/repository_providers.dart';
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

  try {
    final data = Map<String, dynamic>.from(jsonDecode(collection.authData));
    bearerController.text = data['token'] ?? '';
    basicUserController.text = data['username'] ?? '';
    basicPassController.text = data['password'] ?? '';
    apiKeyNameController.text = data['name'] ?? '';
    apiKeyValueController.text = data['value'] ?? '';
    apiKeyLocation = data['location'] ?? 'header';
  } catch (_) {}

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.settings2, size: 18, color: Theme.of(dialogContext).colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(child: Text(collection.name)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: DefaultTabController(
            length: 2,
            initialIndex: initialTab,
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
              // Grab the repository before awaiting: the host element (and
              // its ref) can be disposed while the write is in flight.
              final repo = ref.read(collectionRepositoryProvider);
              try {
                await repo.updateCollection(updated);
              } catch (e) {
                if (dialogContext.mounted) {
                  showDbugToast(dialogContext,
                      message: 'Failed to save: $e', type: ToastType.error);
                }
                return;
              }
              try {
                ref.invalidate(collectionsProvider);
                ref.invalidate(collectionByIdProvider(collection.id));
              } catch (_) {
                // Host element was disposed during the await; the write is
                // committed and providers will refetch on next creation.
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
