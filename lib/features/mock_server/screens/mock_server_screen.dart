import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/models/mock_endpoint.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/utils/method_colors.dart';
import '../providers/mock_server_provider.dart';

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mock Server', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Define mock endpoints for local testing', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
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
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
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
                onPressed: () => _showAddEndpointDialog(context),
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
                        onDelete: () async {
                          await ref.read(mockEndpointRepositoryProvider).deleteEndpoint(ep.id);
                          ref.invalidate(mockEndpointsProvider);
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
              onPressed: () => _showAddEndpointDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Endpoint'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEndpointDialog(BuildContext context) {
    final pathController = TextEditingController(text: '/api/');
    final bodyController = TextEditingController(text: '{"status": "ok"}');
    String method = 'GET';
    int statusCode = 200;
    int delayMs = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Mock Endpoint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: ['GET', 'POST', 'PUT', 'DELETE'].map((m) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: method == m
                      ? FilledButton.tonal(
                          onPressed: () => setDialogState(() => method = m),
                          child: Text(m, style: const TextStyle(fontSize: 11)),
                        )
                      : OutlinedButton(
                          onPressed: () => setDialogState(() => method = m),
                          child: Text(m, style: const TextStyle(fontSize: 11)),
                        ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              TextField(controller: pathController, decoration: const InputDecoration(hintText: '/api/path')),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: statusCode,
                      isDense: true,
                      items: [200, 201, 204, 400, 401, 403, 404, 500].map((c) =>
                        DropdownMenuItem(value: c, child: Text('$c'))
                      ).toList(),
                      onChanged: (v) { if (v != null) setDialogState(() => statusCode = v); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: bodyController, decoration: const InputDecoration(hintText: 'Response body (JSON)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (pathController.text.isNotEmpty) {
                  await ref.read(mockEndpointRepositoryProvider).createEndpoint(
                    method: method,
                    path: pathController.text,
                    statusCode: statusCode,
                    body: bodyController.text,
                    delayMs: delayMs,
                  );
                  ref.invalidate(mockEndpointsProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  final MockEndpoint endpoint;
  final VoidCallback onDelete;

  const _EndpointTile({required this.endpoint, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: methodColor(endpoint.method).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(endpoint.method, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: methodColor(endpoint.method)), textAlign: TextAlign.center),
      ),
      title: Text(endpoint.path, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
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
          IconButton(icon: const Icon(LucideIcons.trash2, size: 14), onPressed: onDelete, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}
