import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/collection_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late CollectionRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = CollectionRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('createCollection', () {
    test('creates a collection with all fields', () async {
      final coll = await repo.createCollection(
        name: 'My API',
        description: 'Test collection',
        sourceType: 'manual',
        sourceSpecId: 'spec-1',
        globalHeaders: {'X-Custom': 'value'},
      );

      expect(coll.name, 'My API');
      expect(coll.description, 'Test collection');
      expect(coll.sourceType, 'manual');
      expect(coll.sourceSpecId, 'spec-1');
      expect(coll.globalHeaders, {'X-Custom': 'value'});
      expect(coll.id, isNotEmpty);
    });

    test('creates collection with defaults', () async {
      final coll = await repo.createCollection(name: 'Minimal');
      expect(coll.description, isNull);
      expect(coll.sourceType, 'manual');
      expect(coll.sourceSpecId, isNull);
      expect(coll.globalHeaders, isEmpty);
    });

    test('createdAt and updatedAt are set', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      final coll = await repo.createCollection(name: 'Test');
      final after = DateTime.now().millisecondsSinceEpoch;

      expect(coll.createdAt.millisecondsSinceEpoch, greaterThanOrEqualTo(before));
      expect(coll.createdAt.millisecondsSinceEpoch, lessThanOrEqualTo(after));
    });
  });

  group('getAllCollections', () {
    test('returns all collections ordered by created_at DESC', () async {
      final first = await repo.createCollection(name: 'First');
      await Future.delayed(const Duration(milliseconds: 5));
      final second = await repo.createCollection(name: 'Second');
      await Future.delayed(const Duration(milliseconds: 5));
      final third = await repo.createCollection(name: 'Third');

      final colls = await repo.getAllCollections();
      expect(colls, hasLength(3));
      expect(colls.first.name, 'Third');
      expect(colls.last.name, 'First');
    });
  });

  group('updateCollection', () {
    test('updates collection fields', () async {
      final coll = await repo.createCollection(name: 'Old');
      final updated = coll.copyWith(
        name: 'New',
        description: 'Updated',
        globalHeaders: {'X-Auth': 'token'},
      );
      await repo.updateCollection(updated);

      final fetched = await repo.getCollection(coll.id);
      expect(fetched?.name, 'New');
      expect(fetched?.description, 'Updated');
      expect(fetched?.globalHeaders, {'X-Auth': 'token'});
    });
  });

  group('deleteCollection', () {
    test('deletes a collection by id', () async {
      final coll = await repo.createCollection(name: 'ToDelete');
      await repo.deleteCollection(coll.id);

      final found = await repo.getCollection(coll.id);
      expect(found, isNull);
    });
  });

  group('getCollection', () {
    test('returns a collection by id', () async {
      final created = await repo.createCollection(name: 'FindMe');
      final found = await repo.getCollection(created.id);
      expect(found, isNotNull);
      expect(found!.name, 'FindMe');
    });

    test('returns null for unknown id', () async {
      final found = await repo.getCollection('nonexistent');
      expect(found, isNull);
    });
  });
}
