import 'dart:convert';

import 'package:dbug/core/models/auth_config.dart';
import 'package:dbug/core/request/request_composer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bearer = AuthConfig(type: AuthType.bearer, token: 'req-token');
  const collectionBearer = AuthConfig(type: AuthType.bearer, token: 'col-token');
  const collectionKeyQuery = AuthConfig(
    type: AuthType.apiKey,
    apiKeyName: 'api_key',
    apiKeyValue: 'col-key',
    apiKeyLocation: ApiKeyLocation.query,
  );

  group('AuthConfig', () {
    test('round-trips through stored form', () {
      const auth = AuthConfig(
        type: AuthType.apiKey,
        apiKeyName: 'X-Key',
        apiKeyValue: 'v',
        apiKeyLocation: ApiKeyLocation.query,
      );
      final restored = AuthConfig.fromStored(auth.storedType, auth.storedData);
      expect(restored, auth);
      expect(restored.apiKeyLocation, ApiKeyLocation.query);
    });

    test('bad stored data falls back to empty fields', () {
      final auth = AuthConfig.fromStored('bearer', 'not json');
      expect(auth.type, AuthType.bearer);
      expect(auth.token, '');
      expect(auth.producesCredentials, isFalse);
    });

    test('unknown type is none', () {
      expect(AuthConfig.fromStored('oauth2', '{}').type, AuthType.none);
      expect(AuthConfig.fromStored(null, null).type, AuthType.none);
    });

    test('bearer header trims the token', () {
      expect(const AuthConfig(type: AuthType.bearer, token: '  abc ').headers(),
          {'Authorization': 'Bearer abc'});
    });

    test('basic header encodes user:password, password untrimmed', () {
      const auth = AuthConfig(type: AuthType.basic, username: 'u', password: ' p ');
      expect(auth.headers(), {'Authorization': 'Basic ${base64Encode(utf8.encode('u: p '))}'});
    });

    test('blank credentials produce nothing', () {
      expect(const AuthConfig(type: AuthType.bearer).headers(), isEmpty);
      expect(const AuthConfig(type: AuthType.basic, password: 'p').headers(), isEmpty);
      expect(const AuthConfig(type: AuthType.apiKey, apiKeyName: 'k').headers(), isEmpty);
    });

    test('api key goes to header or query by location', () {
      const header = AuthConfig(type: AuthType.apiKey, apiKeyName: 'k', apiKeyValue: 'v');
      expect(header.headers(), {'k': 'v'});
      expect(header.queryParams(), isEmpty);
      final query = header.copyWith(apiKeyLocation: ApiKeyLocation.query);
      expect(query.headers(), isEmpty);
      expect(query.queryParams(), {'k': 'v'});
    });

    test('equality ignores fields of inactive types', () {
      const a = AuthConfig(type: AuthType.bearer, token: 't', username: 'x');
      const b = AuthConfig(type: AuthType.bearer, token: 't', username: 'y');
      expect(a, b);
      expect(a == b.copyWith(token: 'other'), isFalse);
    });
  });

  group('composeRequest headers', () {
    test('merge order: collection, then request, then auth', () {
      final out = composeRequest(
        method: 'get',
        url: 'https://x',
        collectionHeaders: {'X-A': 'col', 'X-B': 'col', 'Authorization': 'col'},
        headers: {'X-B': 'req', 'Authorization': 'req'},
        auth: bearer,
      );
      expect(out.method, 'GET');
      expect(out.headers['X-A'], 'col');
      expect(out.headers['X-B'], 'req');
      expect(out.headers['Authorization'], 'Bearer req-token');
    });

    test('collection auth applies when request auth is none', () {
      final out = composeRequest(method: 'GET', url: 'u', collectionAuth: collectionBearer);
      expect(out.headers['Authorization'], 'Bearer col-token');
    });

    test('request auth overrides collection auth', () {
      final out = composeRequest(
          method: 'GET', url: 'u', auth: bearer, collectionAuth: collectionBearer);
      expect(out.headers['Authorization'], 'Bearer req-token');
    });

    test('request auth with blank fields still overrides (sends nothing)', () {
      final out = composeRequest(
        method: 'GET',
        url: 'u',
        auth: const AuthConfig(type: AuthType.bearer),
        collectionAuth: collectionBearer,
      );
      expect(out.headers.containsKey('Authorization'), isFalse);
    });

    test('request-level header Authorization survives when no auth is set', () {
      final out = composeRequest(method: 'GET', url: 'u', headers: {'Authorization': 'Custom x'});
      expect(out.headers['Authorization'], 'Custom x');
    });
  });

  group('composeRequest query params', () {
    test('request api key in query overrides a same-named param', () {
      final out = composeRequest(
        method: 'GET',
        url: 'u',
        params: {'api_key': 'mine', 'q': '1'},
        auth: const AuthConfig(
          type: AuthType.apiKey,
          apiKeyName: 'api_key',
          apiKeyValue: 'req',
          apiKeyLocation: ApiKeyLocation.query,
        ),
      );
      expect(out.queryParams, {'api_key': 'req', 'q': '1'});
    });

    test('collection api key fills in but never overrides a param', () {
      expect(
        composeRequest(method: 'GET', url: 'u', collectionAuth: collectionKeyQuery).queryParams,
        {'api_key': 'col-key'},
      );
      expect(
        composeRequest(
          method: 'GET',
          url: 'u',
          params: {'api_key': 'mine'},
          collectionAuth: collectionKeyQuery,
        ).queryParams,
        {'api_key': 'mine'},
      );
    });

    test('collection api key is not added when request auth is set', () {
      final out = composeRequest(
          method: 'GET', url: 'u', auth: bearer, collectionAuth: collectionKeyQuery);
      expect(out.queryParams, isEmpty);
    });
  });

  group('composeRequest variables', () {
    const vars = {'host': 'api.test', 'token': 's3cret', 'id': '42'};

    test('substituted in url, header values, query values and body', () {
      final out = composeRequest(
        method: 'POST',
        url: ' https://{{host}}/users/{{id}} ',
        headers: {'X-Token': '{{token}}', '{{host}}': 'v'},
        params: {'id': '{{id}}'},
        bodyType: 'json',
        body: '{"id": "{{id}}"}',
        variables: vars,
      );
      expect(out.url, 'https://api.test/users/42');
      expect(out.headers['X-Token'], 's3cret');
      expect(out.headers.containsKey('{{host}}'), isTrue, reason: 'keys are not substituted');
      expect(out.queryParams['id'], '42');
      expect(out.body, '{"id": "42"}');
    });

    test('auth header values are substituted too', () {
      final out = composeRequest(
        method: 'GET',
        url: 'u',
        auth: const AuthConfig(type: AuthType.bearer, token: '{{token}}'),
        variables: vars,
      );
      expect(out.headers['Authorization'], 'Bearer s3cret');
    });

    test('unknown variables are left as-is', () {
      expect(composeRequest(method: 'GET', url: '{{nope}}/x').url, '{{nope}}/x');
    });
  });

  group('composeRequest body', () {
    test('no body when type is none or body is empty', () {
      expect(composeRequest(method: 'POST', url: 'u', bodyType: null, body: 'x').body, isNull);
      expect(composeRequest(method: 'POST', url: 'u', bodyType: 'json', body: '').body, isNull);
      expect(composeRequest(method: 'POST', url: 'u', bodyType: 'json', body: '').headers,
          isNot(contains('Content-Type')));
    });

    test('default content types per body type', () {
      String? ct(String type) =>
          composeRequest(method: 'POST', url: 'u', bodyType: type, body: 'a=b').headers['Content-Type'];
      expect(ct('json'), 'application/json');
      expect(ct('form'), 'application/x-www-form-urlencoded');
      expect(ct('raw'), 'text/plain');
    });

    test('an existing content-type header (any case) is kept', () {
      final out = composeRequest(
        method: 'POST',
        url: 'u',
        headers: {'content-type': 'application/vnd.api+json'},
        bodyType: 'json',
        body: '{}',
      );
      expect(out.headers['content-type'], 'application/vnd.api+json');
      expect(out.headers.containsKey('Content-Type'), isFalse);
    });

    test('a collection content-type header counts as set', () {
      final out = composeRequest(
        method: 'POST',
        url: 'u',
        collectionHeaders: {'Content-Type': 'text/csv'},
        bodyType: 'raw',
        body: 'a,b',
      );
      expect(out.headers['Content-Type'], 'text/csv');
    });

    test('form bodies are url-encoded after substitution', () {
      final out = composeRequest(
        method: 'POST',
        url: 'u',
        bodyType: 'form',
        body: 'name={{who}}\nmsg=a b&c',
        variables: {'who': 'J&J'},
      );
      expect(out.body, 'name=J%26J&msg=a+b%26c');
    });
  });

  group('encodeFormBody', () {
    test('skips blank lines, trims, handles missing = and extra =', () {
      expect(encodeFormBody('  a=1 \n\n b \nc=x=y\n'), 'a=1&b=&c=x%3Dy');
    });

    test('empty input gives empty output', () {
      expect(encodeFormBody(''), '');
      expect(encodeFormBody('\n \n'), '');
    });

    test('unicode is percent-encoded', () {
      expect(encodeFormBody('q=café'), 'q=caf%C3%A9');
    });
  });

  group('RequestDraft', () {
    test('round-trips through JSON', () {
      const draft = RequestDraft(
        method: 'POST',
        url: '{{base}}/x',
        name: 'Create',
        bodyType: 'form',
        body: 'a=1',
        headers: {'H': '1'},
        params: {'p': '2'},
        auth: AuthConfig(type: AuthType.basic, username: 'u', password: 'p'),
        tab: 3,
        collectionId: 'c1',
        requestId: 'r1',
        response: ResponseSnapshot(statusCode: 201, body: '{}', timeMs: 5, sizeBytes: 2, headers: {'a': 'b'}),
      );
      final restored = RequestDraft.fromJson(jsonDecode(jsonEncode(draft.toJson())));
      expect(restored.sameRequestAs(draft), isTrue);
      expect(restored.tab, 3);
      expect(restored.collectionId, 'c1');
      expect(restored.requestId, 'r1');
      expect(restored.response!.statusCode, 201);
      expect(restored.response!.headers, {'a': 'b'});
    });

    test('reads legacy drafts with an index auth type and per-key credentials', () {
      final legacy = {
        'method': 'GET',
        'url': 'https://x',
        'tab': 9,
        'bodyType': 1,
        'authType': 1,
        'bearerToken': 'old-token',
        'headers': '{"A":"1"}',
        'params': '{}',
        'response': {'statusCode': 200, 'body': 'ok', 'timeMs': 3, 'sizeBytes': 2},
      };
      final draft = RequestDraft.fromJson(legacy);
      expect(draft.auth.type, AuthType.bearer);
      expect(draft.auth.token, 'old-token');
      expect(draft.bodyType, 'json');
      expect(draft.tab, 3, reason: 'clamped');
      expect(draft.headers, {'A': '1'});
      expect(draft.response!.body, 'ok');
    });

    test('reads legacy drafts with a string type and per-key credentials', () {
      final draft = RequestDraft.fromJson({
        'authType': 'apikey',
        'authData': '{}',
        'apiKeyName': 'k',
        'apiKeyValue': 'v',
        'apiKeyLocation': 'query',
      });
      expect(draft.auth.type, AuthType.apiKey);
      expect(draft.auth.queryParams(), {'k': 'v'});
    });

    test('tolerates garbage fields', () {
      final draft = RequestDraft.fromJson({'headers': 'not json', 'tab': 'x', 'response': 'nope'});
      expect(draft.headers, isEmpty);
      expect(draft.tab, 0);
      expect(draft.response, isNull);
      expect(draft.method, 'GET');
    });

    test('sameRequestAs ignores tab/response and body when no body type', () {
      const a = RequestDraft(url: 'u', body: 'x', tab: 1);
      const b = RequestDraft(url: 'u', body: 'y', tab: 2);
      expect(a.sameRequestAs(b), isTrue);
      expect(a.copyWith(bodyType: 'raw').sameRequestAs(b.copyWith(bodyType: 'raw')), isFalse);
      expect(a.sameRequestAs(a.copyWith(headers: {'h': '1'})), isFalse);
      expect(a.sameRequestAs(a.copyWith(auth: const AuthConfig(type: AuthType.bearer, token: 't'))), isFalse);
    });
  });
}
