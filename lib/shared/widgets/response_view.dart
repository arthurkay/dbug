import 'dart:convert' as convert;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show SelectableText, SelectionArea;
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;
import '../../core/http/http_client.dart';

class ResponseView extends StatefulWidget {
  final HttpResponse response;

  const ResponseView({super.key, required this.response});

  @override
  State<ResponseView> createState() => _ResponseViewState();
}

class _ResponseViewState extends State<ResponseView> {
  int _selectedTab = 0;
  bool _prettyView = true;

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
            Row(
              children: [
                Expanded(
                  child: shad.Tabs(
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
                      const shad.TabItem(child: Text('Headers')),
                    ],
                  ),
                ),
                if (_selectedTab == 0 && isJson) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.muted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _viewToggle(colorScheme, 'Pretty', true),
                        _viewToggle(colorScheme, 'Raw', false),
                      ],
                    ),
                  ),
                ],
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

  Widget _viewToggle(shad.ColorScheme colorScheme, String label, bool isPretty) {
    final isActive = _prettyView == isPretty;
    return GestureDetector(
      onTap: () => setState(() => _prettyView = isPretty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.background : const Color(0x00000000),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colorScheme.foreground : colorScheme.mutedForeground,
          ),
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
        _buildMetaChip(LucideIcons.timer, '${resp.timeMs}ms', colorScheme),
        const SizedBox(width: 12),
        _buildMetaChip(LucideIcons.database, _formatSize(resp.sizeBytes), colorScheme),
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
            Icon(LucideIcons.inbox, size: 32, color: colorScheme.mutedForeground),
            const SizedBox(height: 8),
            Text('Empty response body', style: TextStyle(color: colorScheme.mutedForeground, fontSize: 13)),
          ],
        ),
      );
    }

    final displayBody = isJson && _prettyView ? _prettyPrintJson(resp.body) : resp.body;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.muted,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: _buildLineView(colorScheme, displayBody),
    );
  }

  String _prettyPrintJson(String body) {
    try {
      final parsed = convert.jsonDecode(body);
      return const convert.JsonEncoder.withIndent('  ').convert(parsed);
    } catch (e) {
      debugPrint('Failed to pretty print JSON: $e');
      return body;
    }
  }

  Widget _buildLineView(shad.ColorScheme colorScheme, String body) {
    final lines = body.split('\n');
    final numberedBody = List.generate(lines.length, (i) {
      final lineNum = '${(i + 1).toString().padLeft(4)}  ';
      return '$lineNum${lines[i]}';
    }).join('\n');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.muted,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: SelectableText(
          numberedBody,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: colorScheme.foreground,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaders(shad.ColorScheme colorScheme, HttpResponse resp) {
    if (resp.headers.isEmpty) {
      return Center(
        child: Text('No response headers', style: TextStyle(color: colorScheme.mutedForeground)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.muted,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: SelectionArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          separatorBuilder: (_, __) => const SizedBox(height: 1),
          itemCount: resp.headers.length,
          itemBuilder: (context, i) {
            final key = resp.headers.keys.elementAt(i);
            final value = resp.headers[key]!;
            final isEven = i.isEven;
            return Container(
              color: isEven ? colorScheme.muted : colorScheme.muted.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: SelectableText(key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary, fontFamily: 'monospace')),
                  ),
                  Expanded(
                    child: SelectableText(value, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colorScheme.mutedForeground)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
