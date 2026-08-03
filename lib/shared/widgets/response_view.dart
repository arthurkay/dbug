import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import '../../core/http/http_client.dart';

class ResponseView extends StatefulWidget {
  final HttpResponse response;

  const ResponseView({super.key, required this.response});

  @override
  State<ResponseView> createState() => _ResponseViewState();
}

class _ResponseViewState extends State<ResponseView> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final resp = widget.response;

    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBar(colorScheme, resp),
            const SizedBox(height: 10),
            shad.Tabs(
              index: _selectedTab,
              onChanged: (i) => setState(() => _selectedTab = i),
              children: const [
                shad.TabItem(child: Text('Body')),
                shad.TabItem(child: Text('Headers')),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedTab == 0
                  ? _buildBody(colorScheme, resp)
                  : _buildHeaders(colorScheme, resp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(shad.ColorScheme colorScheme, HttpResponse resp) {
    final statusColor = resp.isSuccess
        ? const Color(0xFF22C55E)
        : resp.statusCode >= 400
            ? const Color(0xFFEF4444)
            : resp.statusCode >= 300
                ? const Color(0xFFF59E0B)
                : colorScheme.mutedForeground;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            resp.statusCode == 0 ? 'ERR' : '${resp.statusCode}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          resp.statusCodeLabel,
          style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground),
        ),
        const Spacer(),
        _buildMetaChip(Icons.timer_outlined, '${resp.timeMs}ms', colorScheme),
        const SizedBox(width: 8),
        _buildMetaChip(Icons.data_usage_outlined, _formatSize(resp.sizeBytes), colorScheme),
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String label, shad.ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.mutedForeground),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
      ],
    );
  }

  Widget _buildBody(shad.ColorScheme colorScheme, HttpResponse resp) {
    if (resp.body.isEmpty) {
      return Center(
        child: Text('Empty response body', style: TextStyle(color: colorScheme.mutedForeground)),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.muted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        _prettyPrintJson(resp.body),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _buildHeaders(shad.ColorScheme colorScheme, HttpResponse resp) {
    if (resp.headers.isEmpty) {
      return Center(
        child: Text('No response headers', style: TextStyle(color: colorScheme.mutedForeground)),
      );
    }

    return ListView.builder(
      itemCount: resp.headers.length,
      itemBuilder: (context, i) {
        final key = resp.headers.keys.elementAt(i);
        final value = resp.headers[key]!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.foreground,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: colorScheme.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _prettyPrintJson(String body) {
    try {
      final dynamic parsed = _jsonDecode(body);
      return _jsonPrettyPrint(parsed, 0);
    } catch (_) {
      return body;
    }
  }

  dynamic _jsonDecode(String s) {
    return convert.jsonDecode(s);
  }

  String _jsonPrettyPrint(dynamic obj, int indent) {
    final pad = '  ' * indent;
    if (obj is Map) {
      if (obj.isEmpty) return '{}';
      final entries = obj.entries.map((e) =>
        '$pad  "${e.key}": ${_jsonPrettyPrint(e.value, indent + 1)}').join(',\n');
      return '{\n$entries\n$pad}';
    } else if (obj is List) {
      if (obj.isEmpty) return '[]';
      final items = obj.map((e) =>
        '$pad  ${_jsonPrettyPrint(e, indent + 1)}').join(',\n');
      return '[\n$items\n$pad]';
    } else if (obj is String) {
      return '"${obj.replaceAll('"', '\\"')}"';
    } else {
      return '$obj';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
