import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/collection_repository.dart';
import 'package:dbug/core/repositories/request_repository.dart';
import 'package:dbug/features/collections/data/postman_exporter.dart';
import 'package:dbug/features/collections/data/postman_importer.dart';
import '../helpers/test_database.dart';

Map<String, dynamic> _collection(List<Map<String, dynamic>> items, {Map<String, dynamic>? auth}) => {
      'info': {'name': 'API', 'schema': postmanSchemaV21},
      'item': items,
      'auth': ?auth,
    };

void main() {
  late CollectionRepository collections;
  late RequestRepository requests;
  late PostmanImporter importer;

  setUp(() async {
    await setupTestDatabase();
    collections = CollectionRepository();
    requests = RequestRepository();
    importer = PostmanImporter(collections: collections, requests: requests);
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  Future<PostmanImportResult> import(Map<String, dynamic> json) =>
      importer.importJson(jsonEncode(json), fileName: 'api.json');

  group('bodies', () {
    test('raw JSON, urlencoded and formdata', () {
      expect(
        postmanBodyToDbug({'mode': 'raw', 'raw': '{}', 'options': {'raw': {'language': 'json'}}}),
        ('json', '{}'),
      );
      expect(postmanBodyToDbug({'mode': 'raw', 'raw': 'hi'}), ('raw', 'hi'));
      expect(
        postmanBodyToDbug({'mode': 'urlencoded', 'urlencoded': [{'key': 'a', 'value': '1'}, {'key': 'b', 'value': '2', 'disabled': true}]}),
        ('form', 'a=1'),
      );
      expect(
        postmanBodyToDbug({'mode': 'formdata', 'formdata': [{'key': 'f', 'type': 'file', 'src': '/x'}, {'key': 'n', 'value': 'v', 'type': 'text'}]}),
        ('form', 'n=v'),
      );
      expect(postmanBodyToDbug({'mode': 'graphql'}), (null, null));
    });
  });

  group('auth', () {
    test('v2.1 list and v2.0 map attribute formats', () {
      expect(postmanAuthToDbug({'type': 'bearer', 'bearer': [{'key': 'token', 'value': 't'}]}),
          ('bearer', jsonEncode({'token': 't'})));
      expect(postmanAuthToDbug({'type': 'basic', 'basic': {'username': 'u', 'password': 'p'}}),
          ('basic', jsonEncode({'username': 'u', 'password': 'p'})));
      expect(
        postmanAuthToDbug({'type': 'apikey', 'apikey': [{'key': 'key', 'value': 'X-Key'}, {'key': 'value', 'value': 'v'}, {'key': 'in', 'value': 'query'}]}),
        ('apikey', jsonEncode({'name': 'X-Key', 'value': 'v', 'location': 'query'})),
      );
    });

    test('inherit/missing returns null, noauth returns none', () {
      expect(postmanAuthToDbug(null), isNull);
      expect(postmanAuthToDbug({'type': 'inherit'}), isNull);
      expect(postmanAuthToDbug({'type': 'noauth'}), ('none', '{}'));
    });
  });

  test('imports requests with string and object URLs', () async {
    final result = await import(_collection([
      {'name': 'Plain', 'request': {'method': 'get', 'url': 'https://a.test/x'}},
      {
        'name': 'Object',
        'request': {
          'method': 'POST',
          'header': [{'key': 'H', 'value': '1'}, {'key': 'Off', 'value': '0', 'disabled': true}],
          'url': {
            'raw': 'https://a.test/y?q=1&skip=2',
            'query': [{'key': 'q', 'value': '1'}, {'key': 'skip', 'value': '2', 'disabled': true}],
          },
        },
      },
      {'name': 'No raw', 'request': {'url': {'protocol': 'https', 'host': ['a', 'test'], 'path': ['z']}}},
    ]));

    expect(result.requestCount, 3);
    final list = await requests.getRequestsByCollection(result.collectionIds.single);
    final plain = list.firstWhere((r) => r.name == 'Plain');
    expect(plain.method, 'GET');
    expect(plain.url, 'https://a.test/x');

    final object = list.firstWhere((r) => r.name == 'Object');
    // Query moved to params (not duplicated in the URL); disabled entries dropped.
    expect(object.url, 'https://a.test/y');
    expect(object.queryParams, {'q': '1'});
    expect(object.headers, {'H': '1'});

    expect(list.firstWhere((r) => r.name == 'No raw').url, 'https://a.test/z');
  });

  test('nested folders become path-named collections inheriting auth', () async {
    final result = await import(_collection([
      {
        'name': 'Users',
        'item': [
          {'name': 'List', 'request': {'url': 'u'}},
          {
            'name': 'Admin',
            'auth': {'type': 'basic', 'basic': {'username': 'root', 'password': 'pw'}},
            'item': [
              {'name': 'Ban', 'request': {'url': 'b', 'auth': {'type': 'bearer', 'bearer': {'token': 'own'}}}},
            ],
          },
        ],
      },
    ], auth: {'type': 'bearer', 'bearer': [{'key': 'token', 'value': 'root-token'}]}));

    final all = await collections.getAllCollections();
    final byName = {for (final c in all) c.name: c};
    expect(byName.keys, containsAll(['API', 'API / Users', 'API / Users / Admin']));
    expect(result.collectionIds, hasLength(3));

    expect(byName['API']!.authType, 'bearer');
    expect(byName['API / Users']!.authType, 'bearer'); // inherited
    expect(byName['API / Users / Admin']!.authType, 'basic'); // own folder auth

    final ban = (await requests.getRequestsByCollection(byName['API / Users / Admin']!.id)).single;
    expect(ban.authType, 'bearer');
    expect(jsonDecode(ban.authData), {'token': 'own'});
  });

  test('rejects non-Postman JSON with a clear message', () async {
    expect(
      () => importer.importJson('{"foo": 1}', fileName: 'x.json'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('Not a Postman collection'))),
    );
    expect(
      () => importer.importJson('{nope', fileName: 'x.json'),
      throwsA(isA<FormatException>().having((e) => e.message, 'message', startsWith('Invalid JSON'))),
    );
  });

  test('export then import round-trips requests and auth', () async {
    final source = await collections.createCollection(
      name: 'Shop',
      description: 'desc',
      authType: 'apikey',
      authData: jsonEncode({'name': 'X-Key', 'value': 'k', 'location': 'header'}),
    );
    await requests.createRequest(
      collectionId: source.id, name: 'Create', method: 'POST', url: '{{baseUrl}}/orders',
      headers: {'Accept': 'application/json'}, bodyType: 'json', body: '{"a":1}',
      queryParams: {'dry': 'true'}, authType: 'bearer', authData: jsonEncode({'token': 't'}),
    );
    await requests.createRequest(
      collectionId: source.id, name: 'Form', method: 'PUT', url: 'https://x/f',
      bodyType: 'form', body: 'a=1\nb=two',
    );
    await requests.createRequest(
      collectionId: source.id, name: 'Raw', method: 'PATCH', url: 'https://x/r',
      bodyType: 'raw', body: 'plain text',
    );

    final exported = exportPostmanCollectionJson(source, await requests.getRequestsByCollection(source.id));
    final result = await importer.importJson(exported, fileName: 'shop.json');

    final imported = (await collections.getCollection(result.collectionIds.single))!;
    expect(imported.name, 'Shop');
    expect(imported.authType, 'apikey');
    expect(jsonDecode(imported.authData), {'name': 'X-Key', 'value': 'k', 'location': 'header'});

    String key(r) => '${r.name}|${r.method}|${r.url}|${r.headers}|${r.bodyType}|${r.body}|${r.queryParams}|${r.authType}|${r.authData}';
    final before = (await requests.getRequestsByCollection(source.id)).map(key).toList();
    final after = (await requests.getRequestsByCollection(imported.id)).map(key).toList();
    expect(after, before);
  });
}
