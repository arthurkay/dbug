import 'dart:convert';

import 'package:flutter/foundation.dart' show mapEquals;

import '../../shared/utils/body_type_helpers.dart';
import '../models/auth_config.dart';
import '../providers/active_environment_provider.dart' show substituteVariables;

/// What actually goes over the wire for one send.
class ComposedRequest {
  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String? body;

  const ComposedRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParams,
    this.body,
  });
}

/// Builds the outgoing request from the builder's inputs.
///
/// Headers merge in this order, later entries winning: collection global
/// headers → request headers → auth headers. Request auth replaces collection
/// auth whenever its type isn't `none` (even with blank fields, which then
/// send nothing). `{{var}}` placeholders are substituted in the URL, header
/// and query values, and the body.
ComposedRequest composeRequest({
  required String method,
  required String url,
  Map<String, String> params = const {},
  Map<String, String> headers = const {},
  String? bodyType,
  String? body,
  AuthConfig auth = AuthConfig.none,
  Map<String, String> collectionHeaders = const {},
  AuthConfig collectionAuth = AuthConfig.none,
  Map<String, String> variables = const {},
}) {
  String sub(String s) => substituteVariables(s, variables);

  final effectiveAuth = auth.type != AuthType.none ? auth : collectionAuth;

  final mergedHeaders = <String, String>{
    ...collectionHeaders,
    ...headers,
    ...effectiveAuth.headers(),
  }.map((k, v) => MapEntry(k, sub(v)));

  final query = <String, String>{...params};
  if (auth.type != AuthType.none) {
    query.addAll(auth.queryParams());
  } else {
    // Collection key only fills in; it never overrides a user param.
    for (final e in collectionAuth.queryParams().entries) {
      query.putIfAbsent(e.key, () => e.value);
    }
  }

  String? outBody;
  final type = bodyType;
  if (type != null && type != 'none' && body != null && body.isNotEmpty) {
    outBody = sub(body);
    if (type == 'form') outBody = encodeFormBody(outBody);
    final hasContentType =
        mergedHeaders.keys.any((k) => k.toLowerCase() == 'content-type');
    if (!hasContentType) {
      mergedHeaders['Content-Type'] = switch (type) {
        'json' => 'application/json',
        'form' => 'application/x-www-form-urlencoded',
        _ => 'text/plain',
      };
    }
  }

  return ComposedRequest(
    method: method.toUpperCase(),
    url: sub(url.trim()),
    headers: mergedHeaders,
    queryParams: query.map((k, v) => MapEntry(k, sub(v))),
    body: outBody,
  );
}

/// Encodes `key=value` lines (one field per line) as
/// application/x-www-form-urlencoded. Blank lines are skipped; a line
/// without `=` becomes a key with an empty value.
String encodeFormBody(String raw) {
  final pairs = <String>[];
  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final eq = trimmed.indexOf('=');
    final key = eq >= 0 ? trimmed.substring(0, eq) : trimmed;
    final value = eq >= 0 ? trimmed.substring(eq + 1) : '';
    pairs.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}');
  }
  return pairs.join('&');
}

/// The last response shown in the builder, kept with the draft.
class ResponseSnapshot {
  final int statusCode;
  final String body;
  final int timeMs;
  final int sizeBytes;
  final Map<String, String> headers;

  const ResponseSnapshot({
    required this.statusCode,
    required this.body,
    this.timeMs = 0,
    this.sizeBytes = 0,
    this.headers = const {},
  });
}

/// The request builder's editable state, persisted between sessions.
///
/// The JSON shape is shared with earlier versions: `bodyType` is the body-type
/// index, `headers`/`params` are JSON-encoded strings, and auth is
/// `authType` + `authData`. Older drafts stored `authType` as an index and
/// each credential under its own key (`bearerToken`, `basicUser`, …); those
/// are still read.
class RequestDraft {
  final String method;
  final String url;
  final String name;
  final String? bodyType;
  final String body;
  final Map<String, String> headers;
  final Map<String, String> params;
  final AuthConfig auth;
  final int tab;
  final String? collectionId;
  final String? requestId;
  final ResponseSnapshot? response;

  const RequestDraft({
    this.method = 'GET',
    this.url = '',
    this.name = '',
    this.bodyType,
    this.body = '',
    this.headers = const {},
    this.params = const {},
    this.auth = AuthConfig.none,
    this.tab = 0,
    this.collectionId,
    this.requestId,
    this.response,
  });

