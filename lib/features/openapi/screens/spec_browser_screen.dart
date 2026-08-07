import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/window_title_provider.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final specAsync = ref.watch(allSpecsProvider);

    return specAsync.when(
      loading: () => const Center(child: DbugSpinner()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (specs) {
        final spec = specs.where((s) => s.id == specId).firstOrNull;
        if (spec == null) {
          return Center(child: Text('Spec not found', style: TextStyle(color: colorScheme.outline)));
        }
        return _SpecBrowserBody(spec: spec);
      },
    );
  }
}

class _SpecBrowserBody extends ConsumerStatefulWidget {
  final OpenApiSpec spec;
  const _SpecBrowserBody({required this.spec});
  @override
  ConsumerState<_SpecBrowserBody> createState() => _SpecBrowserBodyState();
}

class _SpecBrowserBodyState extends ConsumerState<_SpecBrowserBody> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  OpenApiEndpoint? _selectedEndpoint;
  bool _docsMode = false;
  late TabController _detailTabController;

  @override
  void initState() {
    super.initState();
    _detailTabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(windowTitleProvider.notifier).state = widget.spec.title ?? 'OpenAPI Spec';
    });
  }

  @override
  void dispose() {
    _detailTabController.dispose();
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
      (ep.description?.toLowerCase().contains(q) ?? false) ||
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
    final colorScheme = Theme.of(context).colorScheme;
    final grouped = _groupedEndpoints;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                onPressed: () => context.go('/openapi'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.spec.title ?? 'API Spec', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    Text('${widget.spec.version ?? ''} \u2022 ${widget.spec.endpoints.length} endpoints \u2022 ${widget.spec.baseUrl ?? ''}', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() { _docsMode = false; _detailTabController.index = 0; }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.code, size: 14, color: !_docsMode ? colorScheme.primary : colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('API', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: !_docsMode ? colorScheme.primary : colorScheme.outline)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() { _docsMode = true; _detailTabController.index = 0; }),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.bookOpen, size: 14, color: _docsMode ? colorScheme.primary : colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('Docs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _docsMode ? colorScheme.primary : colorScheme.outline)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Search endpoints by name, path, method, or description...', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(LucideIcons.search, size: 16)),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: Card(
                    child: grouped.isEmpty
                        ? Center(child: Text('No endpoints found', style: TextStyle(color: colorScheme.outline)))
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            children: grouped.entries.expand((entry) {
                              return [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                                  child: Text(entry.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colorScheme.outline, letterSpacing: 0.5)),
                                ),
                                ...entry.value.map((ep) => _EndpointTile(
                                  endpoint: ep,
                                  isSelected: _selectedEndpoint == ep,
                                  onTap: () => setState(() {
                                    _selectedEndpoint = ep;
                                    _detailTabController.index = 0;
                                    ref.read(windowTitleProvider.notifier).state = '${ep.method} ${ep.path}';
                                  }),
                                )),
                              ];
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectedEndpoint != null
                      ? _docsMode
                          ? _EndpointDocDetail(
                              endpoint: _selectedEndpoint!,
                              baseUrl: widget.spec.baseUrl ?? '',
                              rawContent: widget.spec.rawContent,
                              tabController: _detailTabController,
                            )
                          : _EndpointApiDetail(
                              endpoint: _selectedEndpoint!,
                              baseUrl: widget.spec.baseUrl ?? '',
                            )
                      : Card(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.mousePointerClick, size: 32, color: colorScheme.outline),
                                const SizedBox(height: 8),
                                Text('Select an endpoint', style: TextStyle(color: colorScheme.outline)),
                              ],
                            ),
                          ),
                        ),
                ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final paramCount = endpoint.parameters.length;
    final hasBody = endpoint.requestBodySchema != null;
    final responseCount = endpoint.responseSchemas?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected ? colorScheme.surfaceContainerHighest : null,
        child: Row(
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: methodColor(endpoint.method).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(endpoint.method, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: methodColor(endpoint.method)), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(endpoint.path, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                  if (endpoint.summary != null)
                    Text(endpoint.summary!, style: TextStyle(fontSize: 10, color: colorScheme.outline), overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (paramCount > 0)
                  _countBadge('$paramCount', LucideIcons.listFilter, colorScheme),
                if (hasBody)
                  _countBadge('body', LucideIcons.fileJson, colorScheme),
                if (responseCount > 0)
                  _countBadge('$responseCount', LucideIcons.arrowDownToLine, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(String label, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 8, color: colorScheme.outline),
            const SizedBox(width: 2),
            Text(label, style: TextStyle(fontSize: 8, color: colorScheme.outline)),
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
    final colorScheme = Theme.of(context).colorScheme;
    final fullUrl = _buildFullUrl();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: methodColor(endpoint.method).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(endpoint.method, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: methodColor(endpoint.method))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(endpoint.path, style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w500))),
              ],
            ),
            if (fullUrl.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fullUrl, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.outline), overflow: TextOverflow.ellipsis),
              ),
            ],
            if (endpoint.summary != null || endpoint.description != null) ...[
              const SizedBox(height: 12),
              if (endpoint.summary != null)
                Text(endpoint.summary!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              if (endpoint.description != null) ...[
                const SizedBox(height: 4),
                Text(endpoint.description!, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
              ],
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (endpoint.parameters.isNotEmpty) ...[
                    _SectionHeader(title: 'Parameters', count: endpoint.parameters.length, icon: LucideIcons.listFilter),
                    const SizedBox(height: 8),
                    _buildParametersTable(endpoint.parameters, colorScheme),
                    const SizedBox(height: 16),
                  ],
                  if (endpoint.requestBodySchema != null) ...[
                    _SectionHeader(title: 'Request Body', icon: LucideIcons.fileJson),
                    const SizedBox(height: 8),
                    _SchemaCard(schema: endpoint.requestBodySchema!),
                    const SizedBox(height: 16),
                  ],
                  if (endpoint.responseSchemas != null && endpoint.responseSchemas!.isNotEmpty) ...[
                    _SectionHeader(title: 'Responses', count: endpoint.responseSchemas!.length, icon: LucideIcons.arrowDownToLine),
                    const SizedBox(height: 8),
                    ...endpoint.responseSchemas!.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ResponseCard(statusCode: e.key, schema: e.value),
                    )),
                  ],
                  if (endpoint.parameters.isEmpty && endpoint.requestBodySchema == null && (endpoint.responseSchemas == null || endpoint.responseSchemas!.isEmpty))
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No schema information available', style: TextStyle(color: colorScheme.outline)),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final url = _buildFullUrl();
                      final req = RequestModel(
                        id: '', name: endpoint.summary ?? '${endpoint.method} ${endpoint.path}',
                        method: endpoint.method, url: url,
                        createdAt: DateTime.now(), updatedAt: DateTime.now(),
                      );
                      context.go('/request', extra: req);
                    },
                    icon: const Icon(LucideIcons.send, size: 14),
                    label: const Text('Send'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final requestRepo = ref.read(requestRepositoryProvider);
                    final collections = await ref.read(collectionRepositoryProvider).getAllCollections();
                    final collection = collections.isNotEmpty ? collections.first : null;
                    if (collection == null) return;
                    await requestRepo.createRequest(
                      collectionId: collection.id,
                      name: endpoint.summary ?? '${endpoint.method} ${endpoint.path}',
                      method: endpoint.method,
                      url: _buildFullUrl(),
                    );
                    ref.invalidate(collectionsProvider);
                    if (context.mounted) showDbugToast(context, message: 'Saved to ${collection.name}', type: ToastType.success);
                  },
                  icon: const Icon(LucideIcons.save, size: 14),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildFullUrl() {
    if (baseUrl.isEmpty) return endpoint.path;
    final path = endpoint.path.startsWith('/') ? endpoint.path : '/${endpoint.path}';
    return baseUrl.endsWith('/') ? '${baseUrl.substring(0, baseUrl.length - 1)}$path' : '$baseUrl$path';
  }

  Widget _buildParametersTable(List<OpenApiParameter> params, ColorScheme colorScheme) {
    final queryParams = params.where((p) => p.location == 'query');
    final pathParams = params.where((p) => p.location == 'path');
    final headerParams = params.where((p) => p.location == 'header');
    final cookieParams = params.where((p) => p.location == 'cookie');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pathParams.isNotEmpty) ...[
          _paramGroupLabel('Path', colorScheme),
          const SizedBox(height: 4),
          ...pathParams.map((p) => _ParameterRow(param: p, colorScheme: colorScheme)),
          const SizedBox(height: 10),
        ],
        if (queryParams.isNotEmpty) ...[
          _paramGroupLabel('Query', colorScheme),
          const SizedBox(height: 4),
          ...queryParams.map((p) => _ParameterRow(param: p, colorScheme: colorScheme)),
          const SizedBox(height: 10),
        ],
        if (headerParams.isNotEmpty) ...[
          _paramGroupLabel('Header', colorScheme),
          const SizedBox(height: 4),
          ...headerParams.map((p) => _ParameterRow(param: p, colorScheme: colorScheme)),
          const SizedBox(height: 10),
        ],
        if (cookieParams.isNotEmpty) ...[
          _paramGroupLabel('Cookie', colorScheme),
          const SizedBox(height: 4),
          ...cookieParams.map((p) => _ParameterRow(param: p, colorScheme: colorScheme)),
        ],
      ],
    );
  }

  Widget _paramGroupLabel(String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colorScheme.outline, letterSpacing: 0.5)),
    );
  }
}

