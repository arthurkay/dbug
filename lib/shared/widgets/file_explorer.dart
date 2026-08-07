import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dbug_spinner.dart';

class FileExplorer extends StatefulWidget {
  final List<String> allowedExtensions;
  final ValueChanged<File> onFileSelected;
  final String? initialDirectory;

  const FileExplorer({
    super.key,
    required this.allowedExtensions,
    required this.onFileSelected,
    this.initialDirectory,
  });

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  late Directory _currentDirectory;
  List<FileSystemEntity> _entries = [];
  String? _selectedPath;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _currentDirectory = Directory(widget.initialDirectory ?? Directory.current.path);
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() { _isLoading = true; _loadError = null; });

    try {
      final entries = await _currentDirectory.list().toList();
      entries.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
      });

      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _entries = [];
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  void _navigateToDirectory(Directory dir) {
    setState(() {
      _currentDirectory = dir;
      _selectedPath = null;
    });
    _loadDirectory();
  }

  void _navigateUp() {
    final parent = _currentDirectory.parent;
    if (parent.path != _currentDirectory.path) {
      _navigateToDirectory(parent);
    }
  }

  bool _isAllowedFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return widget.allowedExtensions.any((e) => ext == '.$e' || ext == e);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbBar(context, colorScheme),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: DbugSpinner())
                : _entries.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : _buildFileList(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowUp, size: 16),
            onPressed: _currentDirectory.parent.path != _currentDirectory.path
                ? _navigateUp
                : null,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildBreadcrumbs(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(ColorScheme colorScheme) {
    final pathParts = p.split(_currentDirectory.path);
    final breadcrumbs = <Widget>[];

    for (var i = 0; i < pathParts.length; i++) {
      if (i > 0) {
        breadcrumbs.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(LucideIcons.chevronRight, size: 14, color: colorScheme.outline),
          ),
        );
      }

      final part = pathParts[i];
      final fullPath = pathParts.sublist(0, i + 1).join(Platform.pathSeparator);
      final isLast = i == pathParts.length - 1;

      breadcrumbs.add(
        GestureDetector(
          onTap: isLast
              ? null
              : () => _navigateToDirectory(Directory(fullPath)),
          child: Text(
            part.isEmpty ? Platform.pathSeparator : part,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
              color: isLast ? colorScheme.onSurface : colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Row(children: breadcrumbs);
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    final hasError = _loadError != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasError ? LucideIcons.circleAlert : LucideIcons.folderOpen, size: 48, color: hasError ? Colors.orange : colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            hasError ? 'Cannot access directory' : 'Empty directory',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.outline,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              _loadError!,
              style: TextStyle(fontSize: 11, color: colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final isDirectory = entry is Directory;
        final name = p.basename(entry.path);
        final isSelected = _selectedPath == entry.path;
        final isAllowed = !isDirectory && _isAllowedFile(entry.path);

        return _FileTile(
          name: name,
          isDirectory: isDirectory,
          isSelected: isSelected,
          isAllowed: isAllowed,
          onTap: () {
            if (isDirectory) {
              _navigateToDirectory(entry);
            } else if (isAllowed) {
              setState(() => _selectedPath = entry.path);
              widget.onFileSelected(entry as File);
            }
          },
        );
      },
    );
  }
}

class _FileTile extends StatelessWidget {
  final String name;
  final bool isDirectory;
  final bool isSelected;
  final bool isAllowed;
  final VoidCallback onTap;

  const _FileTile({
    required this.name,
    required this.isDirectory,
    required this.isSelected,
    required this.isAllowed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final icon = isDirectory
        ? LucideIcons.folder
        : _getFileIcon(name);
    final iconColor = isDirectory
        ? Colors.orange
        : isAllowed
            ? colorScheme.primary
            : colorScheme.outline;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      enabled: isDirectory || isAllowed,
      selected: isSelected,
      selectedTileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      leading: Icon(icon, size: 16, color: iconColor),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 13,
          color: (isDirectory || isAllowed)
              ? colorScheme.onSurface
              : colorScheme.outline,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isDirectory
          ? Icon(LucideIcons.chevronRight, size: 16, color: colorScheme.outline)
          : null,
      onTap: onTap,
    );
  }

  IconData _getFileIcon(String name) {
    final ext = p.extension(name).toLowerCase();
    switch (ext) {
      case '.json':
        return LucideIcons.braces;
      case '.yaml':
      case '.yml':
        return LucideIcons.fileText;
      default:
        return LucideIcons.file;
    }
  }
}
