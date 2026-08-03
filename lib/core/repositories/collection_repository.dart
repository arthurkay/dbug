import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/collection_model.dart';

class CollectionRepository {
  static const _uuid = Uuid();

  Future<Collection> createCollection({
    required String name,
    String? description,
    String sourceType = 'manual',
    String? sourceSpecId,
  }) async {
    final db = await DatabaseService.database;
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.insert('collections', {
      'id': id,
      'name': name,
      'description': description,
      'source_type': sourceType,
      'source_spec_id': sourceSpecId,
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    return Collection(
      id: id,
      name: name,
      description: description,
      sourceType: sourceType,
      sourceSpecId: sourceSpecId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<Collection>> getAllCollections() async {
    final db = await DatabaseService.database;
    final rows = await db.query('collections', orderBy: 'created_at DESC');

    return rows.map((row) => Collection(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      sourceType: row['source_type'] as String,
      sourceSpecId: row['source_spec_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    )).toList();
  }

  Future<void> updateCollection(Collection collection) async {
    final db = await DatabaseService.database;
    await db.update(
      'collections',
      {
        'name': collection.name,
        'description': collection.description,
        'source_type': collection.sourceType,
        'source_spec_id': collection.sourceSpecId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  Future<void> deleteCollection(String id) async {
    final db = await DatabaseService.database;
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
  }

  Future<Collection?> getCollection(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('collections', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final row = rows.first;
    return Collection(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      sourceType: row['source_type'] as String,
      sourceSpecId: row['source_spec_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
