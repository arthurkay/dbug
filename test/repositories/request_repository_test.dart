import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/request_repository.dart';
import 'package:dbug/core/repositories/collection_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late RequestRepository repo;
  late CollectionRepository collRepo;

  setUp(() async {
    await setupTestDatabase();
    repo = RequestRepository();
    collRepo = CollectionRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('createRequest', () {
    test('creates a request with all fields', () async {
      final coll = await collRepo.createCollection(name: 'Test');

      final req = await repo.createRequest(
        collectionId: coll.id,
        name: 'Get Users',
        method: 'GET',
        url: 'https://api.example.com/users',
        headers: {'Authorization': 'Bearer token'},
        bodyType: 'json',
        body: '{"page": 1}',
        queryParams: {'limit': '10'},
      );

      expect(req.name, 'Get Users');
      expect(req.method, 'GET');
      expect(req.url, 'https://api.example.com/users');
      expect(req.headers, {'Authorization': 'Bearer token'});
      expect(req.bodyType, 'json');
      expect(req.body, '{"page": 1}');
      expect(req.queryParams, {'limit': '10'});
      expect(req.collectionId, coll.id);
      expect(req.id, isNotEmpty);
    });

    test('creates a request without collection', () async {
      final req = await repo.createRequest(
        name: 'Standalone',
        method: 'POST',
        url: 'https://api.example.com/data',
      );

      expect(req.collectionId, isNull);
      expect(req.name, 'Standalone');
    });

    test('createdAt and updatedAt are set', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      final req = await repo.createRequest(
        name: 'Test',
        method: 'GET',
        url: 'http://test.com',
      );
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(req.createdAt.millisecondsSinceEpoch, greaterThanOrEqualTo(before));
      expect(req.createdAt.millisecondsSinceEpoch, lessThanOrEqualTo(after));
    });
  });

  group('updateRequest', () {
    test('updates request fields', () async {
      final req = await repo.createRequest(
        name: 'Old',
        method: 'GET',
        url: 'http://old.com',
      );

      final updated = req.copyWith(
        name: 'New',
        method: 'POST',
        url: 'http://new.com',
        body: '{"updated": true}',
      );
      await repo.updateRequest(updated);

      final fetched = await repo.getRequest(req.id);
      expect(fetched?.name, 'New');
      expect(fetched?.method, 'POST');
      expect(fetched?.url, 'http://new.com');
      expect(fetched?.body, '{"updated": true}');
    });
  });

  group('getRequestsByCollection', () {
    test('returns requests for a specific collection', () async {
      final c1 = await collRepo.createCollection(name: 'A');
      final c2 = await collRepo.createCollection(name: 'B');

      await repo.createRequest(collectionId: c1.id, name: 'Req1', method: 'GET', url: 'http://a.com');
      await repo.createRequest(collectionId: c1.id, name: 'Req2', method: 'POST', url: 'http://b.com');
      await repo.createRequest(collectionId: c2.id, name: 'Req3', method: 'GET', url: 'http://c.com');

      final requests = await repo.getRequestsByCollection(c1.id);
      expect(requests, hasLength(2));
      expect(requests.every((r) => r.collectionId == c1.id), isTrue);
    });

    test('returns empty list for unknown collection', () async {
      final requests = await repo.getRequestsByCollection('nonexistent');
      expect(requests, isEmpty);
    });
  });

  group('getAllRequests', () {
    test('returns all requests ordered by created_at DESC', () async {
      await repo.createRequest(name: 'First', method: 'GET', url: 'http://1.com');
      await Future.delayed(const Duration(milliseconds: 5));
      await repo.createRequest(name: 'Second', method: 'POST', url: 'http://2.com');

      final requests = await repo.getAllRequests();
      expect(requests, hasLength(2));
      expect(requests.first.name, 'Second');
      expect(requests.last.name, 'First');
    });
  });

  group('getRequest', () {
    test('returns a request by id', () async {
      final created = await repo.createRequest(
        name: 'FindMe',
        method: 'GET',
        url: 'http://find.com',
      );
      final found = await repo.getRequest(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'FindMe');
    });

    test('returns null for unknown id', () async {
      final found = await repo.getRequest('nonexistent');
      expect(found, isNull);
    });
  });

  group('deleteRequest', () {
    test('deletes a request by id', () async {
      final req = await repo.createRequest(
        name: 'ToDelete',
        method: 'DELETE',
        url: 'http://delete.com',
      );
      await repo.deleteRequest(req.id);
      final found = await repo.getRequest(req.id);
      expect(found, isNull);
    });
  });

  group('deleteByCollection', () {
    test('deletes all requests in a collection', () async {
      final coll = await collRepo.createCollection(name: 'Test');

      await repo.createRequest(collectionId: coll.id, name: 'A', method: 'GET', url: 'http://a.com');
      await repo.createRequest(collectionId: coll.id, name: 'B', method: 'POST', url: 'http://b.com');

      await repo.deleteByCollection(coll.id);
      final remaining = await repo.getRequestsByCollection(coll.id);
      expect(remaining, isEmpty);
    });
  });

  group('countByCollection', () {
    test('counts requests in a collection', () async {
      final coll = await collRepo.createCollection(name: 'Test');

      await repo.createRequest(collectionId: coll.id, name: 'A', method: 'GET', url: 'http://a.com');
      await repo.createRequest(collectionId: coll.id, name: 'B', method: 'POST', url: 'http://b.com');
      await repo.createRequest(collectionId: coll.id, name: 'C', method: 'PUT', url: 'http://c.com');

      final count = await repo.countByCollection(coll.id);
      expect(count, 3);
    });

    test('returns 0 for empty collection', () async {
      final count = await repo.countByCollection('nonexistent');
      expect(count, 0);
    });
  });
}
