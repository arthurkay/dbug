import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/utils/syntax_highlighter.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/http_client_provider.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/repositories/openapi_repository.dart';
import '../../../shared/widgets/file_explorer.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../data/openapi_parser.dart';

class SpecImportScreen extends ConsumerStatefulWidget {
  const SpecImportScreen({super.key});

  @override
  ConsumerState<SpecImportScreen> createState() => _SpecImportScreenState();
}

class _SpecImportScreenState extends ConsumerState<SpecImportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _pasteController = TextEditingController();
  bool _showFileExplorer = false;
  String? _selectedFileName;
  String? _selectedFilePath;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(windowTitleProvider.notifier).state = 'OpenAPI Specs';
    });
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      await _parseAndImport(content, sourceName: p.basename(path), sourceType: 'file');
    } catch (e) {
      if (mounted) {
        showDbugToast(context, message: 'Failed to read file: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _parseAndImport(String content, {String sourceName = 'clipboard', String sourceType = 'paste', String? sourceUrl}) async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      final ParsedSpec parsed;
      try {
        parsed = OpenApiParser.parseOrThrow(content);
      } on FormatException catch (e) {
        if (mounted) {
          showDbugToast(context, message: 'Can\'t import "$sourceName": ${e.message}', type: ToastType.error);
        }
        return;
      }

      if (parsed.endpoints.isEmpty) {
        if (mounted) {
          showDbugToast(context, message: 'No endpoints found in "$sourceName"', type: ToastType.warning);
        }
        return;
      }

      await ref.read(openApiRepositoryProvider).saveParsedSpec(parsed, sourceType: sourceType, sourceUrl: sourceUrl);
      ref.invalidate(specSummariesProvider);
      ref.invalidate(collectionsProvider);
      ref.invalidate(environmentsProvider);

      if (mounted) {
        showDbugToast(context, message: 'Imported "${parsed.title ?? sourceName}" — ${parsed.endpoints.length} endpoints', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        showDbugToast(context, message: 'Parse error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final specsAsync = ref.watch(specSummariesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: PageHeader(title: 'OpenAPI Specs', subtitle: 'Import OpenAPI 3.x or Swagger 2.0 specs as request collections')),
              if (_isImporting)
                const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 16, height: 16, child: DbugSpinner(strokeWidth: 2))),
              if (_showFileExplorer)
                TextButton.icon(onPressed: () => setState(() => _showFileExplorer = false), icon: const Icon(LucideIcons.x, size: 16), label: const Text('Close Explorer')),
            ],
          ),
          const SizedBox(height: 16),
          if (_showFileExplorer)
            Expanded(
              child: FileExplorer(
                allowedExtensions: ['json', 'yaml', 'yml'],
                onFileSelected: (file) => _loadAndParseFile(file.path),
              ),
            )
          else ...[
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'From URL'),
                Tab(text: 'Paste'),
                Tab(text: 'From File'),
              ],
            ),
            const SizedBox(height: 16),
            // The URL form is a single row, so it takes only the height it
            // needs; paste/file get a fixed area. The spec list gets the rest.
            if (_tabController.index == 0)
              _buildImportContent(colorScheme)
            else
              SizedBox(height: 280, child: _buildImportContent(colorScheme)),
            const SizedBox(height: 16),
            Expanded(child: _buildImportedSpecs(colorScheme, specsAsync)),
          ],
        ],
      ),
    );
  }

  Widget _buildImportContent(ColorScheme colorScheme) {
    switch (_tabController.index) {
      case 0: return _buildUrlImport(colorScheme);
      case 1: return _buildPasteImport(colorScheme);
      case 2: return _buildFileImport(colorScheme);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildUrlImport(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import from URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _urlController, decoration: const InputDecoration(hintText: 'https://api.example.com/openapi.json'))),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isImporting ? null : () async {
                    if (_urlController.text.isNotEmpty) {
                      try {
                        final dio = ref.read(httpClientProvider).dio;
                        final response = await dio.get(
                          _urlController.text,
                          options: Options(responseType: ResponseType.plain),
                        );
                        final body = response.data?.toString() ?? '';
                        await _parseAndImport(body, sourceName: _urlController.text, sourceType: 'url', sourceUrl: _urlController.text);
                      } catch (e) {
                        if (mounted) {
                          showDbugToast(context, message: 'Failed to fetch: $e', type: ToastType.error);
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

  Widget _buildPasteImport(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste Spec', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Expanded(child: TextField(controller: _pasteController, decoration: const InputDecoration(hintText: 'Paste OpenAPI JSON or YAML here...'), style: TextStyle(fontFamily: codeFontFamily, fontSize: 13), maxLines: null, expands: true)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: _isImporting ? null : () { if (_pasteController.text.isNotEmpty) _parseAndImport(_pasteController.text); },
                  child: const Text('Parse & Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileImport(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import from File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Expanded(
              child: _selectedFileName != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(LucideIcons.fileText, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selectedFileName!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface), overflow: TextOverflow.ellipsis),
                                    Text(_selectedFilePath!, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(LucideIcons.x, size: 16), onPressed: () => setState(() { _selectedFileName = null; _selectedFilePath = null; })),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(onPressed: () => setState(() { _selectedFileName = null; _selectedFilePath = null; }), child: const Text('Choose Different File')),
                            const SizedBox(width: 8),
                            FilledButton(onPressed: _isImporting ? null : () { if (_selectedFilePath != null) _loadAndParseFile(_selectedFilePath!); }, child: const Text('Import')),
                          ],
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.upload, size: 48, color: colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('Select a .json or .yaml file', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text('OpenAPI 3.x specification file', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.icon(onPressed: _isImporting ? null : _pickFile, icon: const Icon(LucideIcons.upload, size: 16), label: const Text('Browse Files')),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(onPressed: () => setState(() => _showFileExplorer = true), icon: const Icon(LucideIcons.folderOpen, size: 16), label: const Text('File Explorer')),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportedSpecs(ColorScheme colorScheme, AsyncValue<List<OpenApiSpecSummary>> specsAsync) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Imported Specs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                const Spacer(),
                specsAsync.whenData((specs) => Text('${specs.length}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))).when(skipLoadingOnRefresh: false, skipLoadingOnReload: false, data: (w) => w, error: (_, _) => const SizedBox.shrink(), loading: () => const SizedBox.shrink()),
              ],
            ),
          ),
          Container(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          Expanded(
            child: specsAsync.when(
              loading: () => const Center(child: DbugSpinner()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (specs) {
                if (specs.isEmpty) {
                  return Center(child: Text('No specs imported yet', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: specs.length,
                  itemBuilder: (context, index) {
                    final spec = specs[index];
                    return _SpecTile(
                      spec: spec,
                      onTap: () => context.go('/openapi/${spec.id}'),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Spec'),
                            content: Text('Delete "${spec.title ?? 'Untitled'}"? Its generated collection, requests and environment are deleted too.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        final repo = ref.read(openApiRepositoryProvider);
                        final collectionId = await repo.getCollectionForSpec(spec.id);
                        await repo.deleteSpec(spec.id);
                        ref.invalidate(specSummariesProvider);
                        ref.invalidate(specByIdProvider(spec.id));
                        ref.invalidate(collectionForSpecProvider(spec.id));
                        ref.invalidate(collectionsProvider);
                        if (collectionId != null) {
                          ref.invalidate(collectionByIdProvider(collectionId));
                          ref.invalidate(requestsByCollectionProvider(collectionId));
                        }
                        // Its environment is gone too; the active environment
                        // is derived from this list, so it clears itself.
                        ref.invalidate(environmentsProvider);
                      },
                    );
                  },
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
  final OpenApiSpecSummary spec;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SpecTile({required this.spec, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(LucideIcons.fileText, size: 16, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.title ?? 'Untitled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface), overflow: TextOverflow.ellipsis),
                  Text('${spec.endpointCount} endpoints • ${spec.version ?? 'unknown'}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(icon: const Icon(LucideIcons.trash2, size: 14), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
