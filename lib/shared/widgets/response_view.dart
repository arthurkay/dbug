import 'dart:convert' as convert;
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/http/http_client.dart';
import '../../core/providers/syntax_theme_provider.dart';
import '../utils/syntax_highlighter.dart';
import 'dbug_spinner.dart';

/// Bodies above this size are prepared on a background isolate.
const backgroundRenderThreshold = 100 * 1024;

/// Bodies above this size are shown without syntax highlighting.
const highlightLimit = 512 * 1024;

/// Display lines longer than this are split into continuation rows, so a
/// minified multi-megabyte body never becomes one unpaintable line.
const maxDisplayLineChars = 4000;

const _codeFontSize = 13.0;
const _codeLineHeight = 1.5;

class ResponseView extends ConsumerStatefulWidget {
  final HttpResponse response;

  const ResponseView({super.key, required this.response});

  /// Number of body renders started; lets tests check that unrelated
  /// rebuilds don't redo the work.
  @visibleForTesting
  static int debugRenderCount = 0;

  /// The most recent background render, so tests can await it.
  @visibleForTesting
  static Future<void>? debugPendingRender;

  @override
  ConsumerState<ResponseView> createState() => _ResponseViewState();
}

/// The body as prepared for display.
class RenderedBody {
  /// The displayed text (pretty-printed when that view is on).
  final String text;

  /// One entry per display row: highlighted spans, or null when highlighting
  /// is off (then [plainLines] is used).
  final List<List<TextSpan>>? spanLines;
  final List<String>? plainLines;

  /// 1-based source line number for each display row, or 0 for a
  /// continuation of a split long line.
  final List<int> lineNumbers;

  /// Length of the longest display row, for sizing the horizontal scroll.
  final int maxLineChars;

  final bool highlighted;

  const RenderedBody({
    required this.text,
    this.spanLines,
    this.plainLines,
    required this.lineNumbers,
    required this.maxLineChars,
    required this.highlighted,
  });

  int get rowCount => lineNumbers.length;
}

/// Pretty-prints (when asked) and highlights [body]. Pure, so it can run on a
/// background isolate.
RenderedBody renderBody({
  required String body,
  required bool prettyJson,
  required String contentType,
  required String themeName,
  required Brightness brightness,
}) {
  var text = body;
  if (prettyJson) {
    try {
      text = const convert.JsonEncoder.withIndent('  ').convert(convert.jsonDecode(body));
    } catch (_) {
      // Not valid JSON after all; show it as-is.
    }
  }

  if (text.length > highlightLimit) {
    final rows = <String>[];
    final numbers = <int>[];
    var maxChars = 0;
    var lineNo = 0;
    for (final line in const convert.LineSplitter().convert(text)) {
      lineNo++;
      for (var start = 0; start == 0 || start < line.length; start += maxDisplayLineChars) {
        final chunk = line.substring(start, math.min(line.length, start + maxDisplayLineChars));
        rows.add(chunk);
        numbers.add(start == 0 ? lineNo : 0);
        maxChars = math.max(maxChars, chunk.length);
      }
    }
    return RenderedBody(
      text: text,
      plainLines: rows,
      lineNumbers: numbers,
      maxLineChars: maxChars,
      highlighted: false,
    );
  }

  final spans = SyntaxHighlighter.highlight(text, contentType, brightness, themeName: themeName);
  final split = splitSpansIntoLines(spans, maxLineChars: maxDisplayLineChars);
  return RenderedBody(
    text: text,
    spanLines: split.lines,
    lineNumbers: split.lineNumbers,
    maxLineChars: split.maxLineChars,
    highlighted: true,
  );
}

/// Splits a flat list of highlighted spans into display rows at each `\n`,
/// keeping every fragment's style. Rows longer than [maxLineChars] continue
/// on extra rows whose line number is 0.
({List<List<TextSpan>> lines, List<int> lineNumbers, int maxLineChars}) splitSpansIntoLines(
  List<TextSpan> spans, {
  int maxLineChars = maxDisplayLineChars,
}) {
  final lines = <List<TextSpan>>[];
  final numbers = <int>[];
  var current = <TextSpan>[];
  var currentLen = 0;
  var lineNo = 1;
  var isContinuation = false;
  var maxChars = 0;

  void endRow({required bool newLine}) {
    lines.add(current);
    numbers.add(isContinuation ? 0 : lineNo);
    maxChars = math.max(maxChars, currentLen);
    current = <TextSpan>[];
    currentLen = 0;
    if (newLine) {
      lineNo++;
      isContinuation = false;
    } else {
      isContinuation = true;
    }
  }

  void addText(String text, TextStyle? style) {
    var rest = text;
    while (rest.isNotEmpty) {
      final room = maxLineChars - currentLen;
      if (room <= 0) {
        endRow(newLine: false);
        continue;
      }
      final piece = rest.length <= room ? rest : rest.substring(0, room);
      current.add(TextSpan(text: piece, style: style));
      currentLen += piece.length;
      rest = rest.substring(piece.length);
    }
  }

  for (final span in spans) {
    final text = span.text ?? '';
    final parts = text.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) endRow(newLine: true);
      if (parts[i].isNotEmpty) addText(parts[i], span.style);
    }
  }
  endRow(newLine: true);

  return (lines: lines, lineNumbers: numbers, maxLineChars: maxChars);
}

