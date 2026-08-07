import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/history_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late HistoryRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = HistoryRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('addEntry', () {
    test('creates a history entry with all fields', () async {
      final entry = await repo.addEntry(
        requestId: 'req-1',
        method: 'POST',
        url: 'https://api.example.com/users',
        statusCode: 201,
        responseTimeMs: 150,
        responseSize: 1024,
        responseBody: '{"id": 1}',
        requestName: 'Create User',
        collectionId: 'coll-1',
        headers: '{"Authorization": "Bearer tok"}',
        collectionHeaders: '{"Tenant": "acme"}',
        body: '{"name": "test"}',
        bodyType: 'json',
        queryParams: '{"verbose": "true"}',
        authType: 'bearer',
        authData: '{"token": "abc123"}',
      );

      expect(entry.id, isNotEmpty);
      expect(entry.requestId, 'req-1');
      expect(entry.method, 'POST');
      expect(entry.url, 'https://api.example.com/users');
      expect(entry.statusCode, 201);
      expect(entry.responseTimeMs, 150);
      expect(entry.responseSize, 1024);
      expect(entry.responseBody, '{"id": 1}');
      expect(entry.requestName, 'Create User');
      expect(entry.collectionId, 'coll-1');
      expect(entry.headers, '{"Authorization": "Bearer tok"}');
      expect(entry.collectionHeaders, '{"Tenant": "acme"}');
      expect(entry.body, '{"name": "test"}');
      expect(entry.bodyType, 'json');
      expect(entry.queryParams, '{"verbose": "true"}');
      expect(entry.authType, 'bearer');
      expect(entry.authData, '{"token": "abc123"}');
    });

    test('creates entry with defaults', () async {
      final entry = await repo.addEntry(
        method: 'GET',
        url: 'http://test.com',
      );

      expect(entry.requestId, isNull);
      expect(entry.statusCode, isNull);
      expect(entry.responseTimeMs, isNull);
      expect(entry.headers, '{}');
      expect(entry.collectionHeaders, '{}');
      expect(entry.queryParams, '{}');
      expect(entry.authType, 'none');
      expect(entry.authData, '{}');
    });

    test('sentAt is set to current time', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      final entry = await repo.addEntry(method: 'GET', url: 'http://test.com');
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(entry.sentAt.millisecondsSinceEpoch, greaterThanOrEqualTo(before));
      expect(entry.sentAt.millisecondsSinceEpoch, lessThanOrEqualTo(after));
    });
  });

  group('getAllHistory', () {
    test('returns entries ordered by sent_at DESC', () async {
      await repo.addEntry(method: 'GET', url: 'http://1.com');
      await repo.addEntry(method: 'POST', url: 'http://2.com');
      await repo.addEntry(method: 'PUT', url: 'http://3.com');

      final entries = await repo.getAllHistory();
      expect(entries, hasLength(3));
    });

    test('limits to 500 entries', () async {
      for (var i = 0; i < 510; i++) {
        await repo.addEntry(method: 'GET', url: 'http://test$i.com');
      }

      final entries = await repo.getAllHistory();
      expect(entries.length, 500);
    });
  });

  group('deleteEntry', () {
    test('deletes an entry by id', () async {
      final entry = await repo.addEntry(method: 'DELETE', url: 'http://delete.com');
      await repo.deleteEntry(entry.id);

      final entries = await repo.getAllHistory();
      expect(entries, isEmpty);
    });
  });

  group('clearAll', () {
    test('clears all history entries', () async {
      await repo.addEntry(method: 'GET', url: 'http://1.com');
      await repo.addEntry(method: 'POST', url: 'http://2.com');
      await repo.addEntry(method: 'PUT', url: 'http://3.com');

      await repo.clearAll();
      final entries = await repo.getAllHistory();
      expect(entries, isEmpty);
    });
  });

  group('count', () {
    test('counts all history entries', () async {
      await repo.addEntry(method: 'GET', url: 'http://1.com');
      await repo.addEntry(method: 'POST', url: 'http://2.com');

      final count = await repo.count();
      expect(count, 2);
    });

    test('returns 0 for empty history', () async {
      final count = await repo.count();
      expect(count, 0);
    });
  });
}
