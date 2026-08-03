import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

import '../../../core/http/http_client.dart';
import '../../../core/models/request_model.dart';
import '../../../core/providers/http_client_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/response_view.dart';
import '../../../shared/widgets/toast_helper.dart';

class RequestScreen extends ConsumerStatefulWidget {
  final RequestModel? initialRequest;

  const RequestScreen({super.key, this.initialRequest});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  String _selectedMethod = 'GET';
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _requestNameController = TextEditingController();
  int _selectedTab = 0;
  int _selectedBodyType = 0;
  int _selectedAuthType = 0;
  bool _isSending = false;
  HttpResponse? _lastResponse;
  String? _currentRequestId;

  final _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
  final _bodyTypes = ['None', 'JSON', 'Form Data', 'Raw'];
  final _authTypes = ['None', 'Bearer', 'Basic', 'API Key'];

  late final List<KeyValueEntry> _params;
  late final List<KeyValueEntry> _headers;

  // Auth controllers
  final _bearerTokenController = TextEditingController();
  final _basicUserController = TextEditingController();
  final _basicPassController = TextEditingController();
  final _apiKeyNameController = TextEditingController();
  final _apiKeyValueController = TextEditingController();
  String _apiKeyLocation = 'header'; // header or query

  @override
  void initState() {
    super.initState();
    _params = [KeyValueEntry()];
    _headers = [KeyValueEntry()];
    if (widget.initialRequest != null) {
      _loadFromRequest(widget.initialRequest!);
    }
  }

  void _loadFromRequest(RequestModel req) {
    _currentRequestId = req.id;
    _selectedMethod = req.method;
    _urlController.text = req.url;
    _bodyController.text = req.body ?? '';
    _requestNameController.text = req.name;
    if (req.bodyType == 'json') {
      _selectedBodyType = 1;
    } else if (req.bodyType == 'form') {
      _selectedBodyType = 2;
    } else if (req.bodyType == 'raw') {
      _selectedBodyType = 3;
    } else {
      _selectedBodyType = 0;
    }
    _params
      ..clear()
      ..addAll(mapToEntries(req.queryParams));
    if (_params.isEmpty) _params.add(KeyValueEntry());
    _headers
      ..clear()
      ..addAll(mapToEntries(req.headers));
    if (_headers.isEmpty) _headers.add(KeyValueEntry());
  }

  @override
  void didUpdateWidget(covariant RequestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRequest != null && widget.initialRequest != oldWidget.initialRequest) {
      setState(() => _loadFromRequest(widget.initialRequest!));
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    _requestNameController.dispose();
    _bearerTokenController.dispose();
    _basicUserController.dispose();
    _basicPassController.dispose();
    _apiKeyNameController.dispose();
    _apiKeyValueController.dispose();
    for (final e in _params) {
      e.dispose();
    }
    for (final e in _headers) {
      e.dispose();
    }
    super.dispose();
  }

  Map<String, String> _buildAuthHeaders() {
    switch (_selectedAuthType) {
      case 1: // Bearer
        final token = _bearerTokenController.text.trim();
        if (token.isNotEmpty) return {'Authorization': 'Bearer $token'};
        break;
      case 2: // Basic
        final user = _basicUserController.text.trim();
        final pass = _basicPassController.text;
        if (user.isNotEmpty) {
          final encoded = base64Encode(utf8.encode('$user:$pass'));
          return {'Authorization': 'Basic $encoded'};
        }
        break;
      case 3: // API Key (header mode)
        if (_apiKeyLocation == 'header') {
          final name = _apiKeyNameController.text.trim();
          final value = _apiKeyValueController.text.trim();
          if (name.isNotEmpty && value.isNotEmpty) return {name: value};
        }
        break;
    }
    return {};
  }

  Map<String, String> _buildQueryParams() {
    final params = entriesToMap(_params);
    if (_selectedAuthType == 3 && _apiKeyLocation == 'query') {
      final name = _apiKeyNameController.text.trim();
      final value = _apiKeyValueController.text.trim();
      if (name.isNotEmpty && value.isNotEmpty) params[name] = value;
    }
    return params;
  }

