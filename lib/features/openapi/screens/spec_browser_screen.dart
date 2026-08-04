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
                    Text('${widget.spec.version ?? ''} • ${widget.spec.endpoints.length} endpoints', style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
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
                                  onTap: () => setState(() => _selectedEndpoint = ep),
                                  onSend: (context) {
                                    final base = widget.spec.baseUrl ?? '';
                                    final path = ep.path.startsWith('/') ? ep.path : '/${ep.path}';
                                    final url = base.endsWith('/') ? '$base$path'.substring(1) : '$base$path';
                                    final req = RequestModel(
                                      id: '', name: ep.summary ?? '${ep.method} ${ep.path}',
                                      method: ep.method, url: url,
                                      createdAt: DateTime.now(), updatedAt: DateTime.now(),
                                    );
                                    context.go('/request', extra: req);
                                  },
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
                    child: _EndpointDetail(
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
  final void Function(BuildContext context) onSend;

  const _EndpointTile({required this.endpoint, required this.isSelected, required this.onTap, required this.onSend});

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

class _EndpointDetail extends ConsumerWidget {
  final OpenApiEndpoint endpoint;
  final String baseUrl;

  const _EndpointDetail({required this.endpoint, required this.baseUrl});

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
