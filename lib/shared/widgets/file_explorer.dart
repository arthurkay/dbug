import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;

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
    final colorScheme = shad.Theme.of(context).colorScheme;

    return shad.Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbBar(context, colorScheme),
          Container(height: 1, color: colorScheme.border.withValues(alpha: 0.5)),
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

  Widget _buildBreadcrumbBar(BuildContext context, shad.ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colorScheme.card,
      child: Row(
        children: [
          shad.IconButton.ghost(
            icon: const Icon(LucideIcons.arrowUp, size: 16),
            onPressed: _currentDirectory.parent.path != _currentDirectory.path
                ? _navigateUp
                : null,
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

  Widget _buildBreadcrumbs(shad.ColorScheme colorScheme) {
    final pathParts = p.split(_currentDirectory.path);
    final breadcrumbs = <Widget>[];

    for (var i = 0; i < pathParts.length; i++) {
      if (i > 0) {
        breadcrumbs.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(LucideIcons.chevronRight, size: 14, color: colorScheme.mutedForeground),
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
              color: isLast ? colorScheme.foreground : colorScheme.mutedForeground,
            ),
          ),
        ),
      );
    }

    return Row(children: breadcrumbs);
  }

  Widget _buildEmptyState(shad.ColorScheme colorScheme) {
    final hasError = _loadError != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasError ? LucideIcons.circleAlert : LucideIcons.folderOpen, size: 48, color: hasError ? const Color(0xFFF59E0B) : colorScheme.mutedForeground),
          const SizedBox(height: 12),
          Text(
            hasError ? 'Cannot access directory' : 'Empty directory',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.mutedForeground,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              _loadError!,
              style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileList(BuildContext context, shad.ColorScheme colorScheme) {
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
    final colorScheme = shad.Theme.of(context).colorScheme;

    final icon = isDirectory
        ? LucideIcons.folder
        : _getFileIcon(name);
    final iconColor = isDirectory
        ? const Color(0xFFF59E0B)
        : isAllowed
            ? colorScheme.primary
            : colorScheme.mutedForeground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: shad.Button.ghost(
        onPressed: onTap,
        alignment: Alignment.centerLeft,
        enabled: isDirectory || isAllowed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    color: (isDirectory || isAllowed)
                        ? colorScheme.foreground
                        : colorScheme.mutedForeground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDirectory)
                Icon(LucideIcons.chevronRight, size: 16, color: colorScheme.mutedForeground),
            ],
          ),
        ),
      ),
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
