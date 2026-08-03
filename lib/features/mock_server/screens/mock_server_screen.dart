import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../../core/providers/repository_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/mock_endpoint.dart';
import '../../../shared/widgets/toast_helper.dart';

class MockServerScreen extends ConsumerStatefulWidget {
  const MockServerScreen({super.key});

  @override
  ConsumerState<MockServerScreen> createState() => _MockServerScreenState();
}

class _MockServerScreenState extends ConsumerState<MockServerScreen> {
  bool _isRunning = false;
  HttpServer? _server;
  final int _port = AppConstants.defaultMockPort;

  Future<void> _startServer() async {
    try {
      final endpoints = await ref.read(mockEndpointRepositoryProvider).getAllEndpoints();

      shelf.Handler handler = (shelf.Request request) async {
        final path = request.requestedUri.path;
        final method = request.method.toUpperCase();

        final match = endpoints.where((e) => e.method.toUpperCase() == method && e.path == path).firstOrNull;

        if (match == null) {
          return shelf.Response.notFound('{"error": "Not found"}', headers: {'content-type': 'application/json'});
        }

        if (match.delayMs > 0) {
          await Future.delayed(Duration(milliseconds: match.delayMs));
        }

        return shelf.Response(
          match.statusCode,
          body: match.body ?? '{"status": "ok"}',
          headers: {'content-type': 'application/json', ...match.headers},
        );
      };

      _server = await shelf_io.serve(handler, 'localhost', _port);
      setState(() => _isRunning = true);

      if (mounted) {
        showDbugToast(context, message: 'Mock server running on http://localhost:$_port', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        showDbugToast(context, message: 'Failed to start server: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _stopServer() async {
    await _server?.close(force: true);
    _server = null;
    setState(() => _isRunning = false);
    if (mounted) {
      showDbugToast(context, message: 'Mock server stopped', type: ToastType.info);
    }
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final endpointsAsync = ref.watch(mockEndpointsProvider);

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
                    Text('Mock Server', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.foreground)),
                    const SizedBox(height: 4),
                    Text('Define mock endpoints for local testing', style: TextStyle(fontSize: 13, color: colorScheme.mutedForeground)),
                  ],
                ),
              ),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: shad.TextField(
                  placeholder: Text('$_port'),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 8),
              shad.Button.outline(
                onPressed: _isRunning ? _stopServer : _startServer,
                leading: Icon(_isRunning ? Icons.stop : Icons.play_arrow, size: 16),
                child: Text(_isRunning ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 8),
              if (_isRunning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Running', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
                ),
              if (!_isRunning) ...[
                const SizedBox(width: 8),
                shad.Button.primary(
                  onPressed: () => _showAddEndpointDialog(context),
                  leading: const Icon(Icons.add, size: 16),
                  child: const Text('Add Endpoint'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: endpointsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (endpoints) {
                if (endpoints.isEmpty) return _buildEmptyState(colorScheme);
                return shad.Card(
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

  Widget _buildEmptyState(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns, size: 48, color: colorScheme.mutedForeground),
            const SizedBox(height: 16),
            Text('No mock endpoints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const SizedBox(height: 8),
            Text('Add endpoints to simulate API responses', style: TextStyle(color: colorScheme.mutedForeground)),
            const SizedBox(height: 16),
            shad.Button.primary(
              onPressed: () => _showAddEndpointDialog(context),
              leading: const Icon(Icons.add, size: 16),
              child: const Text('Add Endpoint'),
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
        builder: (context, setDialogState) => shad.AlertDialog(
          title: const Text('Add Mock Endpoint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: ['GET', 'POST', 'PUT', 'DELETE'].map((m) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: method == m
                      ? shad.Button.primary(
                          onPressed: () => setDialogState(() => method = m),
                          child: Text(m, style: const TextStyle(fontSize: 11)),
                        )
                      : shad.Button.outline(
                          onPressed: () => setDialogState(() => method = m),
                          child: Text(m, style: const TextStyle(fontSize: 11)),
                        ),
                )).toList(),
              ),
              const SizedBox(height: 12),
              shad.TextField(controller: pathController, placeholder: const Text('/api/path')),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: shad.Select<int>(
                      value: statusCode,
                      onChanged: (v) { if (v != null) setDialogState(() => statusCode = v); },
                      itemBuilder: (context, value) => Text('$value', style: const TextStyle(fontSize: 12)),
                      popup: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [200, 201, 204, 400, 401, 403, 404, 500].map((c) =>
                          shad.SelectItemButton<int>(value: c, child: Text('$c'))
                        ).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              shad.TextField(controller: bodyController, placeholder: const Text('Response body (JSON)')),
            ],
          ),
          actions: [
            shad.Button.ghost(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            shad.Button.primary(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _methodColor(endpoint.method).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(endpoint.method, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _methodColor(endpoint.method)), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(endpoint.path, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: endpoint.statusCode >= 200 && endpoint.statusCode < 300
                  ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                  : const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${endpoint.statusCode}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: endpoint.statusCode >= 200 && endpoint.statusCode < 300 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            ),
          ),
          const SizedBox(width: 4),
          shad.IconButton.ghost(icon: const Icon(Icons.delete_outline, size: 14), onPressed: onDelete),
        ],
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
