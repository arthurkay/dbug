import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class MockServerScreen extends StatefulWidget {
  const MockServerScreen({super.key});

  @override
  State<MockServerScreen> createState() => _MockServerScreenState();
}

class _MockServerScreenState extends State<MockServerScreen> {
  bool _isRunning = false;
  final _portController = TextEditingController(text: '3001');

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = shad.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Mock Server',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.foreground,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(context, colorScheme),
            ],
          ),
          const SizedBox(height: 16),
          _buildServerControls(context, colorScheme),
          const SizedBox(height: 16),
          _buildEndpointsList(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, shad.ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isRunning
            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
            : colorScheme.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRunning
                  ? const Color(0xFF22C55E)
                  : colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isRunning ? 'Running on :${_portController.text}' : 'Stopped',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _isRunning
                  ? const Color(0xFF22C55E)
                  : colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerControls(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Port: ',
              style: TextStyle(color: colorScheme.foreground),
            ),
            SizedBox(
              width: 80,
              child: shad.TextField(
                controller: _portController,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            shad.Button.primary(
              onPressed: () {
                setState(() => _isRunning = !_isRunning);
              },
              leading: Icon(_isRunning ? Icons.stop : Icons.play_arrow, size: 16),
              child: Text(_isRunning ? 'Stop' : 'Start'),
            ),
            const Spacer(),
            shad.Button.outline(
              onPressed: () => _showAddEndpointDialog(context),
              leading: const Icon(Icons.add, size: 16),
              child: const Text('Add Endpoint'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointsList(BuildContext context, shad.ColorScheme colorScheme) {
    return Expanded(
      child: shad.Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Mock Endpoints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.foreground,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      size: 48,
                      color: colorScheme.mutedForeground,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No mock endpoints defined',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add endpoints to define mock responses',
                      style: TextStyle(color: colorScheme.mutedForeground),
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

  void _showAddEndpointDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => shad.AlertDialog(
        title: const Text('Add Mock Endpoint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                shad.Button.outline(onPressed: () {}, child: const Text('GET')),
                const SizedBox(width: 8),
                shad.Button.outline(onPressed: () {}, child: const Text('POST')),
                const SizedBox(width: 8),
                shad.Button.outline(onPressed: () {}, child: const Text('PUT')),
                const SizedBox(width: 8),
                const Expanded(
                  child: shad.TextField(
                    placeholder: Text('/api/resource'),
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const shad.TextField(placeholder: Text('Status Code')),
            const SizedBox(height: 12),
            const shad.TextField(
              placeholder: Text('Response Body (JSON)'),
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              minLines: 5,
              maxLines: null,
            ),
          ],
        ),
        actions: [
          shad.Button.ghost(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          shad.Button.primary(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
