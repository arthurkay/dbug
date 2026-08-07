import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/models/history_entry.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/utils/method_colors.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(windowTitleProvider.notifier).state = 'History';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(historyProvider);

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
                    Text('History', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Recent requests and responses', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear History'),
                      content: const Text('Delete all history entries?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  await ref.read(historyRepositoryProvider).clearAll();
                  ref.invalidate(historyProvider);
                },
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, method, URL, or status...',
                    isDense: true,
                    prefixIcon: Icon(LucideIcons.search, size: 16),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: DbugSpinner()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }
                final filtered = _searchQuery.isEmpty
                    ? entries
                    : entries.where((e) {
                        final q = _searchQuery;
                        return (e.requestName ?? '').toLowerCase().contains(q) ||
                            e.method.toLowerCase().contains(q) ||
                            e.url.toLowerCase().contains(q) ||
                            (e.statusCode?.toString().contains(q) ?? false);
                      }).toList();
                if (filtered.isEmpty) {
                  return _buildNoResults(colorScheme);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Expanded(
                      child: Card(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            return _HistoryTile(
                              entry: entry,
                              onTap: () {
                                final collHeaders = <String, String>{};
                                try {
                                  final decoded = jsonDecode(entry.collectionHeaders);
                                  collHeaders.addAll(Map<String, String>.from(decoded));
                                } catch (e) { debugPrint('Failed to parse collection headers: $e'); }
                                context.go('/request', extra: {
                                  'historyEntry': entry,
                                  'collectionId': entry.collectionId,
                                  'collectionHeaders': collHeaders,
                                });
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Entry'),
                                    content: const Text('Remove this entry from history?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                await ref.read(historyRepositoryProvider).deleteEntry(entry.id);
                                ref.invalidate(historyProvider);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.history, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No history yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Send a request to see it here', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ColorScheme colorScheme) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No results found', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Try a different search term', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = entry.requestName ?? entry.url;

    final statusColor = entry.statusCode == null
        ? colorScheme.outline
        : entry.statusCode! >= 200 && entry.statusCode! < 300
            ? Colors.green
            : entry.statusCode! >= 400
                ? Colors.red
                : Colors.orange;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: methodColor(entry.method).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(entry.method, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: methodColor(entry.method)), textAlign: TextAlign.center),
      ),
      title: Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
      subtitle: Text(entry.url, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 1),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.statusCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${entry.statusCode}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          if (entry.responseTimeMs != null) ...[
            const SizedBox(width: 8),
            Text('${entry.responseTimeMs}ms', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 12),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
