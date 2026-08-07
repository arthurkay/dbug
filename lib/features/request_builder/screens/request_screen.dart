import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/http/http_client.dart';
import '../../../core/models/request_model.dart';
import '../../../core/models/history_entry.dart';
import '../../../core/providers/http_client_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/response_view.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/utils/method_colors.dart';
import '../../../shared/utils/body_type_helpers.dart';
import '../../../core/providers/window_title_provider.dart';

class RequestScreen extends ConsumerStatefulWidget {
  final RequestModel? initialRequest;
  final Map<String, String> collectionHeaders;
  final String? collectionId;
  final String? collectionAuthType;
  final String? collectionAuthData;
  final HistoryEntry? historyEntry;
  final String? prefillMethod;
  final String? prefillUrl;
  final String? prefillSpecId;

  const RequestScreen({
    super.key,
    this.initialRequest,
    this.collectionHeaders = const {},
    this.collectionId,
    this.collectionAuthType,
    this.collectionAuthData,
    this.historyEntry,
    this.prefillMethod,
    this.prefillUrl,
    this.prefillSpecId,
  });

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> with TickerProviderStateMixin {
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
  bool _showEndpointList = true;
  String _endpointSearchQuery = '';
  double _responseSplitRatio = 0.5;

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
    _loadSplitRatio();
    _params = [KeyValueEntry()];
    _headers = [KeyValueEntry()];
    ref.read(windowTitleProvider.notifier).state = 'Request Builder';
    if (widget.prefillMethod != null) _selectedMethod = widget.prefillMethod!;
    if (widget.prefillUrl != null) _urlController.text = widget.prefillUrl!;
    if (widget.historyEntry != null) {
      _loadFromHistoryEntry(widget.historyEntry!);
    } else if (widget.initialRequest != null) {
      _loadFromRequest(widget.initialRequest!);
    } else {
      _loadBuilderState();
    }
  }

  static const _kBuilderStateKey = 'request_builder_state';

  Future<void> _saveBuilderState() async {
    final params = entriesToMap(_params);
    final headers = entriesToMap(_headers);

    String authType = 'none';
    String authData = '{}';
    if (_selectedAuthType == 1) {
      authType = 'bearer';
      authData = jsonEncode({'token': _bearerTokenController.text});
    } else if (_selectedAuthType == 2) {
      authType = 'basic';
      authData = jsonEncode({'username': _basicUserController.text, 'password': _basicPassController.text});
    } else if (_selectedAuthType == 3) {
      authType = 'apikey';
      authData = jsonEncode({'name': _apiKeyNameController.text, 'value': _apiKeyValueController.text, 'location': _apiKeyLocation});
    }

    final state = {
      'method': _selectedMethod,
      'url': _urlController.text,
      'body': _bodyController.text,
      'requestName': _requestNameController.text,
      'tab': _selectedTab,
      'bodyType': _selectedBodyType,
      'authType': authType,
      'authData': authData,
      'headers': jsonEncode(headers),
      'params': jsonEncode(params),
      'collectionId': widget.collectionId,
      'collectionHeaders': jsonEncode(widget.collectionHeaders),
      'currentRequestId': _currentRequestId,
      'bearerToken': _bearerTokenController.text,
      'basicUser': _basicUserController.text,
      'basicPass': _basicPassController.text,
      'apiKeyName': _apiKeyNameController.text,
      'apiKeyValue': _apiKeyValueController.text,
      'apiKeyLocation': _apiKeyLocation,
      'response': _lastResponse != null ? {
        'statusCode': _lastResponse!.statusCode,
        'body': _lastResponse!.body,
        'timeMs': _lastResponse!.timeMs,
        'sizeBytes': _lastResponse!.sizeBytes,
      } : null,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBuilderStateKey, jsonEncode(state));
  }