/// What a render depends on; a render is redone only when this changes.
class _RenderKey {
  final String body;
  final bool pretty;
  final String contentType;
  final String themeName;
  final Brightness brightness;

  const _RenderKey(this.body, this.pretty, this.contentType, this.themeName, this.brightness);

  bool sameAs(_RenderKey? other) =>
      other != null &&
      // Identity first: a parent rebuild passes the very same string.
      (identical(body, other.body) || body == other.body) &&
      pretty == other.pretty &&
      contentType == other.contentType &&
      themeName == other.themeName &&
      brightness == other.brightness;
}

class _ResponseViewState extends ConsumerState<ResponseView> {
  int _selectedTab = 0;
  bool _prettyView = true;

  _RenderKey? _renderKey;
  RenderedBody? _rendered;
  int _renderGeneration = 0;

  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  /// Starts a render when the body or its display settings changed. Small
  /// bodies render synchronously; large ones on a background isolate.
  void _ensureRendered(HttpResponse resp, bool isJson, String themeName, Brightness brightness) {
    final key = _RenderKey(
      resp.body,
      isJson && _prettyView,
      resp.headers['content-type'] ?? '',
      themeName,
      brightness,
    );
    if (key.sameAs(_renderKey)) return;
    _renderKey = key;
    ResponseView.debugRenderCount++;
    final generation = ++_renderGeneration;

    if (key.body.length <= backgroundRenderThreshold) {
      _rendered = _render(key);
      return;
    }
    _rendered = null;
    final pending = _renderInBackground(key);
    ResponseView.debugPendingRender = pending;
    pending.then((result) {
      if (mounted && generation == _renderGeneration) {
        setState(() => _rendered = result);
      }
    }, onError: (Object e) {
      debugPrint('Failed to render response body: $e');
    });
  }

  static RenderedBody _render(_RenderKey key) => renderBody(
        body: key.body,
        prettyJson: key.pretty,
        contentType: key.contentType,
        themeName: key.themeName,
        brightness: key.brightness,
      );

