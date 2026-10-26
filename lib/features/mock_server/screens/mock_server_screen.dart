import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/utils/syntax_highlighter.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/models/mock_endpoint.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/utils/method_colors.dart';
import '../providers/mock_server_provider.dart';
import '../widgets/mock_endpoint_dialog.dart';

class MockServerScreen extends ConsumerStatefulWidget {
  const MockServerScreen({super.key});

  @override
  ConsumerState<MockServerScreen> createState() => _MockServerScreenState();
}

class _MockServerScreenState extends ConsumerState<MockServerScreen> {
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(
      text: '${ref.read(mockServerProvider).port}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(windowTitleProvider.notifier).state = 'Mock Server';
    });
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  Future<void> _startServer() async {
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) {
      showDbugToast(context,
          message: 'Enter a valid port (1–65535)', type: ToastType.warning);
      return;
    }

    final error = await ref.read(mockServerProvider.notifier).start(port);
    if (!mounted) return;
    if (error != null) {
      showDbugToast(context, message: error, type: ToastType.error);
    } else {
      showDbugToast(context,
          message: 'Mock server running on http://localhost:$port',
          type: ToastType.success);
    }
  }

  Future<void> _stopServer() async {
    await ref.read(mockServerProvider.notifier).stop();
    if (mounted) {
      showDbugToast(context, message: 'Mock server stopped', type: ToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final endpointsAsync = ref.watch(mockEndpointsProvider);
    final server = ref.watch(mockServerProvider);
    final isRunning = server.isRunning;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: PageHeader(title: 'Mock Server', subtitle: 'Define mock endpoints for local testing')),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _portController,
                  enabled: !isRunning,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Port',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: TextStyle(fontSize: 12, fontFamily: codeFontFamily),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isRunning ? _stopServer : _startServer,
                icon: Icon(isRunning ? LucideIcons.square : LucideIcons.play, size: 16),
                label: Text(isRunning ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 8),
              if (isRunning) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(':${server.port}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: () => showMockEndpointDialog(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Endpoint'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: endpointsAsync.when(
              loading: () => const Center(child: DbugSpinner()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (endpoints) {
                if (endpoints.isEmpty) return _buildEmptyState(colorScheme);
                return Card(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: endpoints.length,
                    itemBuilder: (context, index) {
                      final ep = endpoints[index];
                      return _EndpointTile(
                        endpoint: ep,
                        onEdit: () => showMockEndpointDialog(context, existing: ep),
                        onDelete: () => _deleteEndpoint(ep),
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

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.server, size: 48, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No mock endpoints', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Add endpoints to simulate API responses', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showMockEndpointDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Endpoint'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEndpoint(MockEndpoint ep) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Endpoint'),
        content: Text('Delete ${ep.method} ${ep.path}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(mockEndpointRepositoryProvider).deleteEndpoint(ep.id);
    ref.invalidate(mockEndpointsProvider);
  }
}

class _EndpointTile extends StatelessWidget {
  final MockEndpoint endpoint;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EndpointTile({required this.endpoint, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onEdit,
      leading: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: methodColor(endpoint.method).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(endpoint.method, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: methodColor(endpoint.method)), textAlign: TextAlign.center),
      ),
      title: Text(endpoint.path, style: TextStyle(fontSize: 12, fontFamily: codeFontFamily)),
      subtitle: endpoint.delayMs > 0 || endpoint.headers.isNotEmpty
          ? Text(
              [
                if (endpoint.delayMs > 0) '${endpoint.delayMs} ms delay',
                if (endpoint.headers.isNotEmpty) '${endpoint.headers.length} header${endpoint.headers.length == 1 ? '' : 's'}',
              ].join(' · '),
              style: const TextStyle(fontSize: 11),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: endpoint.statusCode >= 200 && endpoint.statusCode < 300
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${endpoint.statusCode}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: endpoint.statusCode >= 200 && endpoint.statusCode < 300 ? Colors.green : Colors.red),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(LucideIcons.pencil, size: 14), tooltip: 'Edit', onPressed: onEdit, visualDensity: VisualDensity.compact),
          IconButton(icon: const Icon(LucideIcons.trash2, size: 14), tooltip: 'Delete', onPressed: onDelete, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}
