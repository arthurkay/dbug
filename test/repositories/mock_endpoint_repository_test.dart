import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/mock_endpoint_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late MockEndpointRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = MockEndpointRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('createEndpoint', () {
    test('creates an endpoint with all fields', () async {
      final ep = await repo.createEndpoint(
        method: 'POST',
        path: '/api/users',
        statusCode: 201,
        headers: {'Content-Type': 'application/json'},
        body: '{"id": 1}',
        delayMs: 100,
      );

      expect(ep.id, isNotEmpty);
      expect(ep.method, 'POST');
      expect(ep.path, '/api/users');
      expect(ep.statusCode, 201);
      expect(ep.headers, {'Content-Type': 'application/json'});
      expect(ep.body, '{"id": 1}');
      expect(ep.delayMs, 100);
    });

    test('creates endpoint with defaults', () async {
      final ep = await repo.createEndpoint(method: 'GET', path: '/status');
      expect(ep.statusCode, 200);
      expect(ep.headers, isEmpty);
      expect(ep.body, isNull);
      expect(ep.delayMs, 0);
    });
  });

  group('updateEndpoint', () {
    test('updates endpoint fields', () async {
      final ep = await repo.createEndpoint(method: 'GET', path: '/old');
      final updated = ep.copyWith(
        method: 'POST',
        path: '/new',
        statusCode: 201,
        body: '{"created": true}',
      );
      await repo.updateEndpoint(updated);

      final all = await repo.getAllEndpoints();
      final found = all.where((e) => e.id == ep.id).first;
      expect(found.method, 'POST');
      expect(found.path, '/new');
      expect(found.statusCode, 201);
      expect(found.body, '{"created": true}');
    });
  });

  group('deleteEndpoint', () {
    test('deletes an endpoint by id', () async {
      final ep = await repo.createEndpoint(method: 'GET', path: '/to-delete');
      await repo.deleteEndpoint(ep.id);

      final all = await repo.getAllEndpoints();
      expect(all, isEmpty);
    });
  });

  group('getAllEndpoints', () {
    test('returns all endpoints ordered by path ASC', () async {
      await repo.createEndpoint(method: 'GET', path: '/zebra');
      await repo.createEndpoint(method: 'GET', path: '/alpha');
      await repo.createEndpoint(method: 'POST', path: '/middle');

      final all = await repo.getAllEndpoints();
      expect(all, hasLength(3));
      expect(all[0].path, '/alpha');
      expect(all[1].path, '/middle');
      expect(all[2].path, '/zebra');
    });
  });

  group('matchEndpoint', () {
    test('matches by method and path', () async {
      await repo.createEndpoint(method: 'GET', path: '/api/status', body: '{"ok": true}');
      await repo.createEndpoint(method: 'POST', path: '/api/users');

      final match = await repo.matchEndpoint('GET', '/api/status');
      expect(match, isNotNull);
      expect(match!.body, '{"ok": true}');
    });

    test('returns null for no match', () async {
      await repo.createEndpoint(method: 'GET', path: '/api/status');
      final match = await repo.matchEndpoint('POST', '/api/status');
      expect(match, isNull);
    });

    test('case insensitive method matching', () async {
      await repo.createEndpoint(method: 'GET', path: '/api/status');
      final match = await repo.matchEndpoint('get', '/api/status');
      expect(match, isNotNull);
    });

    test('returns null for empty database', () async {
      final match = await repo.matchEndpoint('GET', '/anything');
      expect(match, isNull);
    });
  });
}
