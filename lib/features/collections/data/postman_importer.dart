import 'dart:convert';

import '../../../core/repositories/collection_repository.dart';
import '../../../core/repositories/request_repository.dart';

class PostmanImportResult {
  /// Every collection created: the root first, then one per folder.
  final List<String> collectionIds;
  final String rootName;
  final int requestCount;

  const PostmanImportResult({
    required this.collectionIds,
    required this.rootName,
    required this.requestCount,
  });
}

/// Imports Postman v2.0/v2.1 collections. dbug collections are flat, so each
/// folder becomes its own collection named by its full path
/// ("API / Users / Admin"), inheriting the nearest auth like Postman does.
class PostmanImporter {
  final CollectionRepository collections;
  final RequestRepository requests;

  PostmanImporter({required this.collections, required this.requests});

  /// Throws [FormatException] when [content] isn't JSON or isn't a Postman
  /// collection.
  Future<PostmanImportResult> importJson(String content, {required String fileName}) async {
    final dynamic json;
    try {
      json = jsonDecode(content);
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON: ${e.message}');
    }
    if (json is! Map<String, dynamic> || json['info'] is! Map || json['item'] is! List) {
      throw const FormatException('Not a Postman collection (expected v2.0 or v2.1 format)');
    }

    final info = json['info'] as Map;
    final rootName = info['name']?.toString() ?? fileName.replaceAll(RegExp(r'\.json$'), '');
    final rootAuth = postmanAuthToDbug(json['auth']) ?? ('none', '{}');
    final ids = <String>[];
    var count = 0;

    Future<void> importFolder(String name, String? description, List items, (String, String) auth) async {
      final collection = await collections.createCollection(
        name: name,
        description: description,
        sourceType: 'postman',
        authType: auth.$1,
        authData: auth.$2,
      );
      ids.add(collection.id);

      for (final item in items.whereType<Map<String, dynamic>>()) {
        if (item['item'] is List) {
          final folderAuth = postmanAuthToDbug(item['auth']) ?? auth;
          await importFolder(
            '$name / ${item['name'] ?? 'Folder'}',
            item['description']?.toString(),
            item['item'] as List,
            folderAuth,
          );
        } else if (item['request'] != null) {
          await _importRequest(item, collection.id);
          count++;
        }
      }
    }

    await importFolder(
      rootName,
      info['description']?.toString() ?? 'Imported from $fileName',
      json['item'] as List,
      rootAuth,
    );

    return PostmanImportResult(collectionIds: ids, rootName: rootName, requestCount: count);
  }

  Future<void> _importRequest(Map<String, dynamic> item, String collectionId) async {
    // A request may be just a URL string.
    final rawReq = item['request'];
    final req = rawReq is String ? <String, dynamic>{'url': rawReq} : rawReq as Map<String, dynamic>;
    final method = (req['method'] ?? 'GET').toString().toUpperCase();

    final queryParams = <String, String>{};
    var url = '';
    final urlData = req['url'];
    if (urlData is String) {
      url = urlData;
    } else if (urlData is Map) {
      final query = (urlData['query'] as List? ?? []).whereType<Map>()
          .where((q) => q['key'] != null && q['disabled'] != true);
      for (final q in query) {
        queryParams[q['key'].toString()] = q['value']?.toString() ?? '';
      }
      url = urlData['raw']?.toString() ?? _joinUrl(urlData);
      // The query also lives in `query`; keeping it in the URL too would send
      // every parameter twice.
      if (queryParams.isNotEmpty) url = url.split('?').first;
    }

    final headers = <String, String>{};
    for (final h in (req['header'] as List? ?? []).whereType<Map>()) {
      if (h['key'] != null && h['disabled'] != true) {
        headers[h['key'].toString()] = h['value']?.toString() ?? '';
      }
    }

    String? body;
    String? bodyType;
    if (req['body'] is Map<String, dynamic>) {
      (bodyType, body) = postmanBodyToDbug(req['body'] as Map<String, dynamic>);
    }

    // No request auth (or "inherit") means: use the collection's auth, which
    // is exactly what dbug does for authType 'none'.
    final auth = postmanAuthToDbug(req['auth']) ?? ('none', '{}');

    await requests.createRequest(
      collectionId: collectionId,
      name: item['name']?.toString() ?? 'Untitled',
      method: method,
      url: url,
      headers: headers,
      bodyType: bodyType,
      body: body,
      queryParams: queryParams,
      authType: auth.$1,
      authData: auth.$2,
    );
  }

  static String _joinUrl(Map urlData) {
    final protocol = urlData['protocol']?.toString();
    final host = urlData['host'];
    final path = urlData['path'];
    final hostStr = host is List ? host.join('.') : host?.toString() ?? '';
    final pathStr = path is List ? path.join('/') : path?.toString() ?? '';
    final base = protocol != null ? '$protocol://$hostStr' : hostStr;
    return pathStr.isEmpty ? base : '$base/$pathStr';
  }
}

/// Maps a Postman body onto dbug's body types (json/form/raw). Postman's
/// `mode` names don't match ours: JSON is `raw` + `options.raw.language`,
/// and both `urlencoded` and `formdata` carry key/value lists (disabled and
/// file fields are skipped).
(String?, String?) postmanBodyToDbug(Map<String, dynamic> bodyData) {
  switch (bodyData['mode']) {
    case 'raw':
      final raw = bodyData['raw']?.toString();
      final options = bodyData['options'];
      final language = options is Map && options['raw'] is Map ? options['raw']['language'] : null;
      return (language == 'json' ? 'json' : 'raw', raw);
    case 'urlencoded':
    case 'formdata':
      final fields = (bodyData[bodyData['mode']] as List? ?? [])
          .whereType<Map>()
          .where((f) => f['key'] != null && f['disabled'] != true && f['type'] != 'file')
          .map((f) => '${f['key']}=${f['value'] ?? ''}');
      return fields.isEmpty ? (null, null) : ('form', fields.join('\n'));
    default:
      return (null, null);
  }
}

/// Converts a Postman auth object to dbug's (authType, authData JSON).
/// Returns null for missing/`inherit` auth (caller decides the fallback) and
/// ('none', '{}') for `noauth` or unsupported types.
(String, String)? postmanAuthToDbug(dynamic auth) {
  if (auth is! Map) return null;
  final type = auth['type']?.toString();
  if (type == null || type == 'inherit') return null;

  // v2.1 stores attributes as [{key, value}], v2.0 as a plain map.
  Map<String, String> attrs(String name) {
    final raw = auth[name];
    if (raw is List) {
      return {
        for (final a in raw.whereType<Map>())
          if (a['key'] != null) a['key'].toString(): a['value']?.toString() ?? '',
      };
    }
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    return const {};
  }

  switch (type) {
    case 'bearer':
      return ('bearer', jsonEncode({'token': attrs('bearer')['token'] ?? ''}));
    case 'basic':
      final a = attrs('basic');
      return ('basic', jsonEncode({'username': a['username'] ?? '', 'password': a['password'] ?? ''}));
    case 'apikey':
      final a = attrs('apikey');
      return (
        'apikey',
        jsonEncode({
          'name': a['key'] ?? '',
          'value': a['value'] ?? '',
          'location': a['in'] == 'query' ? 'query' : 'header',
        }),
      );
    default:
      return ('none', '{}');
  }
}
