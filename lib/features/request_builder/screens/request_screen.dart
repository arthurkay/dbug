import 'dart:convert';
import 'package:dio/dio.dart' show CancelToken, DioException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/security/secret_cipher.dart';
import '../../../core/http/http_client.dart';
import '../../../core/models/auth_config.dart';
import '../../../core/models/collection_model.dart';
import '../../../core/models/history_entry.dart';
import '../../../core/models/request_model.dart';
import '../../../core/providers/active_environment_provider.dart';
import '../../../core/providers/http_client_provider.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/window_title_provider.dart';
import '../../../core/request/request_composer.dart';
import '../../../shared/utils/body_type_helpers.dart';
import '../../../shared/utils/method_colors.dart';
import '../../../shared/utils/syntax_highlighter.dart';
import '../../../shared/widgets/auth_editor.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/widgets/dbug_spinner.dart';
import '../../../shared/widgets/json_body_editor.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../../../shared/widgets/response_view.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../collections/widgets/collection_settings_dialog.dart';

/// Seals a request-builder draft saved before encryption existed. Drafts are
/// otherwise only rewritten when the request screen saves, which would leave
/// the old plaintext credentials on disk until then.
Future<void> sealLegacyRequestDraft() async {
  if (Secrets.isLocked) return;
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_RequestScreenState._kBuilderStateKey);
  if (raw == null || SecretCipher.isSealed(raw)) return;
  await prefs.setString(_RequestScreenState._kBuilderStateKey, Secrets.cipher.seal(raw));
}

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

