import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
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
    Map<String, String> globalHeaders = const {},
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
      'global_headers': jsonEncode(globalHeaders),
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    return Collection(
      id: id,
      name: name,
      description: description,
      sourceType: sourceType,
      sourceSpecId: sourceSpecId,
      globalHeaders: globalHeaders,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<Collection>> getAllCollections() async {
    final db = await DatabaseService.database;
    final rows = await db.query('collections', orderBy: 'created_at DESC');

    return rows.map(_rowToCollection).toList();
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
        'global_headers': jsonEncode(collection.globalHeaders),
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
    return _rowToCollection(rows.first);
  }

  Collection _rowToCollection(Map<String, dynamic> row) {
    final headersRaw = row['global_headers'] as String? ?? '{}';
    Map<String, String> globalHeaders = {};
    try {
      globalHeaders = Map<String, String>.from(jsonDecode(headersRaw));
    } catch (e) { debugPrint('Failed to parse collection headers: $e'); }

    return Collection(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      sourceType: row['source_type'] as String,
      sourceSpecId: row['source_spec_id'] as String?,
      globalHeaders: globalHeaders,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