class _ParameterRow extends StatelessWidget {
  final OpenApiParameter param;
  final ColorScheme colorScheme;
  const _ParameterRow({required this.param, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(param.name, style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                    if (param.required) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
                        child: Text('required', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: colorScheme.error)),
                      ),
                    ],
                  ],
                ),
                if (param.description != null) ...[
                  const SizedBox(height: 2),
                  Text(param.description!, style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (param.type != null || param.schemaType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(3)),
              child: Text(param.type ?? param.schemaType!, style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: colorScheme.outline)),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final IconData icon;
  const _SectionHeader({required this.title, this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.outline),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface, letterSpacing: 0.3)),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.outline)),
          ),
        ],
      ],
    );
  }
}

class _SchemaCard extends StatelessWidget {
  final OpenApiSchema schema;
  const _SchemaCard({required this.schema});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: _SchemaView(schema: schema),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final String statusCode;
  final OpenApiSchema schema;
  const _ResponseCard({required this.statusCode, required this.schema});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = int.tryParse(statusCode) ?? 0;
    final statusColor = c >= 200 && c < 300
        ? const Color(0xFF22C55E)
        : c >= 300 && c < 400
            ? const Color(0xFFF59E0B)
            : c >= 400
                ? const Color(0xFFEF4444)
                : colorScheme.outline;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                  child: Text(statusCode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                ),
                const SizedBox(width: 8),
                Text(_statusText(c), style: TextStyle(fontSize: 12, color: colorScheme.outline)),
              ],
            ),
          ),
          if (schema.type != null || schema.properties.isNotEmpty || schema.ref != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: _SchemaView(schema: schema),
            ),
        ],
      ),
    );
  }

  String _statusText(int code) {
    switch (code) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 204: return 'No Content';
      case 301: return 'Moved Permanently';
      case 302: return 'Found';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 500: return 'Internal Server Error';
      default: return '';
    }
  }
}

