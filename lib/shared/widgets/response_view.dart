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

  static const _keyColor = Color(0xFF93C5FD);
  static const _stringColor = Color(0xFF86EFAC);
  static const _numberColor = Color(0xFFFDE68A);
  static const _boolColor = Color(0xFFC4B5FD);
  static const _nullColor = Color(0xFF9CA3AF);
  static const _bracketColor = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;
    final resp = widget.response;
    final isJson = _isJsonBody(resp);

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
              children: [
                shad.TabItem(child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Body'),
                    if (isJson) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('JSON', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                      ),
                    ],
                  ],
                )),
                shad.TabItem(child: Text('Headers')),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _selectedTab == 0
                  ? _buildBody(colorScheme, resp, isJson)
                  : _buildHeaders(colorScheme, resp),
            ),
          ],
        ),
      ),
    );
  }

  bool _isJsonBody(HttpResponse resp) {
    final contentType = resp.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) return true;
    final body = resp.body.trimLeft();
    return body.startsWith('{') || body.startsWith('[');
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            resp.statusCode == 0 ? 'ERR' : '${resp.statusCode}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(resp.statusCodeLabel, style: TextStyle(fontSize: 12, color: colorScheme.mutedForeground)),
        const Spacer(),
        _buildMetaChip(Icons.timer_outlined, '${resp.timeMs}ms', colorScheme),
        const SizedBox(width: 12),
        _buildMetaChip(Icons.data_usage_outlined, _formatSize(resp.sizeBytes), colorScheme),
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String label, shad.ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.mutedForeground),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBody(shad.ColorScheme colorScheme, HttpResponse resp, bool isJson) {
    if (resp.body.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 32, color: colorScheme.mutedForeground),
            const SizedBox(height: 8),
            Text('Empty response body', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: isJson
            ? _buildHighlightedJson(resp.body)
            : SelectableText(resp.body, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFE6EDF3))),
      ),
    );
  }

  Widget _buildHighlightedJson(String body) {
    try {
      final dynamic parsed = convert.jsonDecode(body);
      final spans = <TextSpan>[];
      _writeJsonSpans(parsed, spans, 0);
      return SelectableText.rich(
        TextSpan(style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFE6EDF3), height: 1.5), children: spans),
      );
    } catch (_) {
      return SelectableText(body, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFE6EDF3)));
    }
  }

  void _writeJsonSpans(dynamic obj, List<TextSpan> spans, int indent) {
    final pad = '  ' * indent;
    final pad1 = '  ' * (indent + 1);

    if (obj is Map) {
      if (obj.isEmpty) {
        spans.add(TextSpan(text: '{}', style: TextStyle(color: _bracketColor)));
        return;
      }
      spans.add(TextSpan(text: '{\n', style: TextStyle(color: _bracketColor)));
      final entries = obj.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        spans.add(TextSpan(text: pad1));
        spans.add(TextSpan(text: '"${e.key}"', style: TextStyle(color: _keyColor, fontWeight: FontWeight.w600)));
        spans.add(TextSpan(text: ': ', style: TextStyle(color: _bracketColor)));
        _writeJsonSpans(e.value, spans, indent + 1);
        if (i < entries.length - 1) spans.add(TextSpan(text: ',', style: TextStyle(color: _bracketColor)));
        spans.add(TextSpan(text: '\n'));
      }
      spans.add(TextSpan(text: '$pad}', style: TextStyle(color: _bracketColor)));
    } else if (obj is List) {
      if (obj.isEmpty) {
        spans.add(TextSpan(text: '[]', style: TextStyle(color: _bracketColor)));
        return;
      }
      spans.add(TextSpan(text: '[\n', style: TextStyle(color: _bracketColor)));
      for (var i = 0; i < obj.length; i++) {
        spans.add(TextSpan(text: pad1));
        _writeJsonSpans(obj[i], spans, indent + 1);
        if (i < obj.length - 1) spans.add(TextSpan(text: ',', style: TextStyle(color: _bracketColor)));
        spans.add(TextSpan(text: '\n'));
      }
      spans.add(TextSpan(text: '$pad]', style: TextStyle(color: _bracketColor)));
    } else if (obj is String) {
      spans.add(TextSpan(text: '"$obj"', style: TextStyle(color: _stringColor)));
    } else if (obj is num) {
      spans.add(TextSpan(text: '$obj', style: TextStyle(color: _numberColor)));
    } else if (obj is bool) {
      spans.add(TextSpan(text: '$obj', style: TextStyle(color: _boolColor)));
    } else if (obj == null) {
      spans.add(TextSpan(text: 'null', style: TextStyle(color: _nullColor, fontStyle: FontStyle.italic)));
    }
  }

  Widget _buildHeaders(shad.ColorScheme colorScheme, HttpResponse resp) {
    if (resp.headers.isEmpty) {
      return Center(
        child: Text('No response headers', style: TextStyle(color: colorScheme.mutedForeground)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => Divider(height: 1, color: const Color(0xFF30363D)),
        itemCount: resp.headers.length,
        itemBuilder: (context, i) {
          final key = resp.headers.keys.elementAt(i);
          final value = resp.headers[key]!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Text(key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _keyColor, fontFamily: 'monospace')),
                ),
                Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFE6EDF3))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