class _RequestScreenState extends ConsumerState<RequestScreen>
    with TickerProviderStateMixin {
  String _selectedMethod = 'GET';
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _requestNameController = TextEditingController();
  int _selectedTab = 0;
  int _selectedBodyType = 0;
  AuthConfig _auth = AuthConfig.none;
  bool _isSending = false;
  CancelToken? _cancelToken;
  HttpResponse? _lastResponse;
  String? _currentRequestId;
  bool _showEndpointList = true;
  String _endpointSearchQuery = '';
  double _responseSplitRatio = 0.5;

  /// The request as last loaded or saved; edits are compared against it to
  /// warn before they're discarded.
  RequestDraft? _cleanSnapshot;

  final _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
  final _bodyTypes = ['None', 'JSON', 'Form Data', 'Raw'];

  late final TabController _tabController;

  late final List<KeyValueEntry> _params;
  late final List<KeyValueEntry> _headers;

  /// Responses larger than this aren't kept in the persisted draft.
  static const _maxPersistedResponseChars = 256 * 1024;

  @override
  void initState() {
    super.initState();
    // Creating the settings notifier applies the saved history limits.
    ref.read(settingsProvider);
    _tabController = TabController(length: 4, vsync: this);
    _loadSplitRatio();
    _params = [KeyValueEntry()];
    _headers = [KeyValueEntry()];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(windowTitleProvider.notifier).state = 'Request Builder';
      }
    });
    if (widget.prefillMethod != null) _selectedMethod = widget.prefillMethod!;
    if (widget.prefillUrl != null) _urlController.text = widget.prefillUrl!;
    if (widget.historyEntry != null) {
      _loadFromHistoryEntry(widget.historyEntry!);
    } else if (widget.initialRequest != null) {
      _loadFromRequest(widget.initialRequest!);
      if (_currentRequestId != null) {
        _loadLatestHistoryForRequest(_currentRequestId!);
      }
    } else {
      _loadBuilderState();
    }
  }

  static const _kBuilderStateKey = 'request_builder_state';

  // Live collection settings: when the request belongs to a collection, the
  // current global headers/auth come from the database (kept fresh through
  // collectionByIdProvider) instead of the snapshot passed via the route.
  // Cached in a field during build — not read via ref on demand — because
  // _saveBuilderState also runs from dispose(), where ref is unusable.
  Collection? _liveCollection;
  String? _restoredCollectionId;

  String? get _collectionId => widget.collectionId ?? _restoredCollectionId;

  Map<String, String> get _collectionHeaders =>
      _liveCollection?.globalHeaders ?? widget.collectionHeaders;

  AuthConfig get _collectionAuth => AuthConfig.fromStored(
        _liveCollection?.authType ?? widget.collectionAuthType,
        _liveCollection?.authData ?? widget.collectionAuthData,
      );

  bool get _collectionAuthDefined => _collectionAuth.type != AuthType.none;

  /// True only when the collection auth would actually produce credentials —
  /// a saved auth type with blank fields sends nothing and must not claim
  /// otherwise in the UI.
  bool get _hasCollectionAuth => _collectionAuth.producesCredentials;

  /// True when this request will actually send with the collection's auth
  /// (no request-level auth is set to override it).
  bool get _usesCollectionAuth => _auth.type == AuthType.none && _hasCollectionAuth;

  Future<void> _editCollectionSettings({int initialTab = 0}) async {
    final id = _collectionId;
    if (id == null) return;
    final collection =
        await ref.read(collectionRepositoryProvider).getCollection(id);
    if (collection == null || !mounted) return;
    await showCollectionSettingsDialog(context, ref, collection,
        initialTab: initialTab);
  }

  // ---------------------------------------------------------------------------
  // Draft <-> UI

  /// The builder's current contents.
  RequestDraft _currentDraft() => RequestDraft(
        method: _selectedMethod,
        url: _urlController.text,
        name: _requestNameController.text,
        bodyType: bodyTypeIndexToString(_selectedBodyType),
        body: _bodyController.text,
        headers: entriesToMap(_headers),
        params: entriesToMap(_params),
        auth: _auth,
        tab: _selectedTab,
        collectionId: _collectionId,
        requestId: _currentRequestId,
      );

  /// Loads [draft]'s request fields into the editors (not tab/response).
  void _applyDraft(RequestDraft draft) {
    _selectedMethod = _methods.contains(draft.method) ? draft.method : 'GET';
    _urlController.text = draft.url;
    _requestNameController.text = draft.name;
    _selectedBodyType = bodyTypeStringToIndex(draft.bodyType);
    _bodyController.text = draft.body;
    _auth = draft.auth;
    _replaceEntries(_headers, draft.headers);
    _replaceEntries(_params, draft.params);
  }

  void _replaceEntries(List<KeyValueEntry> entries, Map<String, String> values) {
    // The editor's text fields still reference the old controllers until the
    // next frame rebuilds them, so dispose those afterwards.
    final old = List.of(entries);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final e in old) {
        e.dispose();
      }
    });
    entries
      ..clear()
      ..addAll(mapToEntries(values));
    if (entries.isEmpty) entries.add(KeyValueEntry());
  }

  void _markClean() => _cleanSnapshot = _currentDraft();

  bool get _hasUnsavedChanges {
    final clean = _cleanSnapshot;
    return clean != null && !clean.sameRequestAs(_currentDraft());
  }

  RequestDraft _draftFromRequest(RequestModel req) => RequestDraft(
        method: req.method,
        url: req.url,
        name: req.name,
        bodyType: req.bodyType,
        body: req.body ?? '',
        headers: req.headers,
        params: req.queryParams,
        auth: AuthConfig.fromStored(req.authType, req.authData),
      );

  static Map<String, String> _decodeStringMap(String? raw) {
    try {
      final decoded = jsonDecode(raw ?? '{}');
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } catch (e) {
      debugPrint('Failed to parse stored map: $e');
    }
    return {};
  }

  HttpResponse? _responseFromHistory(HistoryEntry entry) {
    if (entry.statusCode == null) return null;
    return HttpResponse(
      statusCode: entry.statusCode!,
      headers: _decodeStringMap(entry.responseHeaders),
      body: entry.responseBody ?? '',
      timeMs: entry.responseTimeMs ?? 0,
      sizeBytes: entry.responseSize ?? 0,
      isTruncated: entry.responseTruncated,
    );
  }

  void _setWindowTitle(String name) {
    ref.read(windowTitleProvider.notifier).state =
        name.isNotEmpty ? name : 'Request Builder';
  }

  // ---------------------------------------------------------------------------
  // Persistence of the builder draft

  Future<void> _saveBuilderState() async {
    final response = _lastResponse;
    final draft = _currentDraft().copyWith(
      response: response != null &&
              !response.isBinary &&
              response.body.length <= _maxPersistedResponseChars
          ? ResponseSnapshot(
              statusCode: response.statusCode,
              body: response.body,
              timeMs: response.timeMs,
              sizeBytes: response.sizeBytes,
              headers: response.headers,
            )
          : null,
    );
    // The draft holds credentials (auth, headers, the response), so it is
    // sealed like the database fields; while locked it isn't persisted.
    final sealed = Secrets.sealOrNull(jsonEncode(draft.toJson()));
    if (sealed == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBuilderStateKey, sealed);
  }

  Future<void> _loadBuilderState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = Secrets.cipher.open(prefs.getString(_kBuilderStateKey));
      if (raw == null || !mounted) return;

      final draft = RequestDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _applyDraft(draft);
      _selectedTab = draft.tab;
      // Restore the collection link so global headers/auth apply again after
      // a restart (the live values are then re-read via collectionByIdProvider).
      _restoredCollectionId = draft.collectionId;
      _currentRequestId = draft.requestId;
      final resp = draft.response;
      if (resp != null) {
        _lastResponse = HttpResponse(
          statusCode: resp.statusCode,
          headers: resp.headers,
          body: resp.body,
          timeMs: resp.timeMs,
          sizeBytes: resp.sizeBytes,
        );
      }
      // Moving the controller makes the scrollable TabBar scroll to the tab,
      // which throws if its viewport hasn't been laid out yet — wait a frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.index = _selectedTab;
      });
      _markClean();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load saved request state: $e');
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
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setDouble('response_split_ratio', _responseSplitRatio),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading requests and history

  RequestDraft _draftFromHistory(HistoryEntry entry) => RequestDraft(
        method: entry.method,
        url: entry.url,
        name: entry.requestName ?? '',
        bodyType: entry.bodyType,
        body: entry.body ?? '',
        headers: _decodeStringMap(entry.headers),
        params: _decodeStringMap(entry.queryParams),
        auth: AuthConfig.fromStored(entry.authType, entry.authData),
      );

  void _loadFromHistoryEntry(HistoryEntry entry) {
    _applyDraft(_draftFromHistory(entry));
    _lastResponse = _responseFromHistory(entry);
    _markClean();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setWindowTitle(entry.requestName ?? '');
    });
  }

  void _loadFromRequest(RequestModel req) {
    // An empty id marks an unsaved draft (e.g. "Send" from the spec browser);
    // it must not be treated as an existing request when saving.
    _currentRequestId = req.id.isEmpty ? null : req.id;
    _applyDraft(_draftFromRequest(req));
    _markClean();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setWindowTitle(req.name);
    });
  }

  /// Replays the request's most recent send on top of the saved request: the
  /// last-sent URL, body, headers and params, its auth when it had any, and
  /// its response. The saved name and id are kept.
  Future<void> _loadLatestHistoryForRequest(String requestId) async {
    final historyRepo = ref.read(historyRepositoryProvider);
    final latest = await historyRepo.getLatestByRequestId(requestId);
    if (!mounted || latest == null || _currentRequestId != requestId) return;
    setState(() {
      final fromHistory = _draftFromHistory(latest);
      _applyDraft(fromHistory.copyWith(
        name: _requestNameController.text,
        auth: latest.authType != 'none' ? fromHistory.auth : _auth,
      ));
      _lastResponse = _responseFromHistory(latest);
      _markClean();
    });
  }

  @override
  void didUpdateWidget(covariant RequestScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRequest != null &&
        widget.initialRequest != oldWidget.initialRequest) {
      setState(() => _loadFromRequest(widget.initialRequest!));
    }
  }

  @override
  void dispose() {
    _saveBuilderState();
    _tabController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _requestNameController.dispose();
    for (final e in _params) {
      e.dispose();
    }
    for (final e in _headers) {
      e.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Sending

  void _cancelSend() => _cancelToken?.cancel('Cancelled by user');

  Future<void> _sendRequest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      showDbugToast(context, message: 'Enter a URL to send', type: ToastType.warning);
      return;
    }

    final cancelToken = CancelToken();
    setState(() {
      _isSending = true;
      _cancelToken = cancelToken;
      _lastResponse = null;
    });

    // Read everything that needs ref up front: the screen may be left while
    // the request is in flight, and the send should still land in history.
    final draft = _currentDraft();
    final composed = composeRequest(
      method: draft.method,
      url: draft.url,
      params: draft.params,
      headers: draft.headers,
      bodyType: draft.bodyType,
      body: draft.body,
      auth: draft.auth,
      collectionHeaders: _collectionHeaders,
      collectionAuth: _collectionAuth,
      variables: ref.read(requestVariablesProvider(_collectionId)),
    );
    final client = ref.read(httpClientProvider);
    final historyRepo = ref.read(historyRepositoryProvider);
    final collectionHeaders = _collectionHeaders;

    try {
      final response = await client.sendRequest(
        method: composed.method,
        url: composed.url,
        headers: composed.headers,
        queryParams: composed.queryParams,
        body: composed.body,
        cancelToken: cancelToken,
      );

      if (mounted) setState(() => _lastResponse = response);

      await historyRepo.addEntry(
        requestId: draft.requestId,
        method: composed.method,
        // Keep the {{var}} template; the resolved URL is stored separately so
        // env values (possibly secrets) aren't baked into replays.
        url: url,
        resolvedUrl: composed.url,
        statusCode: response.statusCode,
        responseTimeMs: response.timeMs,
        responseSize: response.sizeBytes,
        responseBody: response.body,
        responseHeaders: response.headers,
        requestName: draft.name.trim().isNotEmpty ? draft.name.trim() : '${composed.method} $url',
        collectionId: draft.collectionId,
        headers: jsonEncode(draft.headers),
        collectionHeaders: jsonEncode(collectionHeaders),
        body: draft.bodyType != null ? draft.body : null,
        bodyType: draft.bodyType,
        // Only the user's own params: auth-derived API keys are rebuilt from
        // authType/authData (or the collection) when the entry is restored,
        // and must not be baked in as plain request params.
        queryParams: jsonEncode(draft.params),
        authType: draft.auth.storedType,
        authData: draft.auth.storedData,
      );
      if (mounted) {
        ref.invalidate(historyProvider);
        _saveBuilderState();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (CancelToken.isCancel(e)) {
        showDbugToast(context, message: 'Request cancelled', type: ToastType.info);
      } else {
        showDbugToast(context, message: 'Request failed: ${e.message}', type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        showDbugToast(context, message: 'Request failed: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _cancelToken = null;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Saving

  /// Saves the request; returns false when nothing was saved (no URL, or the
  /// collection picker was cancelled).
  Future<bool> _saveRequest() async {
    final draft = _currentDraft();
    final url = draft.url.trim();
    if (url.isEmpty) {
      showDbugToast(context, message: 'Enter a URL to save', type: ToastType.warning);
      return false;
    }
    final name = draft.name.trim().isNotEmpty ? draft.name.trim() : '$_selectedMethod $url';
    final body = draft.bodyType != null ? draft.body : null;

    final requestRepo = ref.read(requestRepositoryProvider);

    // The saved request may have been deleted since it was opened; fall back
    // to saving it as a new one instead of silently doing nothing.
    final existing = _currentRequestId != null
        ? await requestRepo.getRequest(_currentRequestId!)
        : null;

    if (existing != null) {
      await requestRepo.updateRequest(existing.copyWith(
        name: name,
        method: _selectedMethod,
        url: url,
        headers: draft.headers,
        bodyType: draft.bodyType,
        body: body,
        queryParams: draft.params,
        authType: draft.auth.storedType,
        authData: draft.auth.storedData,
        updatedAt: DateTime.now(),
      ));
      if (!mounted) return true;
      ref.invalidate(collectionsProvider);
      if (existing.collectionId != null) {
        ref.invalidate(requestsByCollectionProvider(existing.collectionId!));
      }
      _markClean();
      showDbugToast(context, message: 'Request saved', type: ToastType.success);
      return true;
    }

    final collections = await ref.read(collectionRepositoryProvider).getAllCollections();
    if (!mounted) return false;

    String? collectionId;
    if (collections.isNotEmpty) {
      collectionId = await showCollectionPickerDialog(
        context,
        collections: collections,
        initialId: _collectionId,
      );
      if (collectionId == null || !mounted) return false;
    }

    final req = await requestRepo.createRequest(
      collectionId: collectionId,
      name: name,
      method: _selectedMethod,
      url: url,
      headers: draft.headers,
      bodyType: draft.bodyType,
      body: body,
      queryParams: draft.params,
      authType: draft.auth.storedType,
      authData: draft.auth.storedData,
    );
    if (!mounted) return true;
    setState(() {
      _currentRequestId = req.id;
      if (collectionId != null && widget.collectionId == null) _restoredCollectionId = collectionId;
    });
    ref.invalidate(collectionsProvider);
    if (collectionId != null) {
      ref.invalidate(requestsByCollectionProvider(collectionId));
    }
    _markClean();
    showDbugToast(
      context,
      message: collectionId != null ? 'Saved to collection' : 'Request saved',
      type: ToastType.success,
    );
    return true;
  }

  /// Asks what to do with unsaved edits. Returns true when it's fine to move
  /// on (saved or discarded).
  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('This request has changes that haven\'t been saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'discard'), child: const Text('Discard')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save')),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'discard') return true;
    if (choice == 'save') return _saveRequest();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Rebuild when the collection's global headers/auth are edited, keeping
    // the last known value while a refresh is in flight.
    final collectionId = _collectionId;
    if (collectionId != null) {
      final live = ref.watch(collectionByIdProvider(collectionId)).valueOrNull;
      if (live != null) _liveCollection = live;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_showEndpointList && _collectionId != null) ...[
            _buildEndpointList(colorScheme),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.initialRequest != null || _collectionId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        if (_collectionId != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              icon: Icon(
                                _showEndpointList
                                    ? LucideIcons.panelLeftOpen
                                    : LucideIcons.panelLeftClose,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => setState(
                                () => _showEndpointList = !_showEndpointList,
                              ),
                            ),
                          ),
                        if (_liveCollection != null) ...[
                          Icon(LucideIcons.folder, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _liveCollection!.name,
                              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(LucideIcons.chevronRight, size: 14, color: colorScheme.onSurfaceVariant),
                          ),
                        ] else ...[
                          Icon(LucideIcons.globe, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            _requestNameController.text.isNotEmpty
                                ? _requestNameController.text
                                : widget.initialRequest?.name ?? (_currentRequestId == null ? 'Unsaved request' : ''),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildMethodUrlBar(colorScheme),
                _buildResolvedUrlLine(colorScheme),
                const SizedBox(height: 12),
                _buildTabs(colorScheme),
                const SizedBox(height: 10),
                Expanded(
                  child: _lastResponse != null
                      ? _buildResponseSplit(colorScheme)
                      : _buildTabContent(colorScheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointList(ColorScheme colorScheme) {
    final requestsAsync = ref.watch(
      requestsByCollectionProvider(_collectionId!),
    );

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                Icon(LucideIcons.folderOpen, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _liveCollection?.name ?? 'Collection',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${requestsAsync.valueOrNull?.length ?? 0} endpoints',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Collection settings (headers, auth)',
                  icon: const Icon(LucideIcons.settings2, size: 15),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editCollectionSettings(),
                ),
                IconButton(
                  tooltip: 'Add a request to this collection',
                  icon: const Icon(LucideIcons.plus, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _addRequestToCollection(_collectionId!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search endpoints...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              onChanged: (v) => setState(() => _endpointSearchQuery = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: requestsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: DbugSpinner(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      'No requests',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
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
                  return Center(
                    child: Text(
                      'No matching endpoints',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final req = filtered[i];
                    final isActive = req.id == _currentRequestId;
                    return GestureDetector(
                      onTap: () => _switchToRequest(req),
                      onSecondaryTapUp: (d) => _showEndpointMenuAt(req, d.globalPosition),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? colorScheme.surfaceContainerHighest : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: methodColor(
                                  req.method,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                req.method,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: methodColor(req.method),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                req.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isActive
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: PopupMenuButton<String>(
                                tooltip: 'Edit, duplicate or delete',
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                                icon: Icon(LucideIcons.ellipsis, size: 14, color: colorScheme.onSurfaceVariant),
                                itemBuilder: (_) => _endpointMenuItems(),
                                onSelected: (action) => _onEndpointAction(req, action),
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

  /// Creates a request in [collectionId] from a name + method dialog and
  /// opens it. The URL starts with `{{baseUrl}}/` when the collection's
  /// requests use it, so the environment supplies the host.
  Future<void> _addRequestToCollection(String collectionId) async {
    if (!await _confirmDiscardChanges() || !mounted) return;

    final existing = ref.read(requestsByCollectionProvider(collectionId)).valueOrNull ?? const [];
    final usesBaseUrl = existing.any((r) => r.url.toLowerCase().startsWith('{{baseurl}}'));
    final result = await showDialog<({String name, String method})>(
      context: context,
      builder: (ctx) => _NewRequestDialog(collectionName: _liveCollection?.name),
    );
    if (result == null || !mounted) return;

    final req = await ref.read(requestRepositoryProvider).createRequest(
      collectionId: collectionId,
      name: result.name,
      method: result.method,
      url: usesBaseUrl ? '{{baseUrl}}/' : '',
    );
    if (!mounted) return;
    ref.invalidate(requestsByCollectionProvider(collectionId));
    ref.invalidate(collectionsProvider);
    setState(() {
      _currentRequestId = req.id;
      _lastResponse = null;
      _applyDraft(_draftFromRequest(req));
      _markClean();
    });
    _setWindowTitle(req.name);
    _saveBuilderState();
    showDbugToast(context, message: 'Added "${req.name}" to ${_liveCollection?.name ?? 'the collection'}', type: ToastType.success);
  }

  List<PopupMenuEntry<String>> _endpointMenuItems() => const [
        PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(LucideIcons.pencil, size: 16), title: Text('Rename / change method'))),
        PopupMenuItem(value: 'duplicate', child: ListTile(dense: true, leading: Icon(LucideIcons.copy, size: 16), title: Text('Duplicate'))),
        PopupMenuDivider(),
        PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(LucideIcons.trash2, size: 16), title: Text('Delete'))),
      ];

  Future<void> _showEndpointMenuAt(RequestModel req, Offset position) async {
    // showMenu positions relative to the navigator's overlay, which starts
    // beside the sidebar, not at the window origin; convert the click.
    final overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final local = overlay.globalToLocal(position);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(local & Size.zero, Offset.zero & overlay.size),
      items: _endpointMenuItems(),
    );
    if (action != null && mounted) await _onEndpointAction(req, action);
  }

  Future<void> _onEndpointAction(RequestModel req, String action) async {
    final repo = ref.read(requestRepositoryProvider);
    void refresh() {
      if (req.collectionId != null) ref.invalidate(requestsByCollectionProvider(req.collectionId!));
      ref.invalidate(collectionsProvider);
    }

    switch (action) {
      case 'edit':
        final result = await showDialog<({String name, String method})>(
          context: context,
          builder: (_) => _NewRequestDialog(initialName: req.name, initialMethod: req.method),
        );
        if (result == null || !mounted) return;
        if (result.name == req.name && result.method == req.method) return;
        await repo.updateRequest(req.copyWith(name: result.name, method: result.method, updatedAt: DateTime.now()));
        if (!mounted) return;
        refresh();
        if (req.id == _currentRequestId) {
          // Update the open request too, keeping any other unsaved edits
          // marked as unsaved.
          setState(() {
            _requestNameController.text = result.name;
            if (_methods.contains(result.method)) _selectedMethod = result.method;
            _cleanSnapshot = _cleanSnapshot?.copyWith(name: result.name, method: result.method);
          });
          _setWindowTitle(result.name);
          _saveBuilderState();
        }
      case 'duplicate':
        final copy = await repo.createRequest(
          collectionId: req.collectionId,
          name: '${req.name} (copy)',
          method: req.method,
          url: req.url,
          headers: req.headers,
          bodyType: req.bodyType,
          body: req.body,
          queryParams: req.queryParams,
          authType: req.authType,
          authData: req.authData,
        );
        if (!mounted) return;
        refresh();
        await _switchToRequest(copy);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete request'),
            content: Text('Delete "${req.name}" from ${_liveCollection?.name ?? 'the collection'}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        await repo.deleteRequest(req.id);
        if (!mounted) return;
        refresh();
        if (req.id == _currentRequestId) {
          // Keep the builder contents as an unsaved request.
          setState(() => _currentRequestId = null);
          _saveBuilderState();
        }
        showDbugToast(context, message: 'Deleted "${req.name}"', type: ToastType.success);
    }
  }

  Future<void> _switchToRequest(RequestModel req) async {
    if (req.id == _currentRequestId) return;
    if (!await _confirmDiscardChanges() || !mounted) return;
    setState(() {
      _currentRequestId = req.id;
      _lastResponse = null;
      _applyDraft(_draftFromRequest(req));
      _markClean();
    });
    _setWindowTitle(req.name);
    _saveBuilderState();
    _loadLatestHistoryForRequest(req.id);
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
                      Text(
                        'Response',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
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
    final method = methodColor(_selectedMethod);
    return Row(
      children: [
        // Method, URL and Send read as one control, like a browser address bar.
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                PopupMenuButton<String>(
                  tooltip: 'HTTP method',
                  initialValue: _selectedMethod,
                  onSelected: (v) => setState(() => _selectedMethod = v),
                  itemBuilder: (_) => [
                    for (final m in _methods)
                      PopupMenuItem(
                        value: m,
                        height: 34,
                        child: Text(m, style: TextStyle(color: methodColor(m), fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                  ],
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: method.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedMethod, style: TextStyle(color: method, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.3)),
                        const SizedBox(width: 4),
                        Icon(LucideIcons.chevronDown, size: 14, color: method),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _UrlTooltip(
                    tooltipText: _buildResolvedUrlPreview,
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'Enter URL (supports {{variables}})',
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                      ),
                      style: TextStyle(fontFamily: codeFontFamily, fontSize: 13),
                      onSubmitted: (_) {
                        if (!_isSending) _sendRequest();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  // Fixed width so the bar doesn't shift when Send turns into Cancel.
                  child: SizedBox(
                    width: 100,
                    height: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _isSending ? _cancelSend : _sendRequest,
                      icon: _isSending
                          ? SizedBox(
                              width: 13,
                              height: 13,
                              child: DbugSpinner(strokeWidth: 2, color: colorScheme.onPrimary),
                            )
                          : const Icon(LucideIcons.send, size: 14),
                      label: Text(_isSending ? 'Cancel' : 'Send'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          child: OutlinedButton.icon(
            onPressed: _isSending ? null : () => _saveRequest(),
            icon: const Icon(LucideIcons.save, size: 14),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }

  /// The URL as it will be sent, under the URL bar, whenever it contains
  /// `{{variables}}`; names no environment defines are called out.
  Widget _buildResolvedUrlLine(ColorScheme colorScheme) {
    final variables = ref.watch(requestVariablesProvider(_collectionId));
    final envName = ref.watch(activeEnvironmentProvider)?.name;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _urlController,
      builder: (context, value, _) {
        final raw = value.text;
        if (placeholderNames(raw).isEmpty) return const SizedBox.shrink();
        final resolved = substituteVariables(raw, variables);
        final missing = placeholderNames(resolved);
        final muted = colorScheme.onSurfaceVariant;
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
          child: Row(
            children: [
              Icon(LucideIcons.cornerDownRight, size: 13, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  resolved,
                  maxLines: 1,
                  style: TextStyle(fontFamily: codeFontFamily, fontSize: 12, color: muted),
                ),
              ),
              if (missing.isNotEmpty) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: envName == null
                      ? 'No environment is active'
                      : 'Not defined in "$envName" or the spec\'s environment',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.triangleAlert, size: 13, color: colorScheme.error),
                      const SizedBox(width: 4),
                      Text(
                        'Unset: ${missing.join(', ')}',
                        style: TextStyle(fontSize: 12, color: colorScheme.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _buildResolvedUrlPreview() {
    final raw = _urlController.text;
    if (raw.isEmpty) return 'Enter URL (supports {{variables}})';
    final variables = ref.read(requestVariablesProvider(_collectionId));
    if (variables.isEmpty) return raw;
    final resolved = substituteVariables(raw, variables);
    if (resolved == raw) return raw;
    return '$raw\n→ $resolved';
  }

  Widget _buildTabs(ColorScheme colorScheme) {
    final paramCount = _params.where((e) => e.enabled && e.isValid).length;
    final headerCount = _headers.where((e) => e.enabled && e.isValid).length;
    final globalHeaderCount = _collectionHeaders.length;
    return TabBar(
      controller: _tabController,
      onTap: (i) => setState(() => _selectedTab = i),
      tabs: [
        Tab(child: _tabLabel('Params', paramCount > 0 ? '$paramCount' : null, colorScheme)),
        Tab(
          child: _tabLabel(
            'Headers',
            headerCount + globalHeaderCount > 0 ? '${headerCount + globalHeaderCount}' : null,
            colorScheme,
            tooltip: globalHeaderCount > 0 ? '$globalHeaderCount from the collection' : null,
          ),
        ),
        Tab(child: _tabLabel('Body', _selectedBodyType > 0 ? _bodyTypes[_selectedBodyType] : null, colorScheme)),
        Tab(
          child: _tabLabel(
            'Auth',
            _auth.type != AuthType.none ? _auth.type.label : (_usesCollectionAuth ? 'Collection' : null),
            colorScheme,
          ),
        ),
      ],
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }

  /// A tab title with an optional small badge (a count or the active type).
  Widget _tabLabel(String text, String? badge, ColorScheme colorScheme, {String? tooltip}) {
    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
    return tooltip == null ? label : Tooltip(message: tooltip, child: label);
  }

  Widget _buildTabContent(ColorScheme colorScheme) {
    switch (_selectedTab) {
      case 0:
        return _buildParamsTab(colorScheme);
      case 1:
        return _buildHeadersTab(colorScheme);
      case 2:
        return _buildBodyTab(colorScheme);
      case 3:
        return _buildAuthTab(colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildParamsTab(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: KeyValueEditor(
            entries: _params,
            keyHint: 'Parameter',
            valueHint: 'Value',
            onChanged: () => setState(() {}),
          ),
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
            if (_collectionId != null ||
                _collectionHeaders.isNotEmpty) ...[
              _buildGlobalHeadersBox(colorScheme),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: KeyValueEditor(
                  entries: _headers,
                  keyHint: 'Header',
                  valueHint: 'Value',
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalHeadersBox(ColorScheme colorScheme) {
    final headers = _collectionHeaders;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.key,
                size: 12,
                color: headers.isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  headers.isNotEmpty
                      ? 'Global headers · sent with every request in this collection'
                      : 'Global headers · none defined for this collection',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_collectionId != null)
                TextButton(
                  onPressed: () => _editCollectionSettings(initialTab: 0),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          if (headers.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...headers.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        fontFamily: codeFontFamily,
                      ),
                    ),
                    Text(
                      ': ',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: codeFontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
                          onPressed: () =>
                              setState(() => _selectedBodyType = i),
                          child: Text(
                            _bodyTypes[i],
                            style: const TextStyle(fontSize: 11),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () =>
                              setState(() => _selectedBodyType = i),
                          child: Text(
                            _bodyTypes[i],
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                );
              }),
            ),
            const SizedBox(height: 10),
            if (_selectedBodyType == 1)
              Expanded(
                child: JsonBodyEditor(
                  controller: _bodyController,
                  hintText: '{\n  "key": "value"\n}',
                  contentType: 'application/json',
                ),
              )
            else if (_selectedBodyType > 0)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: TextField(
                    controller: _bodyController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: _selectedBodyType == 2
                          ? 'One field per line:\nkey=value'
                          : 'Request body...',
                      hintStyle: TextStyle(
                        fontFamily: codeFontFamily,
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                      isDense: true,
                    ),
                    style: TextStyle(fontFamily: codeFontFamily, fontSize: 13, height: 1.5),
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'No body',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalAuthBanner(ColorScheme colorScheme) {
    final String message;
    final IconData icon;
    final bool highlighted;

    if (_usesCollectionAuth) {
      final label = _collectionAuth.type.label;
      message = 'Using global $label auth from this collection';
      icon = LucideIcons.shieldCheck;
      highlighted = true;
    } else if (_hasCollectionAuth) {
      final label = _collectionAuth.type.label;
      message = "Request auth overrides this collection's global $label auth";
      icon = LucideIcons.shieldOff;
      highlighted = false;
    } else if (_collectionAuthDefined) {
      final label = _collectionAuth.type.label;
      message =
          'Global $label auth has empty credentials — nothing is applied';
      icon = LucideIcons.shieldAlert;
      highlighted = false;
    } else {
      message = 'No global auth defined for this collection';
      icon = LucideIcons.shield;
      highlighted = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlighted
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: highlighted ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _editCollectionSettings(initialTab: 1),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              _collectionAuthDefined ? 'Edit' : 'Define',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
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
              if (_collectionId != null) ...[
                _buildGlobalAuthBanner(colorScheme),
                const SizedBox(height: 12),
              ],
              AuthEditor(
                value: _auth,
                onChanged: (next) => setState(() => _auth = next),
              ),
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
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // The pointer position is global; the overlay may not start at the
        // window origin (it sits beside the sidebar), so convert first.
        // Kept on-screen near the right edge (the box is at most 400 wide).
        left: (_toOverlay(overlay).dx + 12)
            .clamp(0.0, ((overlay.context.size?.width ?? 1e6) - 410).clamp(0.0, double.infinity)),
        top: _toOverlay(overlay).dy + 18,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onInverseSurface,
                fontFamily: codeFontFamily,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  Offset _toOverlay(OverlayState overlay) {
    final box = overlay.context.findRenderObject() as RenderBox?;
    return box == null ? _mousePos : box.globalToLocal(_mousePos);
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
      onEnter: (e) {
        _mousePos = e.position;
        _showOverlay();
      },
      onHover: (e) {
        _mousePos = e.position;
        _overlayEntry?.markNeedsBuild();
      },
      onExit: (_) => _removeOverlay(),
      child: widget.child,
    );
  }
}


/// Name + method for a new request in a collection.
class _NewRequestDialog extends StatefulWidget {
  final String? collectionName;

  /// Set when editing an existing request.
  final String? initialName;
  final String? initialMethod;

  const _NewRequestDialog({this.collectionName, this.initialName, this.initialMethod});

  bool get isEdit => initialName != null;

  @override
  State<_NewRequestDialog> createState() => _NewRequestDialogState();
}

class _NewRequestDialogState extends State<_NewRequestDialog> {
  static const _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];
  late final _name = TextEditingController(text: widget.initialName);
  late String _method =
      _methods.contains(widget.initialMethod) ? widget.initialMethod! : 'GET';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name: name, method: _method));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit
          ? 'Edit request'
          : widget.collectionName != null
              ? 'New request in ${widget.collectionName}'
              : 'New request'),
      content: SizedBox(
        width: 420,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Method', isDense: true),
                items: [
                  for (final m in _methods)
                    DropdownMenuItem(
                      value: m,
                      child: Text(m, style: TextStyle(color: methodColor(m), fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                ],
                onChanged: (v) => setState(() => _method = v ?? _method),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Refund a payment', isDense: true),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _name.text.trim().isEmpty ? null : _submit,
          child: Text(widget.isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
