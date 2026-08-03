import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import '../../../core/repositories/openapi_repository.dart';
import '../../../core/models/openapi_spec.dart';
import '../../../shared/widgets/file_explorer.dart';
import '../data/openapi_parser.dart';

class SpecImportScreen extends ConsumerStatefulWidget {
  const SpecImportScreen({super.key});

  @override
  ConsumerState<SpecImportScreen> createState() => _SpecImportScreenState();
}

class _SpecImportScreenState extends ConsumerState<SpecImportScreen> {
  int _importMode = 0;
  final _urlController = TextEditingController();
  final _pasteController = TextEditingController();
  bool _showFileExplorer = false;
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isImporting = false;
  List<OpenApiSpec> _importedSpecs = [];

  @override
  void initState() {
    super.initState();
    _loadSpecs();
  }

  Future<void> _loadSpecs() async {
    final specs = await OpenApiRepository.getAllSpecs();
    if (mounted) setState(() => _importedSpecs = specs);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'yaml', 'yml'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _selectedFilePath = result.files.single.path;
      });
      await _loadAndParseFile(result.files.single.path!);
    }
  }

  Future<void> _loadAndParseFile(String path) async {
    try {
      final file = File(path);
      final content = await file.readAsString();
      await _parseAndImport(content, sourceName: p.basename(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _parseAndImport(String content, {String sourceName = 'clipboard'}) async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final parsed = OpenApiParser.parse(content);
      if (parsed == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid OpenAPI spec in "$sourceName"'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      if (parsed.endpoints.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No endpoints found in "$sourceName"'),
              backgroundColor: const Color(0xFFF59E0B),
            ),
          );
        }
        return;
      }

      await OpenApiRepository.saveParsedSpec(parsed, sourceType: 'file');
      await _loadSpecs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${parsed.title ?? sourceName}" — ${parsed.endpoints.length} endpoints'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parse error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _deleteSpec(OpenApiSpec spec) async {
    await OpenApiRepository.deleteSpec(spec.id);
    await _loadSpecs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${spec.title ?? 'spec'}"')),
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
                      'OpenAPI Specs',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Import OpenAPI 3.x specifications to use as request collections',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isImporting)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              if (_showFileExplorer)
                shad.Button.ghost(
                  onPressed: () => setState(() => _showFileExplorer = false),
                  leading: const Icon(Icons.close, size: 16),
                  child: const Text('Close Explorer'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showFileExplorer)
            Expanded(
              child: FileExplorer(
                allowedExtensions: ['json', 'yaml', 'yml'],
                onFileSelected: (file) {
                  _loadAndParseFile(file.path);
                },
              ),
            )
          else ...[
            shad.Tabs(
              index: _importMode,
              onChanged: (i) => setState(() => _importMode = i),
              children: const [
                shad.TabItem(child: Text('From URL')),
                shad.TabItem(child: Text('Paste')),
                shad.TabItem(child: Text('From File')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(flex: 3, child: _buildImportContent(context, colorScheme)),
            const SizedBox(height: 12),
            Flexible(
              flex: 2,
              child: _buildImportedSpecs(context, colorScheme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportContent(BuildContext context, shad.ColorScheme colorScheme) {
    switch (_importMode) {
      case 0:
        return _buildUrlImport(context, colorScheme);
      case 1:
        return _buildPasteImport(context, colorScheme);
      case 2:
        return _buildFileImport(context, colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUrlImport(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import from URL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: shad.TextField(
                    controller: _urlController,
                    placeholder: const Text('https://api.example.com/openapi.json'),
                  ),
                ),
                const SizedBox(width: 8),
                shad.Button.primary(
                  onPressed: _isImporting ? null : () async {
                    if (_urlController.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fetching URL...')),
                      );
                      final messenger = ScaffoldMessenger.of(context);
                        try {
                          final client = HttpClient();
                          final request = await client.getUrl(Uri.parse(_urlController.text));
                          final response = await request.close();
                          final body = await response.transform(SystemEncoding().decoder).join();
                          client.close(force: false);
                          await _parseAndImport(body, sourceName: _urlController.text);
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to fetch: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                    }
                  },
                  child: const Text('Fetch & Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasteImport(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste Spec',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: shad.TextField(
                controller: _pasteController,
                placeholder: const Text('Paste OpenAPI JSON or YAML here...'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                shad.Button.primary(
                  onPressed: _isImporting ? null : () {
                    if (_pasteController.text.isNotEmpty) {
                      _parseAndImport(_pasteController.text);
                    }
                  },
                  child: const Text('Parse & Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileImport(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import from File',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedFileName != null
                  ? _buildSelectedFile(colorScheme)
                  : _buildFilePickerArea(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerArea(shad.ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.border,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file,
            size: 48,
            color: colorScheme.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a .json or .yaml file',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'OpenAPI 3.x specification file',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              shad.Button.primary(
                onPressed: _isImporting ? null : _pickFile,
                leading: const Icon(Icons.file_upload_outlined, size: 16),
                child: const Text('Browse Files'),
              ),
              const SizedBox(width: 8),
              shad.Button.outline(
                onPressed: () => setState(() => _showFileExplorer = true),
                leading: const Icon(Icons.folder_open, size: 16),
                child: const Text('File Explorer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFile(shad.ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.description, size: 20, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFileName!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.foreground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedFilePath!,
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
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() {
                  _selectedFileName = null;
                  _selectedFilePath = null;
                }),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            shad.Button.outline(
              onPressed: () => setState(() {
                _selectedFileName = null;
                _selectedFilePath = null;
              }),
              child: const Text('Choose Different File'),
            ),
            const SizedBox(width: 8),
            shad.Button.primary(
              onPressed: _isImporting ? null : () {
                if (_selectedFilePath != null) {
                  _loadAndParseFile(_selectedFilePath!);
                }
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportedSpecs(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Imported Specs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.foreground,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_importedSpecs.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _importedSpecs.isEmpty
                ? Center(
                    child: Text(
                      'No specs imported yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.mutedForeground,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _importedSpecs.length,
                    itemBuilder: (context, index) {
                      final spec = _importedSpecs[index];
                      return _SpecTile(
                        spec: spec,
                        onDelete: () => _deleteSpec(spec),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final OpenApiSpec spec;
  final VoidCallback onDelete;

  const _SpecTile({required this.spec, required this.onDelete});

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
              Icon(Icons.description, size: 16, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title ?? 'Untitled',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.foreground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${spec.endpoints.length} endpoints • ${spec.version ?? 'unknown'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.mutedForeground,
                      ),
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
