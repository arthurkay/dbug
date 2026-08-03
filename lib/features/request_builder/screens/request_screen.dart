import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  String _selectedMethod = 'GET';
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  int _selectedTab = 0;
  final _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
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
          _buildMethodUrlBar(context, colorScheme),
          const SizedBox(height: 16),
          _buildTabs(context, colorScheme),
          const SizedBox(height: 12),
          Expanded(child: _buildTabContent(context, colorScheme)),
          const SizedBox(height: 12),
          _buildSendButton(context),
        ],
      ),
    );
  }

  Widget _buildMethodUrlBar(BuildContext context, shad.ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMethod,
              isDense: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: BorderRadius.circular(6),
              items: _methods.map((m) {
                final color = _getMethodColor(m);
                return DropdownMenuItem(
                  value: m,
                  child: Text(
                    m,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedMethod = v);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: shad.TextField(
            controller: _urlController,
            placeholder: const Text('Enter request URL or paste cURL'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Tabs(
      index: _selectedTab,
      onChanged: (index) => setState(() => _selectedTab = index),
      children: const [
        shad.TabItem(child: Text('Params')),
        shad.TabItem(child: Text('Headers')),
        shad.TabItem(child: Text('Body')),
        shad.TabItem(child: Text('Auth')),
        shad.TabItem(child: Text('Scripts')),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, shad.ColorScheme colorScheme) {
    switch (_selectedTab) {
      case 0:
        return _buildParamsTab(context, colorScheme);
      case 1:
        return _buildHeadersTab(context, colorScheme);
      case 2:
        return _buildBodyTab(context, colorScheme);
      case 3:
        return _buildAuthTab(context, colorScheme);
      case 4:
        return _buildScriptsTab(context, colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildParamsTab(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query Parameters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildKeyValueRow(context, 'Key', 'Value'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            shad.Button.outline(
              onPressed: () {},
              child: const Text('Add Parameter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadersTab(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Headers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildKeyValueRow(context, 'Header', 'Value'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            shad.Button.outline(
              onPressed: () {},
              child: const Text('Add Header'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyTab(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Body',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: shad.TextField(
                controller: _bodyController,
                placeholder: const Text('Enter request body (JSON, XML, etc.)'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthTab(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authorization',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                shad.Button.outline(
                  onPressed: () {},
                  child: const Text('None'),
                ),
                const SizedBox(width: 8),
                shad.Button.outline(
                  onPressed: () {},
                  child: const Text('Bearer'),
                ),
                const SizedBox(width: 8),
                shad.Button.outline(
                  onPressed: () {},
                  child: const Text('Basic'),
                ),
                const SizedBox(width: 8),
                shad.Button.outline(
                  onPressed: () {},
                  child: const Text('API Key'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScriptsTab(BuildContext context, shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pre/Post Request Scripts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: shad.TextField(
                placeholder: const Text(
                  '// Write JavaScript here\n// Available: dbug.setVar(), dbug.getVar(), dbug.getResponse()',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(BuildContext context, String keyHint, String valueHint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: shad.TextField(
              placeholder: Text(keyHint),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: shad.TextField(
              placeholder: Text(valueHint),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          shad.IconButton.ghost(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return shad.Button.primary(
      onPressed: () {},
      leading: const Icon(Icons.send, size: 16),
      child: const Text('Send Request'),
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
