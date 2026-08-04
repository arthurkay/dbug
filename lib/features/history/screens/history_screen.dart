import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' show showDialog;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;

import '../../../core/providers/repository_providers.dart';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;
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
                    Text('History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.foreground)),
                    const SizedBox(height: 4),
                    Text('Recent requests and responses', style: TextStyle(fontSize: 13, color: colorScheme.mutedForeground)),
                  ],
                ),
              ),
              shad.Button.outline(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => shad.AlertDialog(
                      title: const Text('Clear History'),
                      content: const Text('Delete all history entries?'),
                      actions: [
                        shad.Button.ghost(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        shad.Button.primary(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  await ref.read(historyRepositoryProvider).clearAll();
                  ref.invalidate(historyProvider);
                },
                leading: const Icon(LucideIcons.trash2, size: 16),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: shad.TextField(
                  controller: _searchController,
                  placeholder: const Text('Search by name, method, URL, or status...'),
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                shad.IconButton.ghost(
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
                          style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground),
                        ),
                      ),
                    Expanded(
                      child: shad.Card(
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
                                } catch (_) {}
                                context.go('/request', extra: {
                                  'historyEntry': entry,
                                  'collectionId': entry.collectionId,
                                  'collectionHeaders': collHeaders,
                                });
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => shad.AlertDialog(
                                    title: const Text('Delete Entry'),
                                    content: const Text('Remove this entry from history?'),
                                    actions: [
                                      shad.Button.ghost(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      shad.Button.primary(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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

  Widget _buildEmptyState(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.history, size: 48, color: colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text('No history yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const SizedBox(height: 8),
            Text('Send a request to see it here', style: TextStyle(color: colorScheme.mutedForeground)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, size: 48, color: colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text('No results found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const SizedBox(height: 8),
            Text('Try a different search term', style: TextStyle(color: colorScheme.mutedForeground)),
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
    final colorScheme = shad.Theme.of(context).colorScheme;
    final displayName = entry.requestName ?? entry.url;

    final statusColor = entry.statusCode == null
        ? colorScheme.mutedForeground
        : entry.statusCode! >= 200 && entry.statusCode! < 300
            ? const Color(0xFF22C55E)
            : entry.statusCode! >= 400
                ? const Color(0xFFEF4444)
                : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: methodColor(entry.method).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(entry.method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: methodColor(entry.method)), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.foreground), overflow: TextOverflow.ellipsis, maxLines: 1),
                  const SizedBox(height: 1),
                  Text(entry.url, style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground), overflow: TextOverflow.ellipsis, maxLines: 1),
                ],
              ),
            ),
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
              Text('${entry.responseTimeMs}ms', style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground)),
            ],
            const SizedBox(width: 4),
            shad.IconButton.ghost(icon: const Icon(LucideIcons.x, size: 12), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