  Future<void> _sendRequest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() { _isSending = true; _lastResponse = null; });

    try {
      final variables = ref.read(activeVariablesProvider);
      final resolvedUrl = substituteVariables(url, variables);

      final headers = entriesToMap(_headers);
      headers.addAll(_buildAuthHeaders());
      final resolvedHeaders = headers.map((k, v) => MapEntry(k, substituteVariables(v, variables)));

      final queryParams = _buildQueryParams().map((k, v) => MapEntry(k, substituteVariables(v, variables)));

      String? body;
      if (_selectedBodyType > 0 && _bodyController.text.isNotEmpty) {
        body = substituteVariables(_bodyController.text, variables);
      }

      final client = ref.read(httpClientProvider);
      final response = await client.sendRequest(
        method: _selectedMethod,
        url: resolvedUrl,
        headers: resolvedHeaders,
        queryParams: queryParams,
        body: body,
      );

      setState(() => _lastResponse = response);

      // Save to history
      final historyRepo = ref.read(historyRepositoryProvider);
      await historyRepo.addEntry(
        requestId: _currentRequestId,
        method: _selectedMethod,
        url: resolvedUrl,
        statusCode: response.statusCode,
        responseTimeMs: response.timeMs,
        responseSize: response.sizeBytes,
        responseBody: response.body,
      );
      ref.invalidate(historyProvider);
    } catch (e) {
      if (mounted) {
        showDbugToast(context, message: 'Request failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _saveRequest() async {
    final name = _requestNameController.text.trim().isNotEmpty
        ? _requestNameController.text.trim()
        : '$_selectedMethod ${_urlController.text.trim()}';
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    String? bodyType;
    if (_selectedBodyType == 1) {
      bodyType = 'json';
    } else if (_selectedBodyType == 2) {
      bodyType = 'form';
    } else if (_selectedBodyType == 3) {
      bodyType = 'raw';
    }

    final requestRepo = ref.read(requestRepositoryProvider);
    final headers = entriesToMap(_headers);
    final queryParams = entriesToMap(_params);

    if (_currentRequestId != null) {
      final existing = await requestRepo.getRequest(_currentRequestId!);
      if (existing != null) {
        final updated = existing.copyWith(
          name: name,
          method: _selectedMethod,
          url: url,
          headers: headers,
          bodyType: bodyType,
          body: _selectedBodyType > 0 ? _bodyController.text : null,
          queryParams: queryParams,
          updatedAt: DateTime.now(),
        );
        await requestRepo.updateRequest(updated);
      }
    } else {
      final req = await requestRepo.createRequest(
        name: name,
        method: _selectedMethod,
        url: url,
        headers: headers,
        bodyType: bodyType,
        body: _selectedBodyType > 0 ? _bodyController.text : null,
        queryParams: queryParams,
      );
      setState(() => _currentRequestId = req.id);
    }

    ref.invalidate(collectionsProvider);

    if (mounted) {
      showDbugToast(context, message: 'Request saved', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = shad.Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.initialRequest != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.api, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.initialRequest!.name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.foreground),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          _buildMethodUrlBar(colorScheme),
          const SizedBox(height: 12),
          _buildTabs(colorScheme),
          const SizedBox(height: 10),
          Expanded(child: _lastResponse != null ? _buildResponseSplit(colorScheme) : _buildTabContent(colorScheme)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: shad.Button.primary(
                  onPressed: _isSending ? null : _sendRequest,
                  leading: _isSending
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, size: 14),
                  child: Text(_isSending ? 'Sending...' : 'Send'),
                ),
              ),
              const SizedBox(width: 8),
              shad.Button.outline(
                onPressed: _saveRequest,
                leading: const Icon(Icons.save_outlined, size: 14),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseSplit(shad.ColorScheme colorScheme) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: _buildTabContent(colorScheme),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
            const Spacer(),
            shad.IconButton.ghost(
              icon: const Icon(Icons.close, size: 14),
              onPressed: () => setState(() => _lastResponse = null),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 1,
          child: ResponseView(response: _lastResponse!),
        ),
      ],
    );
  }

  Widget _buildMethodUrlBar(shad.ColorScheme colorScheme) {
    return Row(
      children: [
        shad.Select<String>(
          value: _selectedMethod,
          onChanged: (v) { if (v != null) setState(() => _selectedMethod = v); },
          itemBuilder: (context, value) => Text(value, style: TextStyle(color: _methodColor(value), fontWeight: FontWeight.w600, fontSize: 12)),
          popup: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: _methods.map((m) => shad.SelectItemButton<String>(
              value: m,
              child: Text(m, style: TextStyle(color: _methodColor(m), fontWeight: FontWeight.w600, fontSize: 12)),
            )).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: shad.TextField(
            controller: _urlController,
            placeholder: const Text('Enter URL (supports {{variables}})'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(shad.ColorScheme colorScheme) {
    return shad.Tabs(
      index: _selectedTab,
      onChanged: (i) => setState(() => _selectedTab = i),
      children: const [
        shad.TabItem(child: Text('Params')),
        shad.TabItem(child: Text('Headers')),
        shad.TabItem(child: Text('Body')),
        shad.TabItem(child: Text('Auth')),
      ],
    );
  }

  Widget _buildTabContent(shad.ColorScheme colorScheme) {
    switch (_selectedTab) {
      case 0: return _buildParamsTab(colorScheme);
      case 1: return _buildHeadersTab(colorScheme);
      case 2: return _buildBodyTab(colorScheme);
      case 3: return _buildAuthTab(colorScheme);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildParamsTab(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: KeyValueEditor(entries: _params, keyHint: 'Parameter', valueHint: 'Value', onChanged: () => setState(() {})),
        ),
      ),
    );
  }

  Widget _buildHeadersTab(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: KeyValueEditor(entries: _headers, keyHint: 'Header', valueHint: 'Value', onChanged: () => setState(() {})),
        ),
      ),
    );
  }

  Widget _buildBodyTab(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: List.generate(_bodyTypes.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _selectedBodyType == i
                      ? shad.Button.primary(
                          onPressed: () => setState(() => _selectedBodyType = i),
                          child: Text(_bodyTypes[i], style: const TextStyle(fontSize: 11)),
                        )
                      : shad.Button.outline(
                          onPressed: () => setState(() => _selectedBodyType = i),
                          child: Text(_bodyTypes[i], style: const TextStyle(fontSize: 11)),
                        ),
                );
              }),
            ),
            const SizedBox(height: 10),
            if (_selectedBodyType > 0)
              Expanded(
                child: shad.TextField(
                  controller: _bodyController,
                  placeholder: Text(_selectedBodyType == 1 ? '{\n  "key": "value"\n}' : 'Request body...'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text('No body', style: TextStyle(color: colorScheme.mutedForeground)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthTab(shad.ColorScheme colorScheme) {
    return shad.Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: List.generate(_authTypes.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _selectedAuthType == i
                        ? shad.Button.primary(
                            onPressed: () => setState(() => _selectedAuthType = i),
                            child: Text(_authTypes[i], style: const TextStyle(fontSize: 11)),
                          )
                        : shad.Button.outline(
                            onPressed: () => setState(() => _selectedAuthType = i),
                            child: Text(_authTypes[i], style: const TextStyle(fontSize: 11)),
                          ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (_selectedAuthType == 1) ...[
                Text('Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.foreground)),
                const SizedBox(height: 6),
                shad.TextField(controller: _bearerTokenController, placeholder: const Text('Enter bearer token')),
              ] else if (_selectedAuthType == 2) ...[
                Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.foreground)),
                const SizedBox(height: 6),
                shad.TextField(controller: _basicUserController, placeholder: const Text('Username')),
                const SizedBox(height: 12),
                Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.foreground)),
                const SizedBox(height: 6),
                shad.TextField(controller: _basicPassController, placeholder: const Text('Password')),
              ] else if (_selectedAuthType == 3) ...[
                Text('Key Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.foreground)),
                const SizedBox(height: 6),
                shad.TextField(controller: _apiKeyNameController, placeholder: const Text('X-API-Key')),
                const SizedBox(height: 12),
                Text('Key Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.foreground)),
                const SizedBox(height: 6),
                shad.TextField(controller: _apiKeyValueController, placeholder: const Text('Your API key')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Add to:', style: TextStyle(fontSize: 12, color: colorScheme.foreground)),
                    const SizedBox(width: 8),
                    _apiKeyLocation == 'header'
                        ? shad.Button.primary(onPressed: () => setState(() => _apiKeyLocation = 'header'), child: const Text('Header', style: TextStyle(fontSize: 11)))
                        : shad.Button.outline(onPressed: () => setState(() => _apiKeyLocation = 'header'), child: const Text('Header', style: TextStyle(fontSize: 11))),
                    const SizedBox(width: 4),
                    _apiKeyLocation == 'query'
                        ? shad.Button.primary(onPressed: () => setState(() => _apiKeyLocation = 'query'), child: const Text('Query Param', style: TextStyle(fontSize: 11)))
                        : shad.Button.outline(onPressed: () => setState(() => _apiKeyLocation = 'query'), child: const Text('Query Param', style: TextStyle(fontSize: 11))),
                  ],
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No authentication', style: TextStyle(color: colorScheme.mutedForeground)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _methodColor(String method) {
    const colors = {
      'GET': Color(0xFF22C55E), 'POST': Color(0xFF3B82F6), 'PUT': Color(0xFFF59E0B),
      'PATCH': Color(0xFFF97316), 'DELETE': Color(0xFFEF4444), 'HEAD': Color(0xFF8B5CF6),
      'OPTIONS': Color(0xFF6B7280),
    };
    return colors[method] ?? const Color(0xFF6B7280);
  }
}