  Future<void> _loadBuilderState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kBuilderStateKey);
      if (raw == null || !mounted) return;

      final state = jsonDecode(raw) as Map<String, dynamic>;

      _selectedMethod = state['method'] ?? 'GET';
      _urlController.text = state['url'] ?? '';
      _bodyController.text = state['body'] ?? '';
      _requestNameController.text = state['requestName'] ?? '';
      _selectedTab = state['tab'] ?? 0;
      _selectedBodyType = state['bodyType'] ?? 0;
      _currentRequestId = state['currentRequestId'];
      _apiKeyLocation = state['apiKeyLocation'] ?? 'header';

      final savedAuthType = state['authType'];
      if (savedAuthType is String) {
        switch (savedAuthType) {
          case 'bearer': _selectedAuthType = 1; break;
          case 'basic': _selectedAuthType = 2; break;
          case 'apikey': _selectedAuthType = 3; break;
          default: _selectedAuthType = 0;
        }
      } else {
        _selectedAuthType = savedAuthType ?? 0;
      }

      final savedAuthData = state['authData'];
      if (savedAuthData is String && savedAuthData != '{}') {
        try {
          final data = jsonDecode(savedAuthData) as Map<String, dynamic>;
          _bearerTokenController.text = data['token'] ?? '';
          _basicUserController.text = data['username'] ?? '';
          _basicPassController.text = data['password'] ?? '';
          _apiKeyNameController.text = data['name'] ?? '';
          _apiKeyValueController.text = data['value'] ?? '';
          if (data['location'] != null) _apiKeyLocation = data['location'];
        } catch (e) { debugPrint('Failed to parse auth data: $e'); }
      } else {
        _bearerTokenController.text = state['bearerToken'] ?? '';
        _basicUserController.text = state['basicUser'] ?? '';
        _basicPassController.text = state['basicPass'] ?? '';
        _apiKeyNameController.text = state['apiKeyName'] ?? '';
        _apiKeyValueController.text = state['apiKeyValue'] ?? '';
      }

      try {
        final headersMap = Map<String, String>.from(jsonDecode(state['headers'] ?? '{}'));
        _headers..clear()..addAll(mapToEntries(headersMap));
      } catch (e) {
        debugPrint('Failed to parse headers: $e');
        _headers.clear();
      }
      if (_headers.isEmpty) _headers.add(KeyValueEntry());

      try {
        final paramsMap = Map<String, String>.from(jsonDecode(state['params'] ?? '{}'));
        _params..clear()..addAll(mapToEntries(paramsMap));
      } catch (e) {
        debugPrint('Failed to parse params: $e');
        _params.clear();
      }
      if (_params.isEmpty) _params.add(KeyValueEntry());

      final resp = state['response'];
      if (resp != null && resp['statusCode'] != null) {
        _lastResponse = HttpResponse(
          statusCode: resp['statusCode'],
          headers: const {},
          body: resp['body'] ?? '',
          timeMs: resp['timeMs'] ?? 0,
          sizeBytes: resp['sizeBytes'] ?? 0,
        );
      }

      if (mounted) setState(() {});
    } catch (e) { debugPrint('Failed to load saved request state: $e'); }
  }

  Future<void> _loadSplitRatio() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('response_split_ratio');
    if (saved != null && mounted) {
      setState(() => _responseSplitRatio = saved.clamp(0.2, 0.8));
    }
  }

  void _saveSplitRatio() {
    SharedPreferences.getInstance().then((prefs) =>
      prefs.setDouble('response_split_ratio', _responseSplitRatio));
  }

  void _loadFromHistoryEntry(HistoryEntry entry) {
    _selectedMethod = entry.method;
    _urlController.text = entry.url;
    _bodyController.text = entry.body ?? '';
    _requestNameController.text = entry.requestName ?? '';
    ref.read(windowTitleProvider.notifier).state = entry.requestName?.isNotEmpty == true ? entry.requestName! : 'Request Builder';

    // Restore body type
    _selectedBodyType = bodyTypeStringToIndex(entry.bodyType);

    // Restore headers
    try {
      final headersMap = Map<String, String>.from(jsonDecode(entry.headers));
      _headers..clear()..addAll(mapToEntries(headersMap));
    } catch (e) {
      debugPrint('Failed to parse history headers: $e');
      _headers.clear();
    }
    if (_headers.isEmpty) _headers.add(KeyValueEntry());

    // Restore query params
    try {
      final paramsMap = Map<String, String>.from(jsonDecode(entry.queryParams));
      _params..clear()..addAll(mapToEntries(paramsMap));
    } catch (e) {
      debugPrint('Failed to parse history params: $e');
      _params.clear();
    }
    if (_params.isEmpty) _params.add(KeyValueEntry());

    // Restore auth type
    switch (entry.authType) {
      case 'bearer':
        _selectedAuthType = 1;
        try {
          final data = jsonDecode(entry.authData);
          _bearerTokenController.text = data['token'] ?? '';
        } catch (e) { debugPrint('Failed to parse bearer auth: $e'); }
        break;
      case 'basic':
        _selectedAuthType = 2;
        try {
          final data = jsonDecode(entry.authData);
          _basicUserController.text = data['username'] ?? '';
          _basicPassController.text = data['password'] ?? '';
        } catch (e) { debugPrint('Failed to parse basic auth: $e'); }
        break;
      case 'apikey':
        _selectedAuthType = 3;
        try {
          final data = jsonDecode(entry.authData);
          _apiKeyNameController.text = data['name'] ?? '';
          _apiKeyValueController.text = data['value'] ?? '';
          _apiKeyLocation = data['location'] ?? 'header';
        } catch (e) { debugPrint('Failed to parse apikey auth: $e'); }
        break;
      default:
        _selectedAuthType = 0;
    }
  }

  void _loadFromRequest(RequestModel req) {
    _currentRequestId = req.id;
    _selectedMethod = req.method;
    _urlController.text = req.url;
    _bodyController.text = req.body ?? '';
    _requestNameController.text = req.name;
    _selectedBodyType = bodyTypeStringToIndex(req.bodyType);
    _params
      ..clear()
      ..addAll(mapToEntries(req.queryParams));
    if (_params.isEmpty) _params.add(KeyValueEntry());
    _headers
      ..clear()
      ..addAll(mapToEntries(req.headers));
    if (_headers.isEmpty) _headers.add(KeyValueEntry());
    ref.read(windowTitleProvider.notifier).state = req.name.isNotEmpty ? req.name : 'Request Builder';
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
    _saveBuilderState();
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
    // Request-level auth takes precedence
    if (_selectedAuthType != 0) {
      switch (_selectedAuthType) {
        case 1:
          final token = _bearerTokenController.text.trim();
          if (token.isNotEmpty) return {'Authorization': 'Bearer $token'};
          break;
        case 2:
          final user = _basicUserController.text.trim();
          final pass = _basicPassController.text;
          if (user.isNotEmpty) {
            final encoded = base64Encode(utf8.encode('$user:$pass'));
            return {'Authorization': 'Basic $encoded'};
          }
          break;
        case 3:
          if (_apiKeyLocation == 'header') {
            final name = _apiKeyNameController.text.trim();
            final value = _apiKeyValueController.text.trim();
            if (name.isNotEmpty && value.isNotEmpty) return {name: value};
          }
          break;
      }
      return {};
    }

    // Fall back to collection auth
    if (widget.collectionAuthType == null || widget.collectionAuthType == 'none') return {};
    try {
      final data = Map<String, dynamic>.from(jsonDecode(widget.collectionAuthData ?? '{}'));
      switch (widget.collectionAuthType) {
        case 'bearer':
          final token = (data['token'] as String?) ?? '';
          if (token.isNotEmpty) return {'Authorization': 'Bearer $token'};
          break;
        case 'basic':
          final user = (data['username'] as String?) ?? '';
          final pass = (data['password'] as String?) ?? '';
          if (user.isNotEmpty) {
            final encoded = base64Encode(utf8.encode('$user:$pass'));
            return {'Authorization': 'Basic $encoded'};
          }
          break;
        case 'apikey':
          final location = data['location'] ?? 'header';
          if (location == 'header') {
            final name = (data['name'] as String?) ?? '';
            final value = (data['value'] as String?) ?? '';
            if (name.isNotEmpty && value.isNotEmpty) return {name: value};
          }
          break;
      }
    } catch (_) {}
    return {};
  }

  Map<String, String> _buildQueryParams() {
    final params = entriesToMap(_params);

    // Request-level API key query param
    if (_selectedAuthType == 3 && _apiKeyLocation == 'query') {
      final name = _apiKeyNameController.text.trim();
      final value = _apiKeyValueController.text.trim();
      if (name.isNotEmpty && value.isNotEmpty) params[name] = value;
    }

    // Collection-level API key query param (only if request doesn't override)
    if (_selectedAuthType == 0 && widget.collectionAuthType == 'apikey') {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(widget.collectionAuthData ?? '{}'));
        if (data['location'] == 'query') {
          final name = (data['name'] as String?) ?? '';
          final value = (data['value'] as String?) ?? '';
          if (name.isNotEmpty && value.isNotEmpty && !params.containsKey(name)) {
            params[name] = value;
          }
        }
      } catch (_) {}
    }

    return params;
  }

  Future<void> _sendRequest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      if (mounted) showDbugToast(context, message: 'Enter a URL to send', type: ToastType.warning);
      return;
    }

    setState(() { _isSending = true; _lastResponse = null; });

    try {
      final variables = ref.read(activeVariablesProvider);
      final resolvedUrl = substituteVariables(url, variables);

      final headers = <String, String>{};
      headers.addAll(widget.collectionHeaders);
      headers.addAll(entriesToMap(_headers));
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

      // Build auth data for history
      String authType = 'none';
      String authData = '{}';
      if (_selectedAuthType == 1) {
        authType = 'bearer';
        authData = jsonEncode({'token': _bearerTokenController.text.trim()});
      } else if (_selectedAuthType == 2) {
        authType = 'basic';
        authData = jsonEncode({'username': _basicUserController.text.trim(), 'password': _basicPassController.text});
      } else if (_selectedAuthType == 3) {
        authType = 'apikey';
        authData = jsonEncode({'name': _apiKeyNameController.text.trim(), 'value': _apiKeyValueController.text.trim(), 'location': _apiKeyLocation});
      }

      final bodyType = bodyTypeIndexToString(_selectedBodyType);

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
        requestName: _requestNameController.text.trim().isNotEmpty
            ? _requestNameController.text.trim()
            : '$_selectedMethod $resolvedUrl',
        collectionId: widget.collectionId,
        headers: jsonEncode(entriesToMap(_headers)),
        collectionHeaders: jsonEncode(widget.collectionHeaders),
        body: _selectedBodyType > 0 ? _bodyController.text : null,
        bodyType: bodyType,
        queryParams: jsonEncode(_buildQueryParams()),
        authType: authType,
        authData: authData,
      );
      ref.invalidate(historyProvider);
      _saveBuilderState();
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

    final bodyType = bodyTypeIndexToString(_selectedBodyType);

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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_showEndpointList && widget.collectionId != null) ...[
            _buildEndpointList(colorScheme),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.initialRequest != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (widget.collectionId != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              icon: Icon(_showEndpointList ? LucideIcons.panelLeftOpen : LucideIcons.panelLeftClose, size: 18, color: colorScheme.onSurfaceVariant),
                              onPressed: () => setState(() => _showEndpointList = !_showEndpointList),
                            ),
                          ),
                        Icon(LucideIcons.globe, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _requestNameController.text.isNotEmpty
                                ? _requestNameController.text
                                : widget.initialRequest?.name ?? '',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
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
                      child: FilledButton.icon(
                        onPressed: _isSending ? null : _sendRequest,
                        icon: _isSending
                            ? const SizedBox(width: 14, height: 14, child: DbugSpinner(strokeWidth: 2, color: Color(0xFFFFFFFF)))
                            : const Icon(LucideIcons.send, size: 14),
                        label: Text(_isSending ? 'Sending...' : 'Send'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _saveRequest,
                      icon: const Icon(LucideIcons.save, size: 14),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointList(ColorScheme colorScheme) {
    final requestsAsync = ref.watch(requestsByCollectionProvider(widget.collectionId!));

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(LucideIcons.list, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text('Endpoints', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search endpoints...', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              onChanged: (v) => setState(() => _endpointSearchQuery = v),
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: SizedBox(width: 16, height: 16, child: DbugSpinner(strokeWidth: 2))),
              error: (e, _) =>                         Center(child: Text('Error', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))),
              data: (requests) {
                if (requests.isEmpty) {
                  return                     Center(child: Text('No requests', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)));
                }
                final filtered = _endpointSearchQuery.isEmpty
                    ? requests
                    : requests.where((r) {
                        final q = _endpointSearchQuery.toLowerCase();
                        return r.name.toLowerCase().contains(q) ||
                            r.method.toLowerCase().contains(q) ||
                            r.url.toLowerCase().contains(q);
                      }).toList();
                if (filtered.isEmpty) {
                  return                     Center(child: Text('No matching endpoints', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final req = filtered[i];
                    final isActive = req.id == _currentRequestId;
                    return GestureDetector(
                      onTap: () => _switchToRequest(req),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        color: isActive ? colorScheme.surfaceContainerHighest : null,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: methodColor(req.method).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(req.method, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: methodColor(req.method)), textAlign: TextAlign.center),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                req.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? colorScheme.primary : colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _switchToRequest(RequestModel req) {
    setState(() {
      _currentRequestId = req.id;
      _selectedMethod = req.method;
      _urlController.text = req.url;
      _bodyController.text = req.body ?? '';
      _requestNameController.text = req.name;
      _lastResponse = null;
      _selectedBodyType = bodyTypeStringToIndex(req.bodyType);
      _params
        ..clear()
        ..addAll(mapToEntries(req.queryParams));
      if (_params.isEmpty) _params.add(KeyValueEntry());
      _headers
        ..clear()
        ..addAll(mapToEntries(req.headers));
      if (_headers.isEmpty) _headers.add(KeyValueEntry());
    });
    ref.read(windowTitleProvider.notifier).state = req.name.isNotEmpty ? req.name : 'Request Builder';
    _saveBuilderState();
  }

  Widget _buildResponseSplit(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final dividerHeight = 8.0;
        final topHeight = (totalHeight - dividerHeight) * _responseSplitRatio;

        return Column(
          children: [
            SizedBox(
              height: topHeight.clamp(80.0, totalHeight - 80 - dividerHeight),
              child: _buildTabContent(colorScheme),
            ),
            GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _responseSplitRatio += details.delta.dy / totalHeight;
                  _responseSplitRatio = _responseSplitRatio.clamp(0.2, 0.8);
                });
                _saveSplitRatio();
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: Container(
                  height: dividerHeight,
                  color: const Color(0x00000000),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text('Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 14),
                        onPressed: () => setState(() => _lastResponse = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: ResponseView(response: _lastResponse!)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMethodUrlBar(ColorScheme colorScheme) {
    return Row(
      children: [
        DropdownButton<String>(
          value: _selectedMethod,
          underline: const SizedBox.shrink(),
          isDense: true,
          items: _methods.map((m) => DropdownMenuItem(
            value: m,
            child: Text(m, style: TextStyle(color: methodColor(m), fontWeight: FontWeight.w600, fontSize: 12)),
          )).toList(),
          onChanged: (v) { if (v != null) setState(() => _selectedMethod = v); },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _UrlTooltip(
            tooltipText: _buildResolvedUrlPreview,
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(hintText: 'Enter URL (supports {{variables}})', isDense: true),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  String _buildResolvedUrlPreview() {
    final raw = _urlController.text;
    if (raw.isEmpty) return 'Enter URL (supports {{variables}})';
    final variables = ref.read(activeVariablesProvider);
    if (variables.isEmpty) return raw;
    final resolved = substituteVariables(raw, variables);
    if (resolved == raw) return raw;
    return '$raw\n→ $resolved';
  }

  Widget _buildTabs(ColorScheme colorScheme) {
    return TabBar(
      controller: TabController(length: 4, vsync: this, initialIndex: _selectedTab),
      onTap: (i) => setState(() => _selectedTab = i),
      tabs: const [
        Tab(text: 'Params'),
        Tab(text: 'Headers'),
        Tab(text: 'Body'),
        Tab(text: 'Auth'),
      ],
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildTabContent(ColorScheme colorScheme) {
    switch (_selectedTab) {
      case 0: return _buildParamsTab(colorScheme);
      case 1: return _buildHeadersTab(colorScheme);
      case 2: return _buildBodyTab(colorScheme);
      case 3: return _buildAuthTab(colorScheme);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildParamsTab(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: KeyValueEditor(entries: _params, keyHint: 'Parameter', valueHint: 'Value', onChanged: () => setState(() {})),
        ),
      ),
    );
  }

  Widget _buildHeadersTab(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.collectionHeaders.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.key, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text('Collection Headers (inherited)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...widget.collectionHeaders.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: 'monospace')),
                          Text(': ', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                          Expanded(child: Text(e.value, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: KeyValueEditor(entries: _headers, keyHint: 'Header', valueHint: 'Value', onChanged: () => setState(() {})),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyTab(ColorScheme colorScheme) {
    return Card(
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
                      ? FilledButton.tonal(
                          onPressed: () => setState(() => _selectedBodyType = i),
                          child: Text(_bodyTypes[i], style: const TextStyle(fontSize: 11)),
                        )
                      : OutlinedButton(
                          onPressed: () => setState(() => _selectedBodyType = i),
                          child: Text(_bodyTypes[i], style: const TextStyle(fontSize: 11)),
                        ),
                );
              }),
            ),
            const SizedBox(height: 10),
            if (_selectedBodyType > 0)
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(hintText: _selectedBodyType == 1 ? '{\n  "key": "value"\n}' : 'Request body...', border: const OutlineInputBorder()),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              )
            else
              Expanded(
                child: Center(
                    child: Text('No body', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthTab(ColorScheme colorScheme) {
    return Card(
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
                        ? FilledButton.tonal(
                            onPressed: () => setState(() => _selectedAuthType = i),
                            child: Text(_authTypes[i], style: const TextStyle(fontSize: 11)),
                          )
                        : OutlinedButton(
                            onPressed: () => setState(() => _selectedAuthType = i),
                            child: Text(_authTypes[i], style: const TextStyle(fontSize: 11)),
                          ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              if (_selectedAuthType == 1) ...[
                Text('Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(controller: _bearerTokenController, decoration: const InputDecoration(hintText: 'Enter bearer token', border: OutlineInputBorder())),
              ] else if (_selectedAuthType == 2) ...[
                Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(controller: _basicUserController, decoration: const InputDecoration(hintText: 'Username', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(controller: _basicPassController, obscureText: true, decoration: const InputDecoration(hintText: 'Password', border: OutlineInputBorder())),
              ] else if (_selectedAuthType == 3) ...[
                Text('Key Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(controller: _apiKeyNameController, decoration: const InputDecoration(hintText: 'X-API-Key', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Text('Key Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                const SizedBox(height: 6),
                TextField(controller: _apiKeyValueController, decoration: const InputDecoration(hintText: 'Your API key', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Add to:', style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
                    const SizedBox(width: 8),
                    _apiKeyLocation == 'header'
                        ? FilledButton.tonal(onPressed: () => setState(() => _apiKeyLocation = 'header'), child: const Text('Header', style: TextStyle(fontSize: 11)))
                        : OutlinedButton(onPressed: () => setState(() => _apiKeyLocation = 'header'), child: const Text('Header', style: TextStyle(fontSize: 11))),
                    const SizedBox(width: 4),
                    _apiKeyLocation == 'query'
                        ? FilledButton.tonal(onPressed: () => setState(() => _apiKeyLocation = 'query'), child: const Text('Query Param', style: TextStyle(fontSize: 11)))
                        : OutlinedButton(onPressed: () => setState(() => _apiKeyLocation = 'query'), child: const Text('Query Param', style: TextStyle(fontSize: 11))),
                  ],
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No authentication', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UrlTooltip extends StatefulWidget {
  final String Function() tooltipText;
  final Widget child;

  const _UrlTooltip({required this.tooltipText, required this.child});

  @override
  State<_UrlTooltip> createState() => _UrlTooltipState();
}

class _UrlTooltipState extends State<_UrlTooltip> {
  OverlayEntry? _overlayEntry;
  Offset _mousePos = Offset.zero;

  void _showOverlay() {
    final text = widget.tooltipText();
    if (text.isEmpty) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: _mousePos.dx + 12,
        top: _mousePos.dy - 8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onInverseSurface, fontFamily: 'monospace'),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showOverlay(),
      onHover: (e) {
        _mousePos = e.position;
        _overlayEntry?.markNeedsBuild();
      },
      onExit: (_) => _removeOverlay(),
      child: widget.child,
    );
  }
}
