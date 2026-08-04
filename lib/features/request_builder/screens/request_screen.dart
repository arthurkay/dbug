import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shadcn_flutter/shadcn_flutter.dart' show LucideIcons;

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

class RequestScreen extends ConsumerStatefulWidget {
  final RequestModel? initialRequest;
  final Map<String, String> collectionHeaders;
  final String? collectionId;
  final HistoryEntry? historyEntry;

  const RequestScreen({super.key, this.initialRequest, this.collectionHeaders = const {}, this.collectionId, this.historyEntry});

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
    if (widget.historyEntry != null) {
      _loadFromHistoryEntry(widget.historyEntry!);
    } else if (widget.initialRequest != null) {
      _loadFromRequest(widget.initialRequest!);
    }
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

    // Restore body type
    if (entry.bodyType == 'json') {
      _selectedBodyType = 1;
    } else if (entry.bodyType == 'form') {
      _selectedBodyType = 2;
    } else if (entry.bodyType == 'raw') {
      _selectedBodyType = 3;
    } else {
      _selectedBodyType = 0;
    }

    // Restore headers
    try {
      final headersMap = Map<String, String>.from(jsonDecode(entry.headers));
      _headers..clear()..addAll(mapToEntries(headersMap));
    } catch (_) {
      _headers.clear();
    }
    if (_headers.isEmpty) _headers.add(KeyValueEntry());

    // Restore query params
    try {
      final paramsMap = Map<String, String>.from(jsonDecode(entry.queryParams));
      _params..clear()..addAll(mapToEntries(paramsMap));
    } catch (_) {
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
        } catch (_) {}
        break;
      case 'basic':
        _selectedAuthType = 2;
        try {
          final data = jsonDecode(entry.authData);
          _basicUserController.text = data['username'] ?? '';
          _basicPassController.text = data['password'] ?? '';
        } catch (_) {}
        break;
      case 'apikey':
        _selectedAuthType = 3;
        try {
          final data = jsonDecode(entry.authData);
          _apiKeyNameController.text = data['name'] ?? '';
          _apiKeyValueController.text = data['value'] ?? '';
          _apiKeyLocation = data['location'] ?? 'header';
        } catch (_) {}
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

      String? bodyType;
      if (_selectedBodyType == 1) {
        bodyType = 'json';
      } else if (_selectedBodyType == 2) {
        bodyType = 'form';
      } else if (_selectedBodyType == 3) {
        bodyType = 'raw';
      }

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
                            child: shad.IconButton.ghost(
                              icon: Icon(_showEndpointList ? LucideIcons.panelLeftOpen : LucideIcons.panelLeftClose, size: 18, color: colorScheme.mutedForeground),
                              onPressed: () => setState(() => _showEndpointList = !_showEndpointList),
                            ),
                          ),
                        Icon(LucideIcons.globe, size: 14, color: colorScheme.primary),
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
                            ? const SizedBox(width: 14, height: 14, child: DbugSpinner(strokeWidth: 2, color: Color(0xFFFFFFFF)))
                            : const Icon(LucideIcons.send, size: 14),
                        child: Text(_isSending ? 'Sending...' : 'Send'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    shad.Button.outline(
                      onPressed: _saveRequest,
                      leading: const Icon(LucideIcons.save, size: 14),
                      child: const Text('Save'),
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

  Widget _buildEndpointList(shad.ColorScheme colorScheme) {
    final requestsAsync = ref.watch(requestsByCollectionProvider(widget.collectionId!));

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.border.withValues(alpha: 0.5)),
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
                Text('Endpoints', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: shad.TextField(
              placeholder: const Text('Search endpoints...'),
              onChanged: (v) => setState(() => _endpointSearchQuery = v),
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: colorScheme.border.withValues(alpha: 0.5)),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(child: SizedBox(width: 16, height: 16, child: DbugSpinner(strokeWidth: 2))),
              error: (e, _) => Center(child: Text('Error', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground))),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(child: Text('No requests', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)));
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
                  return Center(child: Text('No matching endpoints', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)));
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
                        color: isActive ? colorScheme.primary.withValues(alpha: 0.08) : null,
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
                                  color: isActive ? colorScheme.primary : colorScheme.foreground,
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
    });
  }

  Widget _buildResponseSplit(shad.ColorScheme colorScheme) {
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
                        color: colorScheme.border,
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
                      Text('Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.foreground)),
                      const Spacer(),
                      shad.IconButton.ghost(
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

  Widget _buildMethodUrlBar(shad.ColorScheme colorScheme) {
    return Row(
      children: [
        shad.Select<String>(
          value: _selectedMethod,
          onChanged: (v) { if (v != null) setState(() => _selectedMethod = v); },
          itemBuilder: (context, value) => Text(value, style: TextStyle(color: methodColor(value), fontWeight: FontWeight.w600, fontSize: 12)),
          popup: (context) => shad.SelectPopup<String>(
            items: shad.SelectItemList(
              children: _methods.map((m) => shad.SelectItemButton<String>(
                value: m,
                child: Text(m, style: TextStyle(color: methodColor(m), fontWeight: FontWeight.w600, fontSize: 12)),
              )).toList(),
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.collectionHeaders.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.key, size: 12, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text('Collection Headers (inherited)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.primary, letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...widget.collectionHeaders.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.foreground, fontFamily: 'monospace')),
                          Text(': ', style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground)),
                          Expanded(child: Text(e.value, style: TextStyle(fontSize: 11, color: colorScheme.mutedForeground, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
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

}
