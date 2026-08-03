import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class SpecBrowserScreen extends StatelessWidget {
  final String specId;

  const SpecBrowserScreen({super.key, required this.specId});

  @override
  Widget build(BuildContext context) {
    final theme = shad.Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: _buildEndpointList(context, colorScheme),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildEndpointDetail(context, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildEndpointList(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: shad.TextField(
              placeholder: Text('Search endpoints...'),
              style: TextStyle(fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _buildTagGroup(context, colorScheme, 'Users', [
                  _buildEndpointTile(context, 'GET', '/users', 'List users'),
                  _buildEndpointTile(context, 'POST', '/users', 'Create user'),
                  _buildEndpointTile(context, 'GET', '/users/{id}', 'Get user'),
                ]),
                _buildTagGroup(context, colorScheme, 'Posts', [
                  _buildEndpointTile(context, 'GET', '/posts', 'List posts'),
                  _buildEndpointTile(context, 'POST', '/posts', 'Create post'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagGroup(
    BuildContext context,
    shad.ColorScheme colorScheme,
    String tag,
    List<Widget> children,
  ) {
    return ExpansionTile(
      title: Text(
        tag,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      children: children,
    );
  }

  Widget _buildEndpointTile(
    BuildContext context,
    String method,
    String path,
    String summary,
  ) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getMethodColor(method).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          method,
          style: TextStyle(
            color: _getMethodColor(method),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(path, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      subtitle: Text(summary, style: const TextStyle(fontSize: 11)),
      onTap: () {},
    );
  }

  Widget _buildEndpointDetail(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                shad.Button.primary(
                  onPressed: () {},
                  leading: const Icon(Icons.send, size: 14),
                  child: const Text('Send'),
                ),
                const SizedBox(width: 8),
                shad.Button.ghost(
                  onPressed: () {},
                  child: const Text('Save to Collection'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Select an endpoint from the list',
              style: TextStyle(color: colorScheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(String method) {
    const colors = {
      'GET': Color(0xFF22C55E),
      'POST': Color(0xFF3B82F6),
      'PUT': Color(0xFFF59E0B),
      'PATCH': Color(0xFFF97316),
      'DELETE': Color(0xFFEF4444),
      'HEAD': Color(0xFF8B5CF6),
      'OPTIONS': Color(0xFF6B7280),
    };
    return colors[method] ?? const Color(0xFF6B7280);
  }
}
