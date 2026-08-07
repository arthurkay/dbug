import 'dart:convert' as convert;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/http/http_client.dart';
import '../utils/syntax_highlighter.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final resp = widget.response;
    final isJson = _isJsonBody(resp);
    final contentType = _detectContentType(resp);

    return Card(
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
                  child: DefaultTabController(
                    length: 2,
                    initialIndex: _selectedTab,
                    child: TabBar(
                      onTap: (i) => setState(() => _selectedTab = i),
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Body'),
                            if (contentType != 'text') ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(contentType.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.green)),
                              ),
                            ],
                          ],
                        )),
                        const Tab(text: 'Headers'),
                      ],
                    ),
                  ),
                ),
                if (_selectedTab == 0 && isJson) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
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

  Widget _viewToggle(ColorScheme colorScheme, String label, bool isPretty) {
    final isActive = _prettyView == isPretty;
    return GestureDetector(
      onTap: () => setState(() => _prettyView = isPretty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colorScheme.onSurface : colorScheme.outline,
          ),
        ),
      ),
    );
  }

  bool _isJsonBody(HttpResponse resp) {
    final contentType = resp.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) return true;
    if (contentType.contains('xml') || contentType.contains('yaml') || contentType.contains('yml')) return false;
    final body = resp.body.trimLeft();
    return body.startsWith('{') || body.startsWith('[');
  }

  String _detectContentType(HttpResponse resp) {
    final contentType = resp.headers['content-type'] ?? '';
    if (contentType.contains('application/json') || contentType.contains('text/json')) return 'json';
    if (contentType.contains('xml') || contentType.contains('text/xml') || contentType.contains('application/xml')) return 'xml';
    if (contentType.contains('yaml') || contentType.contains('yml') || contentType.contains('text/yaml')) return 'yaml';
    final body = resp.body.trimLeft();
    if (body.startsWith('{') || body.startsWith('[')) return 'json';
    if (body.startsWith('<')) return 'xml';
    return 'text';
  }

  Widget _buildStatusBar(ColorScheme colorScheme, HttpResponse resp) {
    final statusColor = resp.isSuccess
        ? Colors.green
        : resp.statusCode >= 400
            ? Colors.red
            : resp.statusCode >= 300
                ? Colors.orange
                : colorScheme.outline;

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
        Text(resp.statusCodeLabel, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        const Spacer(),
        _buildMetaChip(LucideIcons.timer, '${resp.timeMs}ms', colorScheme),
        const SizedBox(width: 12),
        _buildMetaChip(LucideIcons.database, _formatSize(resp.sizeBytes), colorScheme),
      ],
    );
  }

  Widget _buildMetaChip(IconData icon, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBody(ColorScheme colorScheme, HttpResponse resp, bool isJson) {
    if (resp.body.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 32, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('Empty response body', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }

    final displayBody = isJson && _prettyView ? _prettyPrintJson(resp.body) : resp.body;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: _buildHighlightedView(colorScheme, displayBody, resp),
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

  Widget _buildHighlightedView(ColorScheme colorScheme, String body, HttpResponse resp) {
    final lines = body.split('\n');
    final contentType = resp.headers['content-type'] ?? '';
    final spans = SyntaxHighlighter.highlight(body, contentType, colorScheme.brightness);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(right: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4))),
              ),
              child: Column(
                children: List.generate(lines.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                )),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(14),
                child: SelectableText.rich(
                  TextSpan(children: spans),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaders(ColorScheme colorScheme, HttpResponse resp) {
    if (resp.headers.isEmpty) {
      return Center(
        child: Text('No response headers', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
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
              color: isEven ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: SelectableText(key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary, fontFamily: 'monospace')),
                  ),
                  Expanded(
                    child: SelectableText(value, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant)),
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
