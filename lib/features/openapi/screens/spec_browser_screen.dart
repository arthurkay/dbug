import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;

import '../../../core/providers/repository_providers.dart';
import '../../../core/models/openapi_spec.dart';
import '../../../core/models/request_model.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/utils/method_colors.dart';

class SpecBrowserScreen extends ConsumerWidget {
  final String specId;

  const SpecBrowserScreen({super.key, required this.specId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final specAsync = ref.watch(allSpecsProvider);

    return specAsync.when(
      loading: () => const Center(child: DbugSpinner()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (specs) {
        final spec = specs.where((s) => s.id == specId).firstOrNull;
        if (spec == null) {
          return Center(child: Text('Spec not found', style: TextStyle(color: colorScheme.mutedForeground)));
        }
        return _SpecBrowserBody(spec: spec);
      },
    );
  }
}

class _SpecBrowserBody extends StatefulWidget {
  final OpenApiSpec spec;

  const _SpecBrowserBody({required this.spec});

  @override
  State<_SpecBrowserBody> createState() => _SpecBrowserBodyState();
}

class _SpecBrowserBodyState extends State<_SpecBrowserBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  OpenApiEndpoint? _selectedEndpoint;
  bool _docsMode = false;
  int _detailTab = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OpenApiEndpoint> get _filteredEndpoints {
    if (_searchQuery.isEmpty) return widget.spec.endpoints;
    final q = _searchQuery.toLowerCase();
    return widget.spec.endpoints.where((ep) =>
      ep.path.toLowerCase().contains(q) ||
      ep.method.toLowerCase().contains(q) ||
      (ep.summary?.toLowerCase().contains(q) ?? false) ||
      ep.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  Map<String, List<OpenApiEndpoint>> get _groupedEndpoints {
    final map = <String, List<OpenApiEndpoint>>{};
    for (final ep in _filteredEndpoints) {
      final tag = ep.tags.isNotEmpty ? ep.tags.first : 'Other';
      map.putIfAbsent(tag, () => []).add(ep);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final grouped = _groupedEndpoints;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              shad.IconButton.ghost(
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                onPressed: () => context.go('/openapi'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.spec.title ?? 'API Spec', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.foreground)),
                    Text('${widget.spec.version ?? ''} \u2022 ${widget.spec.endpoints.length} endpoints', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              shad.Button.ghost(
                onPressed: () => setState(() { _docsMode = false; _detailTab = 0; }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.code, size: 14, color: !_docsMode ? colorScheme.primary : colorScheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text('API', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !_docsMode ? colorScheme.primary : colorScheme.mutedForeground)),
                  ],
                ),
              ),
              shad.Button.ghost(
                onPressed: () => setState(() { _docsMode = true; _detailTab = 0; }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.bookOpen, size: 14, color: _docsMode ? colorScheme.primary : colorScheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text('Docs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _docsMode ? colorScheme.primary : colorScheme.mutedForeground)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          shad.TextField(
            controller: _searchController,
            placeholder: const Text('Search endpoints...'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: shad.Card(
                    child: grouped.isEmpty
                        ? Center(child: Text('No endpoints found', style: TextStyle(color: colorScheme.mutedForeground)))
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            children: grouped.entries.expand((entry) {
                              return [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                                  child: Text(entry.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.mutedForeground, letterSpacing: 0.5)),
                                ),
                                ...entry.value.map((ep) => _EndpointTile(
                                  endpoint: ep,
                                  isSelected: _selectedEndpoint == ep,
                                  onTap: () => setState(() { _selectedEndpoint = ep; _detailTab = 0; }),
                                )),
                              ];
                            }).toList(),
                          ),
                  ),
                ),
                if (_selectedEndpoint != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _docsMode
                        ? _EndpointDocDetail(
                            endpoint: _selectedEndpoint!,
                            baseUrl: widget.spec.baseUrl ?? '',
                            rawContent: widget.spec.rawContent,
                            detailTab: _detailTab,
                            onTabChanged: (i) => setState(() => _detailTab = i),
                          )
                        : _EndpointApiDetail(
                            endpoint: _selectedEndpoint!,
                            baseUrl: widget.spec.baseUrl ?? '',
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  final OpenApiEndpoint endpoint;
  final bool isSelected;
  final VoidCallback onTap;

  const _EndpointTile({required this.endpoint, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: methodColor(endpoint.method).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(endpoint.method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: methodColor(endpoint.method)), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(endpoint.path, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  if (endpoint.summary != null)
                    Text(endpoint.summary!, style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndpointApiDetail extends ConsumerWidget {
  final OpenApiEndpoint endpoint;
  final String baseUrl;

  const _EndpointApiDetail({required this.endpoint, required this.baseUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = shad.Theme.of(context).colorScheme;

    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: methodColor(endpoint.method).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(endpoint.method, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: methodColor(endpoint.method))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(endpoint.path, style: const TextStyle(fontSize: 13, fontFamily: 'monospace'))),
              ],
            ),
            if (endpoint.summary != null) ...[
              const SizedBox(height: 8),
              Text(endpoint.summary!, style: TextStyle(fontSize: 13, color: colorScheme.foreground)),
            ],
            if (endpoint.description != null) ...[
              const SizedBox(height: 4),
              Text(endpoint.description!, style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
            ],
            if (endpoint.parameters.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Parameters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
              const SizedBox(height: 6),
              ...endpoint.parameters.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(p.location, style: TextStyle(fontSize: 9, color: colorScheme.mutedForeground)),
                    ),
                    const SizedBox(width: 6),
                    Text(p.name, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                    if (p.required) ...[
                      const SizedBox(width: 4),
                      Text('*', style: TextStyle(fontSize: 12, color: colorScheme.destructive)),
                    ],
                    if (p.type != null) ...[
                      const SizedBox(width: 6),
                      Text(p.type!, style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground)),
                    ],
                  ],
                ),
              )),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: shad.Button.primary(
                    onPressed: () {
                      final path = endpoint.path.startsWith('/') ? endpoint.path : '/${endpoint.path}';
                      final url = baseUrl.endsWith('/') ? '$baseUrl$path'.substring(1) : '$baseUrl$path';
                      final req = RequestModel(
                        id: '', name: endpoint.summary ?? '${endpoint.method} ${endpoint.path}',
                        method: endpoint.method, url: url,
                        createdAt: DateTime.now(), updatedAt: DateTime.now(),
                      );
                      context.go('/request', extra: req);
                    },
                    leading: const Icon(LucideIcons.send, size: 14),
                    child: const Text('Send'),
                  ),
                ),
                const SizedBox(width: 8),
                shad.Button.outline(
                  onPressed: () async {
                    final requestRepo = ref.read(requestRepositoryProvider);
                    final collections = await ref.read(collectionRepositoryProvider).getAllCollections();
                    final collection = collections.isNotEmpty ? collections.first : null;
                    if (collection == null) return;

                    await requestRepo.createRequest(
                      collectionId: collection.id,
                      name: endpoint.summary ?? '${endpoint.method} ${endpoint.path}',
                      method: endpoint.method,
                      url: baseUrl.endsWith('/') ? '$baseUrl${endpoint.path}'.substring(1) : '$baseUrl${endpoint.path}',
                    );
                    ref.invalidate(collectionsProvider);
                    if (context.mounted) {
                      showDbugToast(context, message: 'Saved to ${collection.name}', type: ToastType.success);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EndpointDocDetail extends StatelessWidget {
  final OpenApiEndpoint endpoint;
  final String baseUrl;
  final String rawContent;
  final int detailTab;
  final ValueChanged<int> onTabChanged;

  const _EndpointDocDetail({
    required this.endpoint,
    required this.baseUrl,
    required this.rawContent,
    required this.detailTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;

    return shad.Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: methodColor(endpoint.method).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(endpoint.method, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: methodColor(endpoint.method))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(endpoint.path, style: const TextStyle(fontSize: 13, fontFamily: 'monospace'))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: shad.Tabs(
              index: detailTab,
              onChanged: onTabChanged,
              children: const [
                shad.TabItem(child: Text('Documentation')),
                shad.TabItem(child: Text('Raw Spec')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: detailTab == 0
                ? _buildDocumentation(colorScheme)
                : _buildRawSpec(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentation(shad.ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (endpoint.summary != null) ...[
            Text(endpoint.summary!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const SizedBox(height: 4),
          ],
          if (endpoint.description != null) ...[
            Text(endpoint.description!, style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
            const SizedBox(height: 16),
          ],
          if (endpoint.parameters.isNotEmpty) ...[
            _buildSectionHeader('Parameters', colorScheme),
            const SizedBox(height: 8),
            ...endpoint.parameters.map((p) => _buildParameterTile(p, colorScheme)),
            const SizedBox(height: 16),
          ],
          if (endpoint.requestBodySchema != null) ...[
            _buildSectionHeader('Request Body', colorScheme),
            const SizedBox(height: 8),
            _SchemaView(schema: endpoint.requestBodySchema!),
            const SizedBox(height: 16),
          ],
          if (endpoint.responseSchemas != null && endpoint.responseSchemas!.isNotEmpty) ...[
            _buildSectionHeader('Responses', colorScheme),
            const SizedBox(height: 8),
            ...endpoint.responseSchemas!.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(e.key, colorScheme).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(e.key, colorScheme))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _SchemaView(schema: e.value),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRawSpec(shad.ColorScheme colorScheme) {
    final lines = rawContent.split('\n');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colorScheme.border.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.fileText, size: 14, color: colorScheme.mutedForeground),
                  const SizedBox(width: 6),
                  Text('Raw Spec Content', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
                  const Spacer(),
                  Text('${lines.length} lines', style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text.rich(TextSpan(
                children: [
                  for (var i = 0; i < lines.length; i++) ...[
                    TextSpan(
                      text: '${(i + 1).toString().padLeft(4)}  ',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.mutedForeground.withValues(alpha: 0.5)),
                    ),
                    TextSpan(
                      text: '${lines[i]}\n',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.foreground),
                    ),
                  ],
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, shad.ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.foreground, letterSpacing: 0.3)),
    );
  }

  Widget _buildParameterTile(OpenApiParameter p, shad.ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: colorScheme.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(p.location, style: TextStyle(fontSize: 9, color: colorScheme.mutedForeground)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                    if (p.required) ...[
                      const SizedBox(width: 4),
                      Text('*', style: TextStyle(fontSize: 12, color: colorScheme.destructive)),
                    ],
                    if (p.type != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(p.type!, style: TextStyle(fontSize: 9, color: colorScheme.primary)),
                      ),
                    ],
                  ],
                ),
                if (p.description != null) ...[
                  const SizedBox(height: 2),
                  Text(p.description!, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String code, shad.ColorScheme colorScheme) {
    final c = int.tryParse(code) ?? 0;
    if (c >= 200 && c < 300) return const Color(0xFF22C55E);
    if (c >= 300 && c < 400) return const Color(0xFFF59E0B);
    if (c >= 400) return const Color(0xFFEF4444);
    return colorScheme.mutedForeground;
  }
}

class _SchemaView extends StatelessWidget {
  final OpenApiSchema schema;
  final int depth;

  const _SchemaView({required this.schema, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          left: depth > 0 ? BorderSide(color: colorScheme.border.withValues(alpha: 0.5), width: 2) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTypeBadge(schema, colorScheme),
          if (schema.description != null) ...[
            const SizedBox(height: 4),
            Text(schema.description!, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
          ],
          if (schema.requiredFields.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Text('required:', style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground)),
                ...schema.requiredFields.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.destructive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(f, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.destructive)),
                )),
              ],
            ),
          ],
          if (schema.enumValues.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Text('enum:', style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground)),
                ...schema.enumValues.map((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(v, style: TextStyle(fontSize: 10, color: colorScheme.primary)),
                )),
              ],
            ),
          ],
          if (schema.properties.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...schema.properties.entries.map((e) => _buildPropertyRow(e.key, e.value, schema.requiredFields.contains(e.key), colorScheme)),
          ],
          if (schema.items != null) ...[
            const SizedBox(height: 8),
            Text('items:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.mutedForeground)),
            const SizedBox(height: 4),
            _SchemaView(schema: schema.items!, depth: depth + 1),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(OpenApiSchema schema, shad.ColorScheme colorScheme) {
    final parts = <String>[];
    if (schema.ref != null) {
      parts.add(schema.ref!.split('/').last);
    }
    if (schema.type != null) {
      parts.add(schema.type!);
    }
    if (schema.format != null) {
      parts.add('(${schema.format})');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    final label = parts.join(' ');
    final isRef = schema.ref != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRef
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        color: isRef ? colorScheme.primary : colorScheme.foreground,
      )),
    );
  }

  Widget _buildPropertyRow(String name, OpenApiSchema prop, bool isRequired, shad.ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Text('\u2022 ', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
          Text(name, style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w500, color: colorScheme.foreground)),
          if (isRequired) ...[
            const SizedBox(width: 4),
            Text('*', style: TextStyle(fontSize: 12, color: colorScheme.destructive)),
          ],
          const SizedBox(width: 8),
          if (prop.type != null || prop.ref != null)
            _SchemaView(schema: prop, depth: depth + 1),
        ],
      ),
    );
  }
}
