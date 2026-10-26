import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;

import '../../../core/models/mock_endpoint.dart';

/// A matched endpoint plus the values captured by its path parameters.
class MockMatch {
  final MockEndpoint endpoint;
  final Map<String, String> params;

  const MockMatch(this.endpoint, [this.params = const {}]);
}

/// Finds the endpoint for [method] and [path]. An exact path match wins;
/// otherwise templates with `:name` or `{name}` segments are tried and the
/// most specific one (fewest parameters) is chosen. Trailing slashes are
/// ignored on both sides.
MockMatch? matchMockEndpoint(List<MockEndpoint> endpoints, String method, String path) {
  final upper = method.toUpperCase();
  final target = _normalize(path);
  final candidates = endpoints.where((e) => e.method.toUpperCase() == upper);

  for (final e in candidates) {
    if (_normalize(e.path) == target) return MockMatch(e);
  }

  final targetSegments = _segments(target);
  MockMatch? best;
  var bestParamCount = 1 << 30;
  for (final e in candidates) {
    final templateSegments = _segments(_normalize(e.path));
    if (templateSegments.length != targetSegments.length) continue;

    final params = <String, String>{};
    var matched = true;
    for (var i = 0; i < templateSegments.length; i++) {
      final name = _paramName(templateSegments[i]);
      if (name != null) {
        if (targetSegments[i].isEmpty) {
          matched = false;
          break;
        }
        params[name] = Uri.decodeComponent(targetSegments[i]);
      } else if (templateSegments[i] != targetSegments[i]) {
        matched = false;
        break;
      }
    }
    if (matched && params.isNotEmpty && params.length < bestParamCount) {
      best = MockMatch(e, params);
      bestParamCount = params.length;
    }
  }
  return best;
}

String _normalize(String path) {
  var p = path.trim();
  if (!p.startsWith('/')) p = '/$p';
  while (p.length > 1 && p.endsWith('/')) {
    p = p.substring(0, p.length - 1);
  }
  return p;
}

List<String> _segments(String normalizedPath) =>
    normalizedPath == '/' ? const [] : normalizedPath.substring(1).split('/');

String? _paramName(String segment) {
  if (segment.length > 1 && segment.startsWith(':')) return segment.substring(1);
  if (segment.length > 2 && segment.startsWith('{') && segment.endsWith('}')) {
    return segment.substring(1, segment.length - 1);
  }
  return null;
}

final _paramRef = RegExp(r'\{\{\s*params\.([\w\-]+)\s*\}\}');

/// Replaces `{{params.name}}` in a response body with captured values;
/// unknown names are left as written.
String substitutePathParams(String body, Map<String, String> params) {
  if (params.isEmpty) return body;
  return body.replaceAllMapped(_paramRef, (m) => params[m.group(1)!] ?? m.group(0)!);
}

const _corsMethods = 'GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS';

Map<String, String> _corsHeaders(shelf.Request request) => {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': _corsMethods,
      'access-control-allow-headers':
          request.headers['access-control-request-headers'] ?? '*',
    };

/// Merges [overrides] into [base] case-insensitively, so a user's
/// `Content-Type` replaces the default `content-type` instead of duplicating it.
Map<String, String> _mergeHeaders(Map<String, String> base, Map<String, String> overrides) {
  final merged = Map.of(base);
  for (final entry in overrides.entries) {
    merged.removeWhere((k, _) => k.toLowerCase() == entry.key.toLowerCase());
    merged[entry.key] = entry.value;
  }
  return merged;
}

/// The mock server's request handler, independent of any server or database
/// so it can be tested with plain [shelf.Request]s.
///
/// - Every response carries permissive CORS headers so browser front-ends
///   can call the mock server; an OPTIONS preflight with no explicit
///   OPTIONS endpoint is answered with 204.
/// - HEAD falls back to the GET endpoint and returns its headers only.
Future<shelf.Response> handleMockRequest(
  shelf.Request request,
  List<MockEndpoint> endpoints, {
  Future<void> Function(Duration) delay = _defaultDelay,
}) async {
  final cors = _corsHeaders(request);
  final method = request.method.toUpperCase();
  final path = request.requestedUri.path;

  var match = matchMockEndpoint(endpoints, method, path);
  if (match == null && method == 'HEAD') {
    match = matchMockEndpoint(endpoints, 'GET', path);
  }

  if (match == null) {
    if (method == 'OPTIONS') {
      return shelf.Response(204, headers: {...cors, 'access-control-max-age': '600'});
    }
    return shelf.Response.notFound(
      '{"error": "Not found", "method": "$method", "path": "$path"}',
      headers: {'content-type': 'application/json', ...cors},
    );
  }

  final endpoint = match.endpoint;
  if (endpoint.delayMs > 0) {
    await delay(Duration(milliseconds: endpoint.delayMs));
  }

  final headers = _mergeHeaders({'content-type': 'application/json', ...cors}, endpoint.headers);
  final body = method == 'HEAD'
      ? ''
      : substitutePathParams(endpoint.body ?? '{"status": "ok"}', match.params);
  return shelf.Response(endpoint.statusCode, body: body, headers: headers);
}

Future<void> _defaultDelay(Duration d) => Future.delayed(d);
