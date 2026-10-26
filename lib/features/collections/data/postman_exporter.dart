import 'dart:convert';

import '../../../core/models/collection_model.dart';
import '../../../core/models/request_model.dart';

const postmanSchemaV21 = 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json';

/// Exports [collection] and its [requests] as a Postman v2.1 collection.
///
/// Limitation: Postman has no equivalent of dbug's collection-wide global
/// headers, so they are not exported. Collection auth maps to the
/// collection-level `auth`, and request auth to each request's `auth`
/// (requests with no auth of their own inherit, as in dbug).
Map<String, dynamic> exportPostmanCollection(Collection collection, List<RequestModel> requests) {
  final collectionAuth = dbugAuthToPostman(collection.authType, collection.authData);
  return {
    'info': {
      'name': collection.name,
      if (collection.description != null) 'description': collection.description,
      'schema': postmanSchemaV21,
    },
    'item': requests.map(_exportRequest).toList(),
    'auth': ?collectionAuth,
  };
}

/// [exportPostmanCollection] as pretty-printed JSON text.
String exportPostmanCollectionJson(Collection collection, List<RequestModel> requests) =>
    const JsonEncoder.withIndent('  ').convert(exportPostmanCollection(collection, requests));

Map<String, dynamic> _exportRequest(RequestModel r) {
  final query = r.queryParams.entries.map((e) => {'key': e.key, 'value': e.value}).toList();
  final raw = query.isEmpty
      ? r.url
      : '${r.url}?${r.queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  final body = _exportBody(r.bodyType, r.body);
  final auth = dbugAuthToPostman(r.authType, r.authData);

  return {
    'name': r.name,
    'request': {
      'method': r.method,
      'header': r.headers.entries.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'url': {
        'raw': raw,
        if (query.isNotEmpty) 'query': query,
      },
      'body': ?body,
      'auth': ?auth,
    },
  };
}

Map<String, dynamic>? _exportBody(String? bodyType, String? body) {
  if (body == null || bodyType == null) return null;
  switch (bodyType) {
    case 'json':
      return {
        'mode': 'raw',
        'raw': body,
        'options': {
          'raw': {'language': 'json'},
        },
      };
    case 'form':
      return {
        'mode': 'urlencoded',
        'urlencoded': [
          for (final line in body.split('\n'))
            if (line.trim().isNotEmpty)
              {
                'key': line.contains('=') ? line.substring(0, line.indexOf('=')).trim() : line.trim(),
                'value': line.contains('=') ? line.substring(line.indexOf('=') + 1).trim() : '',
              },
        ],
      };
    default:
      return {'mode': 'raw', 'raw': body};
  }
}

/// Converts dbug's (authType, authData JSON) to a Postman v2.1 auth object,
/// or null for 'none' (meaning: inherit).
Map<String, dynamic>? dbugAuthToPostman(String authType, String authData) {
  Map<String, dynamic> data;
  try {
    data = Map<String, dynamic>.from(jsonDecode(authData) as Map);
  } catch (_) {
    data = {};
  }
  List<Map<String, String>> attrs(Map<String, Object?> values) => [
        for (final e in values.entries) {'key': e.key, 'value': '${e.value ?? ''}', 'type': 'string'},
      ];

  switch (authType) {
    case 'bearer':
      return {'type': 'bearer', 'bearer': attrs({'token': data['token']})};
    case 'basic':
      return {
        'type': 'basic',
        'basic': attrs({'username': data['username'], 'password': data['password']}),
      };
    case 'apikey':
      return {
        'type': 'apikey',
        'apikey': attrs({'key': data['name'], 'value': data['value'], 'in': data['location'] ?? 'header'}),
      };
    default:
      return null;
  }
}
