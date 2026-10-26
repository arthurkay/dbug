import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show DatabaseException;

import '../../../core/models/mock_endpoint.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../shared/utils/method_colors.dart';
import '../../../shared/utils/syntax_highlighter.dart';
import '../../../shared/widgets/key_value_editor.dart';

const _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
const _statusPresets = [200, 201, 204, 301, 302, 400, 401, 403, 404, 409, 422, 500, 502, 503];

/// Creates a mock endpoint, or edits [existing]. Returns true when saved.
Future<bool> showMockEndpointDialog(BuildContext context, {MockEndpoint? existing}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _MockEndpointDialog(existing: existing),
  );
  return saved == true;
}

class _MockEndpointDialog extends ConsumerStatefulWidget {
  final MockEndpoint? existing;

  const _MockEndpointDialog({this.existing});

  @override
  ConsumerState<_MockEndpointDialog> createState() => _MockEndpointDialogState();
}

class _MockEndpointDialogState extends ConsumerState<_MockEndpointDialog> {
  late String _method;
  late final TextEditingController _path;
  late final TextEditingController _status;
  late final TextEditingController _delay;
  late final TextEditingController _body;
  late final List<KeyValueEntry> _headers;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _method = e?.method.toUpperCase() ?? 'GET';
    _path = TextEditingController(text: e?.path ?? '/api/');
    _status = TextEditingController(text: '${e?.statusCode ?? 200}');
    _delay = TextEditingController(text: '${e?.delayMs ?? 0}');
    _body = TextEditingController(text: e?.body ?? '{"status": "ok"}');
    _headers = mapToEntries(e?.headers ?? const {});
    if (_headers.isEmpty) _headers.add(KeyValueEntry());
  }

  @override
  void dispose() {
    _path.dispose();
    _status.dispose();
    _delay.dispose();
    _body.dispose();
    for (final h in _headers) {
      h.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    var path = _path.text.trim();
    final status = int.tryParse(_status.text.trim());
    final delay = int.tryParse(_delay.text.trim()) ?? 0;

    if (path.isEmpty) return setState(() => _error = 'Enter a path');
    if (!path.startsWith('/')) path = '/$path';
    if (status == null || status < 100 || status > 599) {
      return setState(() => _error = 'Status code must be between 100 and 599');
    }
    if (delay < 0 || delay > 120000) {
      return setState(() => _error = 'Delay must be between 0 and 120000 ms');
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(mockEndpointRepositoryProvider);
    final headers = entriesToMap(_headers);
    final body = _body.text;
    try {
      if (_isEdit) {
        await repo.updateEndpoint(widget.existing!.copyWith(
          method: _method,
          path: path,
          statusCode: status,
          headers: headers,
          body: body,
          delayMs: delay,
        ));
      } else {
        await repo.createEndpoint(
          method: _method,
          path: path,
          statusCode: status,
          headers: headers,
          body: body,
          delayMs: delay,
        );
      }
      ref.invalidate(mockEndpointsProvider);
      if (mounted) Navigator.pop(context, true);
    } on DatabaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.isUniqueConstraintError()
            ? 'An endpoint for $_method $path already exists'
            : 'Failed to save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface);

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Mock Endpoint' : 'Add Mock Endpoint'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final m in _methods)
                    ChoiceChip(
                      label: Text(m, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: methodColor(m))),
                      selected: _method == m,
                      onSelected: (_) => setState(() => _method = m),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Path', style: labelStyle),
              const SizedBox(height: 4),
              TextField(
                controller: _path,
                autofocus: !_isEdit,
                style: TextStyle(fontFamily: codeFontFamily, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '/api/users/:id',
                  helperText: 'Use :name or {name} for path parameters; reference them in the body as {{params.name}}',
                  helperMaxLines: 2,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Status code', style: labelStyle),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _status,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                          decoration: InputDecoration(
                            isDense: true,
                            suffixIcon: PopupMenuButton<int>(
                              tooltip: 'Common status codes',
                              icon: const Icon(Icons.arrow_drop_down),
                              onSelected: (c) => setState(() => _status.text = '$c'),
                              itemBuilder: (_) => [
                                for (final c in _statusPresets) PopupMenuItem(value: c, child: Text('$c')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Delay (ms)', style: labelStyle),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _delay,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Response headers', style: labelStyle),
              const SizedBox(height: 4),
              KeyValueEditor(entries: _headers, keyHint: 'Header', valueHint: 'Value'),
              const SizedBox(height: 12),
              Text('Response body', style: labelStyle),
              const SizedBox(height: 4),
              TextField(
                controller: _body,
                minLines: 6,
                maxLines: 14,
                style: codeTextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration(isDense: true),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_isEdit ? 'Save' : 'Add')),
      ],
    );
  }
}