class _EndpointDocDetail extends StatelessWidget {
  final OpenApiEndpoint endpoint;
  final String baseUrl;
  final String rawContent;
  final TabController tabController;
  const _EndpointDocDetail({required this.endpoint, required this.baseUrl, required this.rawContent, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: methodColor(endpoint.method).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(endpoint.method, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: methodColor(endpoint.method))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(endpoint.path, style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [Tab(text: 'Documentation'), Tab(text: 'Raw Spec')],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: tabController,
              builder: (context, _) => tabController.index == 0 ? _buildDocumentation(colorScheme) : _buildRawSpec(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentation(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (endpoint.summary != null) ...[
            Text(endpoint.summary!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 4),
          ],
          if (endpoint.description != null) ...[
            Text(endpoint.description!, style: TextStyle(fontSize: 13, color: colorScheme.outline)),
            const SizedBox(height: 16),
          ],
          if (endpoint.parameters.isNotEmpty) ...[
            _SectionHeader(title: 'Parameters', count: endpoint.parameters.length, icon: LucideIcons.listFilter),
            const SizedBox(height: 8),
            ...endpoint.parameters.map((p) => _buildParameterTile(p, colorScheme)),
            const SizedBox(height: 16),
          ],
          if (endpoint.requestBodySchema != null) ...[
            _SectionHeader(title: 'Request Body', icon: LucideIcons.fileJson),
            const SizedBox(height: 8),
            _SchemaCard(schema: endpoint.requestBodySchema!),
            const SizedBox(height: 16),
          ],
          if (endpoint.responseSchemas != null && endpoint.responseSchemas!.isNotEmpty) ...[
            _SectionHeader(title: 'Responses', count: endpoint.responseSchemas!.length, icon: LucideIcons.arrowDownToLine),
            const SizedBox(height: 8),
            ...endpoint.responseSchemas!.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ResponseCard(statusCode: e.key, schema: e.value),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildRawSpec(ColorScheme colorScheme) {
    final lines = rawContent.split('\n');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)))),
              child: Row(
                children: [
                  Icon(LucideIcons.fileText, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 6),
                  Text('Raw Spec Content', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const Spacer(),
                  Text('${lines.length} lines', style: TextStyle(fontSize: 10, color: colorScheme.outline)),
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
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.outline.withValues(alpha: 0.5)),
                    ),
                    TextSpan(
                      text: '${lines[i]}\n',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurface),
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

  Widget _buildParameterTile(OpenApiParameter p, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3)),
            child: Text(p.location, style: TextStyle(fontSize: 9, color: colorScheme.outline)),
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
                      Text('*', style: TextStyle(fontSize: 12, color: colorScheme.error)),
                    ],
                    if (p.type != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(3)),
                        child: Text(p.type!, style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: colorScheme.outline)),
                      ),
                    ],
                  ],
                ),
                if (p.description != null) ...[
                  const SizedBox(height: 2),
                  Text(p.description!, style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemaView extends StatelessWidget {
  final OpenApiSchema schema;
  final int depth;
  const _SchemaView({required this.schema, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
      padding: depth > 0 ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: depth > 0
          ? BoxDecoration(
              border: Border(left: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4), width: 2)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTypeBadge(schema, colorScheme),
          if (schema.description != null) ...[
            const SizedBox(height: 4),
            Text(schema.description!, style: TextStyle(fontSize: 11, color: colorScheme.outline)),
          ],
          if (schema.requiredFields.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Text('required:', style: TextStyle(fontSize: 10, color: colorScheme.outline)),
                ...schema.requiredFields.map((f) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: colorScheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(3)),
                  child: Text(f, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.error)),
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
                Text('enum:', style: TextStyle(fontSize: 10, color: colorScheme.outline)),
                ...schema.enumValues.map((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(3)),
                  child: Text(v, style: TextStyle(fontSize: 10, color: colorScheme.outline)),
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
            Text('items:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.outline)),
            const SizedBox(height: 4),
            _SchemaView(schema: schema.items!, depth: depth + 1),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(OpenApiSchema schema, ColorScheme colorScheme) {
    final parts = <String>[];
    if (schema.ref != null) parts.add(schema.ref!.split('/').last);
    if (schema.type != null) parts.add(schema.type!);
    if (schema.format != null) parts.add('(${schema.format})');
    if (parts.isEmpty) return const SizedBox.shrink();

    final label = parts.join(' ');
    final isRef = schema.ref != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRef ? colorScheme.primary.withValues(alpha: 0.08) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: isRef ? colorScheme.primary : colorScheme.onSurface)),
    );
  }

  Widget _buildPropertyRow(String name, OpenApiSchema prop, bool isRequired, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Text('\u2022 ', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
          Text(name, style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
          if (isRequired) ...[
            const SizedBox(width: 4),
            Text('*', style: TextStyle(fontSize: 12, color: colorScheme.error)),
          ],
          const SizedBox(width: 8),
          if (prop.type != null || prop.ref != null)
            _SchemaView(schema: prop, depth: depth + 1),
        ],
      ),
    );
  }
}
