import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import '../../../core/repositories/collection_repository.dart';
import '../../../core/models/collection_model.dart';
import '../../../shared/widgets/file_explorer.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  bool _showFileExplorer = false;
  List<Collection> _collections = [];

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final collections = await CollectionRepository.getAllCollections();
    if (mounted) setState(() => _collections = collections);
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
      await CollectionRepository.createCollection(
        name: fileName.replaceAll('.json', ''),
        description: 'Imported from $fileName',
        sourceType: 'import',
      );
      await _loadCollections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "$fileName"'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deleteCollection(Collection collection) async {
    await CollectionRepository.deleteCollection(collection.id);
    await _loadCollections();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${collection.name}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = shad.Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    Text(
                      'Collections',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organize your requests into collections',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showFileExplorer) ...[
                shad.Button.ghost(
                  onPressed: () => setState(() => _showFileExplorer = false),
                  leading: const Icon(Icons.close, size: 16),
                  child: const Text('Close Explorer'),
                ),
              ] else ...[
                shad.Button.outline(
                  onPressed: _importFromFile,
                  leading: const Icon(Icons.file_upload_outlined, size: 16),
                  child: const Text('Import'),
                ),
                const SizedBox(width: 8),
                shad.Button.outline(
                  onPressed: () => setState(() => _showFileExplorer = true),
                  leading: const Icon(Icons.folder_open, size: 16),
                  child: const Text('Browse'),
                ),
                const SizedBox(width: 8),
                shad.Button.primary(
                  onPressed: () => _showCreateDialog(context),
                  leading: const Icon(Icons.add, size: 16),
                  child: const Text('New Collection'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _showFileExplorer
                ? FileExplorer(
                    allowedExtensions: ['json'],
                    onFileSelected: (file) async {
                      final content = await file.readAsString();
                      await _parseCollection(content, file.path.split('/').last);
                    },
                  )
                : _buildCollectionList(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionList(shad.ColorScheme colorScheme) {
    if (_collections.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    return shad.Card(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _collections.length,
        itemBuilder: (context, index) {
          final collection = _collections[index];
          return _CollectionTile(
            collection: collection,
            onDelete: () => _deleteCollection(collection),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: colorScheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'No collections yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a collection or import a Postman/Insomnia file',
              style: TextStyle(color: colorScheme.mutedForeground),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                shad.Button.primary(
                  onPressed: () => _showCreateDialog(context),
                  leading: const Icon(Icons.add, size: 16),
                  child: const Text('New Collection'),
                ),
                const SizedBox(width: 8),
                shad.Button.outline(
                  onPressed: _importFromFile,
                  leading: const Icon(Icons.file_upload_outlined, size: 16),
                  child: const Text('Import File'),
                ),
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
            shad.TextField(
              controller: nameController,
              placeholder: const Text('Collection name'),
            ),
            const SizedBox(height: 12),
            shad.TextField(
              controller: descController,
              placeholder: const Text('Description (optional)'),
            ),
          ],
        ),
        actions: [
          shad.Button.ghost(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          shad.Button.primary(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await CollectionRepository.createCollection(
                  name: nameController.text,
                  description: descController.text.isNotEmpty ? descController.text : null,
                );
                await _loadCollections();
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

class _CollectionTile extends StatelessWidget {
  final Collection collection;
  final VoidCallback onDelete;

  const _CollectionTile({required this.collection, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: shad.Button.ghost(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.folder, size: 16, color: const Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.foreground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (collection.description != null)
                      Text(
                        collection.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              shad.IconButton.ghost(
                icon: const Icon(Icons.delete_outline, size: 14),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