  // Static so the isolate closure captures only [key], never this State.
  static Future<RenderedBody> _renderInBackground(_RenderKey key) =>
      Isolate.run(() => _render(key));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resp = widget.response;
    final isJson = !resp.isBinary && _isJsonBody(resp);
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
                                child: Text(contentType.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green)),
                              ),
                            ],
                          ],
                        )),
                        const Tab(text: 'Headers'),
                      ],
                    ),
                  ),
                ),
                if (_selectedTab == 0 && resp.body.isNotEmpty && !resp.isBinary)
                  IconButton(
                    tooltip: 'Copy body',
                    icon: const Icon(LucideIcons.copy, size: 14),
                    onPressed: () => _copyBody(resp),
                  ),
                if (_selectedTab == 0 && isJson) ...[
                  const SizedBox(width: 4),
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
            if (resp.isTruncated) ...[
              const SizedBox(height: 8),
              _notice(colorScheme, LucideIcons.scissors,
                  'This body was truncated to the history size limit (Settings → History).'),
            ],
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

  void _copyBody(HttpResponse resp) {
    final text = _rendered?.text ?? resp.body;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Body copied'), duration: Duration(seconds: 1)),
    );
  }

  Widget _notice(ColorScheme colorScheme, IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ),
        ],
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
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  bool _isJsonBody(HttpResponse resp) {
    final contentType = resp.headers['content-type'] ?? '';
    if (contentType.contains('json')) return true;
    if (contentType.contains('xml') || contentType.contains('yaml') || contentType.contains('yml')) return false;
    final body = resp.body.trimLeft();
    return body.startsWith('{') || body.startsWith('[');
  }

  String _detectContentType(HttpResponse resp) {
    if (resp.isBinary) return 'binary';
    final contentType = resp.headers['content-type'] ?? '';
    if (contentType.contains('json')) return 'json';
    if (contentType.contains('xml')) return 'xml';
    if (contentType.contains('yaml') || contentType.contains('yml')) return 'yaml';
    if (contentType.contains('html')) return 'html';
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
        Text(resp.statusCodeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
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
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBody(ColorScheme colorScheme, HttpResponse resp, bool isJson) {
    if (resp.isBinary) {
      return _centeredMessage(colorScheme, LucideIcons.fileQuestion,
          'Binary response — ${_formatSize(resp.sizeBytes)} not shown',
          resp.headers['content-type']);
    }
    if (resp.body.isEmpty) {
      return _centeredMessage(colorScheme, LucideIcons.inbox, 'Empty response body', null);
    }

    _ensureRendered(
      resp,
      isJson,
      ref.watch(syntaxThemeNameProvider),
      colorScheme.brightness,
    );
    final rendered = _rendered;
    if (rendered == null) {
      return Container(
        decoration: _codePanelDecoration(colorScheme),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 18, height: 18, child: DbugSpinner(strokeWidth: 2)),
              const SizedBox(height: 8),
              Text('Preparing ${_formatSize(resp.sizeBytes)} response…',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!rendered.highlighted) ...[
          _notice(colorScheme, LucideIcons.info, 'Syntax highlighting disabled for large responses'),
          const SizedBox(height: 8),
        ],
        Expanded(child: _buildCodeLines(colorScheme, rendered)),
      ],
    );
  }

  Widget _centeredMessage(ColorScheme colorScheme, IconData icon, String title, String? subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  /// Virtualized code view: only the visible rows are built, each with its
  /// line number in the same row so they can't drift apart.
  Widget _buildCodeLines(ColorScheme colorScheme, RenderedBody rendered) {
    final codeStyle = codeTextStyle(color: colorScheme.onSurface, fontSize: _codeFontSize, height: _codeLineHeight);
    final gutterStyle = codeStyle.copyWith(color: colorScheme.onSurfaceVariant);
    final strut = codeStrutStyle(fontSize: _codeFontSize, height: _codeLineHeight);
    const rowHeight = _codeFontSize * _codeLineHeight;

    final lastLineNo = rendered.lineNumbers.isEmpty ? 1 : rendered.lineNumbers.reduce(math.max);
    final charWidth = _measureCharWidth(codeStyle);
    final gutterWidth = 20.0 + '$lastLineNo'.length * charWidth;
    final contentWidth = gutterWidth + 14 + rendered.maxLineChars * charWidth + 28;

    return Container(
      decoration: _codePanelDecoration(colorScheme),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(constraints.maxWidth, contentWidth);
          return Scrollbar(
            controller: _horizontalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: SelectionArea(
                  child: Scrollbar(
                    controller: _verticalController,
                    child: ListView.builder(
                      controller: _verticalController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemExtent: rowHeight,
                      itemCount: rendered.rowCount,
                      itemBuilder: (context, i) {
                        final lineNo = rendered.lineNumbers[i];
                        final spans = rendered.spanLines?[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: gutterWidth,
                              padding: const EdgeInsets.only(right: 10),
                              alignment: Alignment.topRight,
                              decoration: BoxDecoration(
                                border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
                              ),
                              // Selection should copy code, not line numbers.
                              child: SelectionContainer.disabled(
                                child: Text(
                                  lineNo == 0 ? '↪' : '$lineNo',
                                  style: gutterStyle,
                                  strutStyle: strut,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: spans != null
                                  ? Text.rich(TextSpan(children: spans), style: codeStyle, strutStyle: strut, maxLines: 1, softWrap: false)
                                  : Text(rendered.plainLines![i], style: codeStyle, strutStyle: strut, maxLines: 1, softWrap: false),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _measureCharWidth(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: 'MMMMMMMMMM', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width / 10;
    painter.dispose();
    return width;
  }

  /// A light panel (near-white / near-black) rather than the mid-grey
  /// surfaceContainerHighest, which left syntax colors at ~2:1 contrast.
  BoxDecoration _codePanelDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surfaceContainerLow,
      border: Border.all(color: colorScheme.outlineVariant),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    );
  }

  Widget _buildHeaders(ColorScheme colorScheme, HttpResponse resp) {
    if (resp.headers.isEmpty) {
      return Center(
        child: Text('No response headers', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    final codeStyle = codeTextStyle(color: colorScheme.onSurface);

    return Container(
      decoration: _codePanelDecoration(colorScheme),
      clipBehavior: Clip.antiAlias,
      // Plain Text inside one SelectionArea so a drag can select across rows.
      child: SelectionArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: resp.headers.length,
          itemBuilder: (context, i) {
            final key = resp.headers.keys.elementAt(i);
            final value = resp.headers[key]!;
            return Container(
              color: i.isOdd ? colorScheme.onSurface.withValues(alpha: 0.04) : null,
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(key, style: codeStyle.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(value, style: codeStyle.copyWith(color: colorScheme.onSurfaceVariant)),
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