  /// Whether [other] describes the same request (what Save would persist);
  /// ignores UI state such as the selected tab and the last response.
  bool sameRequestAs(RequestDraft other) =>
      method == other.method &&
      url == other.url &&
      name == other.name &&
      (bodyType ?? 'none') == (other.bodyType ?? 'none') &&
      // The body only matters when a body type sends it.
      ((bodyType ?? 'none') == 'none' || body == other.body) &&
      mapEquals(headers, other.headers) &&
      mapEquals(params, other.params) &&
      auth == other.auth;

  RequestDraft copyWith({
    String? method,
    String? url,
    String? name,
    String? bodyType,
    String? body,
    Map<String, String>? headers,
    Map<String, String>? params,
    AuthConfig? auth,
    int? tab,
    String? collectionId,
    String? requestId,
    ResponseSnapshot? response,
  }) {
    return RequestDraft(
      method: method ?? this.method,
      url: url ?? this.url,
      name: name ?? this.name,
      bodyType: bodyType ?? this.bodyType,
      body: body ?? this.body,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      auth: auth ?? this.auth,
      tab: tab ?? this.tab,
      collectionId: collectionId ?? this.collectionId,
      requestId: requestId ?? this.requestId,
      response: response ?? this.response,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'url': url,
        'body': body,
        'requestName': name,
        'tab': tab,
        'bodyType': bodyTypeStringToIndex(bodyType),
        'authType': auth.storedType,
        'authData': auth.storedData,
        'apiKeyLocation': auth.apiKeyLocation.name,
        'headers': jsonEncode(headers),
        'params': jsonEncode(params),
        'collectionId': collectionId,
        'currentRequestId': requestId,
        'response': response == null
            ? null
            : {
                'statusCode': response!.statusCode,
                'body': response!.body,
                'timeMs': response!.timeMs,
                'sizeBytes': response!.sizeBytes,
                'headers': response!.headers,
              },
      };

  factory RequestDraft.fromJson(Map<String, dynamic> json) {
    Map<String, String> stringMap(dynamic raw) {
      try {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        }
      } catch (_) {}
      return {};
    }

    String str(String key) => json[key]?.toString() ?? '';

    AuthConfig auth;
    final rawType = json['authType'];
    final rawData = json['authData'];
    if (rawType is String && rawData is String && rawData != '{}') {
      auth = AuthConfig.fromStored(rawType, rawData);
    } else {
      // Legacy shape: type as a string or an index, credentials per key.
      final type = rawType is int
          ? (rawType >= 0 && rawType < AuthType.values.length
              ? AuthType.values[rawType]
              : AuthType.none)
          : AuthType.fromStored(rawType?.toString());
      auth = AuthConfig(
        type: type,
        token: str('bearerToken'),
        username: str('basicUser'),
        password: str('basicPass'),
        apiKeyName: str('apiKeyName'),
        apiKeyValue: str('apiKeyValue'),
      );
    }
    if (json['apiKeyLocation'] == 'query') {
      auth = auth.copyWith(apiKeyLocation: ApiKeyLocation.query);
    }

    final rawBodyType = json['bodyType'];
    final bodyType = rawBodyType is int
        ? bodyTypeIndexToString(rawBodyType)
        : (rawBodyType is String ? rawBodyType : null);

    ResponseSnapshot? response;
    final resp = json['response'];
    if (resp is Map && resp['statusCode'] is int) {
      response = ResponseSnapshot(
        statusCode: resp['statusCode'] as int,
        body: resp['body']?.toString() ?? '',
        timeMs: (resp['timeMs'] as num?)?.toInt() ?? 0,
        sizeBytes: (resp['sizeBytes'] as num?)?.toInt() ?? 0,
        headers: stringMap(resp['headers']),
      );
    }

    final tab = json['tab'];
    return RequestDraft(
      method: json['method']?.toString() ?? 'GET',
      url: str('url'),
      name: str('requestName'),
      bodyType: bodyType,
      body: str('body'),
      headers: stringMap(json['headers']),
      params: stringMap(json['params']),
      auth: auth,
      tab: (tab is int ? tab : 0).clamp(0, 3),
      collectionId: json['collectionId'] as String?,
      requestId: json['currentRequestId'] as String?,
      response: response,
    );
  }
}
