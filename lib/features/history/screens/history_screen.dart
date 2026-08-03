import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:intl/intl.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/models/history_entry.dart';
import '../../../core/models/request_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  await ref.read(historyRepositoryProvider).clearAll();
                  ref.invalidate(historyProvider);
                },
                leading: const Icon(Icons.delete_sweep_outlined, size: 16),
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }
                return shad.Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _HistoryTile(
                        entry: entry,
                        onTap: () {
                          final req = RequestModel(
                            id: '',
                            name: entry.url,
                            method: entry.method,
                            url: entry.url,
                            createdAt: entry.sentAt,
                            updatedAt: entry.sentAt,
                          );
                          context.go('/request', extra: req);
                        },
                        onDelete: () async {
                          await ref.read(historyRepositoryProvider).deleteEntry(entry.id);
                          ref.invalidate(historyProvider);
                        },
                      );
                    },
                  ),
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
            Icon(Icons.history, size: 48, color: colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text('No history yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const SizedBox(height: 8),
            Text('Send a request to see it here', style: TextStyle(color: colorScheme.mutedForeground)),
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
    final timeStr = DateFormat('MMM d, HH:mm').format(entry.sentAt);

    final statusColor = entry.statusCode == null
        ? colorScheme.mutedForeground
        : entry.statusCode! >= 200 && entry.statusCode! < 300
            ? const Color(0xFF22C55E)
            : entry.statusCode! >= 400
                ? const Color(0xFFEF4444)
                : const Color(0xFFF59E0B);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _methodColor(entry.method).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(entry.method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _methodColor(entry.method)), textAlign: TextAlign.center),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.url, style: TextStyle(fontSize: 12, color: colorScheme.foreground), overflow: TextOverflow.ellipsis, maxLines: 1),
                  Text(timeStr, style: TextStyle(fontSize: 10, color: colorScheme.mutedForeground)),
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
            shad.IconButton.ghost(icon: const Icon(Icons.close, size: 12), onPressed: onDelete),
          ],
        ),
      ),
    );
  }

  Color _methodColor(String method) {
    const colors = {
      'GET': Color(0xFF22C55E), 'POST': Color(0xFF3B82F6), 'PUT': Color(0xFFF59E0B),
      'PATCH': Color(0xFFF97316), 'DELETE': Color(0xFFEF4444),
    };
    return colors[method.toUpperCase()] ?? const Color(0xFF6B7280);
  }
}
