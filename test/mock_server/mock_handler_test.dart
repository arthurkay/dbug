import 'package:dbug/core/models/mock_endpoint.dart';
import 'package:dbug/features/mock_server/data/mock_matcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart' as shelf;

MockEndpoint ep(String method, String path, {int status = 200, String? body, Map<String, String> headers = const {}, int delayMs = 0}) =>
    MockEndpoint(id: '$method $path', method: method, path: path, statusCode: status, body: body, headers: headers, delayMs: delayMs);

shelf.Request req(String method, String path, {Map<String, String> headers = const {}}) =>
    shelf.Request(method, Uri.parse('http://localhost:3001$path'), headers: headers);

void main() {
  group('matchMockEndpoint', () {
    final endpoints = [
      ep('GET', '/users/:id'),
      ep('GET', '/users/me'),
      ep('GET', '/users/{userId}/posts/{postId}'),
      ep('POST', '/users'),
    ];

    test('exact match wins over a template', () {
      final m = matchMockEndpoint(endpoints, 'GET', '/users/me')!;
      expect(m.endpoint.path, '/users/me');
      expect(m.params, isEmpty);
    });

    test('captures :name and {name} parameters', () {
      expect(matchMockEndpoint(endpoints, 'GET', '/users/42')!.params, {'id': '42'});
      expect(
        matchMockEndpoint(endpoints, 'GET', '/users/7/posts/9')!.params,
        {'userId': '7', 'postId': '9'},
      );
    });

    test('decodes captured values', () {
      expect(matchMockEndpoint(endpoints, 'GET', '/users/a%20b')!.params, {'id': 'a b'});
    });

    test('prefers the template with the fewest parameters', () {
      final list = [ep('GET', '/:a/:b'), ep('GET', '/items/:id')];
      expect(matchMockEndpoint(list, 'GET', '/items/3')!.endpoint.path, '/items/:id');
    });

    test('method is case-insensitive and must match', () {
      expect(matchMockEndpoint(endpoints, 'post', '/users'), isNotNull);
      expect(matchMockEndpoint(endpoints, 'DELETE', '/users'), isNull);
    });

    test('ignores trailing slashes and segment count mismatches', () {
      expect(matchMockEndpoint(endpoints, 'POST', '/users/'), isNotNull);
      expect(matchMockEndpoint(endpoints, 'GET', '/users/1/extra'), isNull);
      expect(matchMockEndpoint(endpoints, 'GET', '/nothing'), isNull);
    });
  });

  group('substitutePathParams', () {
    test('replaces known params and keeps unknown ones', () {
      expect(
        substitutePathParams('{"id": "{{params.id}}", "x": "{{ params.x }}", "y": "{{params.y}}"}', {'id': '5', 'x': 'X'}),
        '{"id": "5", "x": "X", "y": "{{params.y}}"}',
      );
    });
  });

  group('handleMockRequest', () {
    test('returns 404 JSON with CORS headers when nothing matches', () async {
      final res = await handleMockRequest(req('GET', '/missing'), const []);
      expect(res.statusCode, 404);
      expect(res.headers['access-control-allow-origin'], '*');
      expect(await res.readAsString(), contains('Not found'));
    });

    test('serves status, body with path params, and merges headers case-insensitively', () async {
      final res = await handleMockRequest(
        req('GET', '/users/12'),
        [ep('GET', '/users/:id', status: 201, body: '{"id": "{{params.id}}"}', headers: {'Content-Type': 'text/plain', 'X-Mock': '1'})],
      );
      expect(res.statusCode, 201);
      expect(await res.readAsString(), '{"id": "12"}');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.headers['x-mock'], '1');
      expect(res.headers['access-control-allow-origin'], '*');
    });

    test('defaults the body when the endpoint has none', () async {
      final res = await handleMockRequest(req('GET', '/ok'), [ep('GET', '/ok')]);
      expect(await res.readAsString(), '{"status": "ok"}');
    });

    test('applies the configured delay', () async {
      Duration? waited;
      await handleMockRequest(
        req('GET', '/slow'),
        [ep('GET', '/slow', delayMs: 250)],
        delay: (d) async => waited = d,
      );
      expect(waited, const Duration(milliseconds: 250));
    });

    test('HEAD falls back to GET with an empty body', () async {
      final res = await handleMockRequest(req('HEAD', '/ok'), [ep('GET', '/ok', body: 'hello', headers: {'X-A': 'b'})]);
      expect(res.statusCode, 200);
      expect(res.headers['x-a'], 'b');
      expect(await res.readAsString(), isEmpty);
    });

    test('answers CORS preflight with 204 and echoes requested headers', () async {
      final res = await handleMockRequest(
        req('OPTIONS', '/users', headers: {'access-control-request-headers': 'authorization, content-type'}),
        [ep('POST', '/users')],
      );
      expect(res.statusCode, 204);
      expect(res.headers['access-control-allow-headers'], 'authorization, content-type');
      expect(res.headers['access-control-allow-methods'], contains('PATCH'));
    });

    test('an explicit OPTIONS endpoint overrides the automatic preflight', () async {
      final res = await handleMockRequest(req('OPTIONS', '/users'), [ep('OPTIONS', '/users', status: 200, body: 'custom')]);
      expect(res.statusCode, 200);
      expect(await res.readAsString(), 'custom');
    });
  });
}
