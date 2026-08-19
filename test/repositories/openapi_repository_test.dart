import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/openapi_repository.dart';
import 'package:dbug/core/models/openapi_spec.dart';
import 'package:dbug/features/openapi/data/openapi_parser.dart';
import 'package:dbug/core/database/database_service.dart';
import '../helpers/test_database.dart';

void main() {
  late OpenApiRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = OpenApiRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  ParsedSpec createTestParsedSpec({
    String? title,
    String? version,
    String? baseUrl,
    List<OpenApiEndpoint>? endpoints,
    String rawContent = '{}',
  }) {
    return ParsedSpec(
      title: title ?? 'Test API',
      version: version ?? '1.0.0',
      baseUrl: baseUrl,
      endpoints: endpoints ?? [],
      rawContent: rawContent,
    );
  }

  group('saveParsedSpec', () {
    test('saves spec to openapi_specs table', () async {
      final parsed = createTestParsedSpec();
      final spec = await repo.saveParsedSpec(parsed, sourceType: 'file');

      expect(spec.id, isNotEmpty);
      expect(spec.title, 'Test API');
      expect(spec.version, '1.0.0');
      expect(spec.sourceType, 'file');
      expect(spec.importedAt, isA<DateTime>());
    });

    test('creates a collection linked to the spec', () async {
      final parsed = createTestParsedSpec(title: 'My API');
      final savedSpec = await repo.saveParsedSpec(parsed);

      final db = await DatabaseService.database;
      final colls = await db.query('collections', where: 'source_spec_id = ?', whereArgs: [savedSpec.id]);
      expect(colls, hasLength(1));
      expect(colls.first['name'], 'My API');
    });

    test('creates requests for each endpoint', () async {
      final endpoints = [
        OpenApiEndpoint(path: '/users', method: 'GET', summary: 'List users'),
        OpenApiEndpoint(path: '/users', method: 'POST', summary: 'Create user'),
        OpenApiEndpoint(path: '/items/{id}', method: 'DELETE', summary: 'Delete item'),
      ];
      final parsed = createTestParsedSpec(endpoints: endpoints);
      final savedSpec = await repo.saveParsedSpec(parsed);

      final db = await DatabaseService.database;
      final colls = await db.query('collections', where: 'source_spec_id = ?', whereArgs: [savedSpec.id]);
      final collId = colls.first['id'];
      final requests = await db.query('requests', where: 'collection_id = ?', whereArgs: [collId]);
      expect(requests, hasLength(3));
    });

    test('converts path params from {id} to {{id}} format', () async {
      final endpoints = [
        OpenApiEndpoint(path: '/users/{id}', method: 'GET'),
      ];
      final parsed = createTestParsedSpec(
        baseUrl: 'https://api.example.com',
        endpoints: endpoints,
      );
      final savedSpec = await repo.saveParsedSpec(parsed);

      final db = await DatabaseService.database;
      final colls = await db.query('collections', where: 'source_spec_id = ?', whereArgs: [savedSpec.id]);
      final collId = colls.first['id'];
      final requests = await db.query('requests', where: 'collection_id = ?', whereArgs: [collId]);
      final url = requests.first['url'] as String;
      expect(url, contains('{{id}}'));
      expect(url, startsWith('{{baseUrl}}'));
    });

    test('creates environment with baseUrl and path params', () async {
      final endpoints = [
        OpenApiEndpoint(path: '/users/{userId}', method: 'GET'),
      ];
      final parsed = createTestParsedSpec(
        title: 'Test',
        baseUrl: 'https://api.test.com',
        endpoints: endpoints,
      );
      final savedSpec = await repo.saveParsedSpec(parsed);

      final db = await DatabaseService.database;
      final envs = await db.query('environments', where: 'name = ? AND source_type = ?', whereArgs: ['Test API', 'openapi']);
      expect(envs, hasLength(1));
    });

    test('does not create environment when no baseUrl or path params', () async {
      final endpoints = [
        OpenApiEndpoint(path: '/status', method: 'GET'),
      ];
      final parsed = createTestParsedSpec(endpoints: endpoints);
      await repo.saveParsedSpec(parsed);

      final db = await DatabaseService.database;
      final envs = await db.query('environments');
      expect(envs, isEmpty);
    });

    test('saves with sourceType and sourceUrl', () async {
      final parsed = createTestParsedSpec();
      final spec = await repo.saveParsedSpec(
        parsed,
        sourceType: 'url',
        sourceUrl: 'https://example.com/openapi.json',
      );

      expect(spec.sourceType, 'url');
      expect(spec.sourceUrl, 'https://example.com/openapi.json');
    });
  });

  group('getAllSpecs', () {
    test('returns all specs ordered by imported_at DESC', () async {
      await repo.saveParsedSpec(createTestParsedSpec(title: 'First'));
      await repo.saveParsedSpec(createTestParsedSpec(title: 'Second'));

      final specs = await repo.getAllSpecs();
      expect(specs, hasLength(2));
      expect(specs.first.title, 'Second');
      expect(specs.last.title, 'First');
    });

    test('returns empty list when no specs', () async {
      final specs = await repo.getAllSpecs();
      expect(specs, isEmpty);
    });

    test('parses endpoints from stored JSON', () async {
      final endpoints = [
        OpenApiEndpoint(path: '/test', method: 'GET', summary: 'Test'),
      ];
      await repo.saveParsedSpec(createTestParsedSpec(endpoints: endpoints));

      final specs = await repo.getAllSpecs();
      expect(specs.first.endpoints, hasLength(1));
      expect(specs.first.endpoints.first.path, '/test');
    });
  });

  group('getSpec', () {
    test('returns a spec by id', () async {
      final saved = await repo.saveParsedSpec(createTestParsedSpec(title: 'FindMe'));
      final found = await repo.getSpec(saved.id);

      expect(found, isNotNull);
      expect(found!.title, 'FindMe');
    });

    test('returns null for unknown id', () async {
      final found = await repo.getSpec('nonexistent');
      expect(found, isNull);
    });
  });

  group('deleteSpec', () {
    test('deletes the spec', () async {
      final saved = await repo.saveParsedSpec(createTestParsedSpec());
      await repo.deleteSpec(saved.id);

      final found = await repo.getSpec(saved.id);
      expect(found, isNull);
    });

    test('cascades to delete collections', () async {
      final saved = await repo.saveParsedSpec(createTestParsedSpec());
      await repo.deleteSpec(saved.id);

      final db = await DatabaseService.database;
      final colls = await db.query('collections', where: 'source_spec_id = ?', whereArgs: [saved.id]);
      expect(colls, isEmpty);
    });

    test('cascades to delete requests', () async {
      final endpoints = [
        OpenApiEndpoint(path: '/test', method: 'GET'),
      ];
      final saved = await repo.saveParsedSpec(createTestParsedSpec(endpoints: endpoints));

      final db = await DatabaseService.database;
      final colls = await db.query('collections', where: 'source_spec_id = ?', whereArgs: [saved.id]);
      expect(colls, isNotEmpty);
      final collId = colls.first['id'];

      await repo.deleteSpec(saved.id);
      final reqs = await db.query('requests', where: 'collection_id = ?', whereArgs: [collId]);
      expect(reqs, isEmpty);
    });

    test('cascades to delete environments', () async {
      final endpoints = [
        OpenApiEndpoint(path: '/users/{id}', method: 'GET'),
      ];
      final saved = await repo.saveParsedSpec(
        createTestParsedSpec(title: 'Test', baseUrl: 'https://api.test.com', endpoints: endpoints),
      );

      await repo.deleteSpec(saved.id);
      final db = await DatabaseService.database;
      final envs = await db.query('environments', where: 'name = ? AND source_type = ?', whereArgs: ['Test API', 'openapi']);
      expect(envs, isEmpty);
    });

    test('auto-created environment is linked to the spec by source_spec_id', () async {
      final saved = await repo.saveParsedSpec(
        createTestParsedSpec(title: 'Linked', baseUrl: 'https://api.test.com'),
      );

      final db = await DatabaseService.database;
      final envs = await db.query('environments', where: 'source_spec_id = ?', whereArgs: [saved.id]);
      expect(envs, hasLength(1));
      expect(envs.first['name'], 'Linked API');
    });

    test('only deletes the environment of the deleted spec when titles collide', () async {
      final first = await repo.saveParsedSpec(
        createTestParsedSpec(title: 'Same', baseUrl: 'https://one.test.com'),
      );
      final second = await repo.saveParsedSpec(
        createTestParsedSpec(title: 'Same', baseUrl: 'https://two.test.com'),
      );

      await repo.deleteSpec(first.id);

      final db = await DatabaseService.database;
      final gone = await db.query('environments', where: 'source_spec_id = ?', whereArgs: [first.id]);
      final kept = await db.query('environments', where: 'source_spec_id = ?', whereArgs: [second.id]);
      expect(gone, isEmpty);
      expect(kept, hasLength(1));
    });

    test('deletes legacy environments that have no source_spec_id', () async {
      final saved = await repo.saveParsedSpec(
        createTestParsedSpec(title: 'Legacy', baseUrl: 'https://api.test.com'),
      );
      final db = await DatabaseService.database;
      await db.update('environments', {'source_spec_id': null},
          where: 'source_spec_id = ?', whereArgs: [saved.id]);

      await repo.deleteSpec(saved.id);

      final envs = await db.query('environments',
          where: 'name = ? AND source_type = ?', whereArgs: ['Legacy API', 'openapi']);
      expect(envs, isEmpty);
    });
  });
}
