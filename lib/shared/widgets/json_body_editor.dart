import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/providers/syntax_theme_provider.dart';
import '../utils/syntax_highlighter.dart';
import 'toast_helper.dart';

class JsonBodyEditor extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String contentType;
  final bool isEditable;

  const JsonBodyEditor({
    super.key,
    required this.controller,
    this.hintText = '{\n  "key": "value"\n}',
    this.contentType = 'application/json',
    this.isEditable = true,
  });

  @override
  ConsumerState<JsonBodyEditor> createState() => _JsonBodyEditorState();
}

class _JsonBodyEditorState extends ConsumerState<JsonBodyEditor> {
  bool _editMode = false;
  bool _prettyView = true;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _isJson {
    final text = widget.controller.text.trimLeft();
    return text.isEmpty || text.startsWith('{') || text.startsWith('[');
  }

  String get _prettyBody {
    final text = widget.controller.text;
    if (text.isEmpty) return text;
    try {
      final parsed = jsonDecode(text);
      return const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (e) {
      return text;
    }
  }

  String get _displayBody {
    if (!_isJson) return widget.controller.text;
    return _prettyView ? _prettyBody : widget.controller.text;
  }

  void _toggleEditMode() {
    if (_editMode) {
      final pretty = _prettyBody;
      if (pretty != widget.controller.text) {
        widget.controller.text = pretty;
      }
    }
    setState(() => _editMode = !_editMode);
    if (_editMode) {
      _focusNode.requestFocus();
    }
  }

  void _formatJson() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    try {
      final parsed = jsonDecode(text);
      final formatted = const JsonEncoder.withIndent('  ').convert(parsed);
      widget.controller.text = formatted;
      setState(() {});
    } catch (e) {
      showDbugToast(context, message: 'Invalid JSON: cannot format', type: ToastType.error);
    }
  }

  void _minifyJson() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    try {
      final parsed = jsonDecode(text);
      final minified = jsonEncode(parsed);
      widget.controller.text = minified;
      setState(() {});
    } catch (e) {
      showDbugToast(context, message: 'Invalid JSON: cannot minify', type: ToastType.error);
    }
  }

  void _copyBody() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    showDbugToast(context, message: 'Copied to clipboard', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final body = widget.controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(colorScheme, body),
        const SizedBox(height: 8),
        Expanded(
          child: _editMode
              ? _buildEditor(colorScheme)
              : _buildView(colorScheme),
        ),
      ],
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme, String body) {
    return Row(
      children: [
        if (_isJson && body.isNotEmpty) ...[
          _viewToggle('Pretty', true, colorScheme),
          const SizedBox(width: 4),
          _viewToggle('Raw', false, colorScheme),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        if (widget.isEditable) ...[
          _toolbarButton(
            _editMode ? LucideIcons.eye : LucideIcons.pencil,
            _editMode ? 'View' : 'Edit',
            _toggleEditMode,
            colorScheme,
          ),
          const SizedBox(width: 4),
        ],
        if (_isJson && body.isNotEmpty && _editMode) ...[
          _toolbarButton(LucideIcons.minus, 'Minify', _minifyJson, colorScheme),
          const SizedBox(width: 4),
          _toolbarButton(LucideIcons.maximize2, 'Format', _formatJson, colorScheme),
          const SizedBox(width: 4),
        ],
        _toolbarButton(LucideIcons.copy, 'Copy', _copyBody, colorScheme),
      ],
    );
  }

  Widget _viewToggle(String label, bool isPretty, ColorScheme colorScheme) {
    final isActive = _prettyView == isPretty;
    return GestureDetector(
      onTap: () => setState(() => _prettyView = isPretty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, String tooltip, VoidCallback onTap, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(tooltip, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLineNumbers(colorScheme, widget.controller.text),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: colorScheme.onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildView(ColorScheme colorScheme) {
    final body = _displayBody;

    if (body.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.inbox, size: 28, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text('Empty body', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final lines = body.split('\n');
    final themeName = ref.watch(syntaxThemeNameProvider);
    final spans = SyntaxHighlighter.highlight(body, widget.contentType, colorScheme.brightness, themeName: themeName);

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
            _buildLineNumbers(colorScheme, body, lines: lines),
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

  Widget _buildLineNumbers(ColorScheme colorScheme, String body, {List<String>? lines}) {
    final lineCount = (lines ?? body.split('\n')).length;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(right: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Column(
        children: List.generate(lineCount, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(
            '${i + 1}',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: colorScheme.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.right,
          ),
        )),
      ),
    );
  }
}
