import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/database/database_service.dart';
import 'package:dbug/core/repositories/openapi_repository.dart';
import 'package:dbug/core/repositories/request_repository.dart';
import 'package:dbug/core/repositories/environment_repository.dart';
import 'package:dbug/features/openapi/data/openapi_parser.dart';
import '../helpers/test_database.dart';

const _spec = '''
{
  "openapi": "3.0.0",
  "info": {"title": "Shop", "version": "2.0"},
  "servers": [{"url": "https://shop.test"}],
  "paths": {
    "/orders/{order-id}": {
      "get": {
        "summary": "Get order",
        "parameters": [
          {"name": "order-id", "in": "path", "required": true, "schema": {"type": "string"}},
          {"name": "expand", "in": "query", "example": "items", "schema": {"type": "string"}},
          {"name": "page", "in": "query", "schema": {"type": "integer"}},
          {"name": "X-Tenant", "in": "header", "schema": {"type": "string"}}
        ],
        "responses": {}
      },
      "put": {
        "requestBody": {"content": {"application/json": {"schema": {
          "type": "object",
          "properties": {"note": {"type": "string"}, "qty": {"type": "integer"}}
        }}}},
        "responses": {}
      }
    }
  }
}''';

void main() {
  late OpenApiRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = OpenApiRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  test('imports prefilled requests with hyphenated path params', () async {
    final spec = await repo.saveParsedSpec(OpenApiParser.parse(_spec)!);
    final collectionId = await repo.getCollectionForSpec(spec.id);
    expect(collectionId, isNotNull);

    final requests = await RequestRepository().getRequestsByCollection(collectionId!);
    final get = requests.firstWhere((r) => r.method == 'GET');
    expect(get.url, '{{baseUrl}}/orders/{{order-id}}');
    expect(get.queryParams, {'expand': 'items', 'page': ''});
    expect(get.headers, {'X-Tenant': ''});
    expect(get.bodyType, isNull);

    final put = requests.firstWhere((r) => r.method == 'PUT');
    expect(put.bodyType, 'json');
    expect(jsonDecode(put.body!), {'note': '', 'qty': 0});

    final env = (await EnvironmentRepository().getAllEnvironments()).single;
    expect(env.sourceSpecId, spec.id);
    expect(env.variables, {'baseUrl': 'https://shop.test', 'order-id': ''});
  });

  test('summaries count endpoints without loading the spec', () async {
    await repo.saveParsedSpec(OpenApiParser.parse(_spec)!);
    final summaries = await repo.getSpecSummaries();
    expect(summaries.single.title, 'Shop');
    expect(summaries.single.version, '2.0');
    expect(summaries.single.endpointCount, 2);
  });

  test('a failed import rolls back completely', () async {
    final db = await DatabaseService.database;
    // Make the environment insert (the last statement) fail.
    await db.execute('''
      CREATE TRIGGER fail_env BEFORE INSERT ON environments
      BEGIN SELECT RAISE(ABORT, 'boom'); END
    ''');
    await expectLater(repo.saveParsedSpec(OpenApiParser.parse(_spec)!), throwsA(anything));

    for (final table in ['openapi_specs', 'collections', 'requests', 'environments']) {
      final count = (await db.rawQuery('SELECT COUNT(*) AS c FROM $table')).first['c'];
      expect(count, 0, reason: table);
    }
  });

  test('deleteSpec removes spec, collection, requests and environment', () async {
    final spec = await repo.saveParsedSpec(OpenApiParser.parse(_spec)!);
    await repo.deleteSpec(spec.id);

    final db = await DatabaseService.database;
    for (final table in ['openapi_specs', 'collections', 'requests', 'environments']) {
      final count = (await db.rawQuery('SELECT COUNT(*) AS c FROM $table')).first['c'];
      expect(count, 0, reason: table);
    }
    expect(await repo.getCollectionForSpec(spec.id), isNull);
  });
}
