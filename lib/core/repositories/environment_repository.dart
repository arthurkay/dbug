import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/environment_model.dart';

class EnvironmentRepository {
  static const _uuid = Uuid();

  Future<Environment> createEnvironment({
    required String name,
    Map<String, String> variables = const {},
    String sourceType = 'user',
  }) async {
    final db = await DatabaseService.database;
    final id = _uuid.v4();

    await db.insert('environments', {
      'id': id,
      'name': name,
      'variables': jsonEncode(variables),
      'is_active': 0,
      'source_type': sourceType,
    });

    return Environment(id: id, name: name, variables: variables, sourceType: sourceType);
  }

  Future<void> updateEnvironment(Environment env) async {
    final db = await DatabaseService.database;
    await db.update(
      'environments',
      {
        'name': env.name,
        'variables': jsonEncode(env.variables),
        'is_active': env.isActive ? 1 : 0,
        'source_type': env.sourceType,
      },
      where: 'id = ?',
      whereArgs: [env.id],
    );
  }

  Future<void> setActive(String id) async {
    final db = await DatabaseService.database;
    await db.update('environments', {'is_active': 0});
    await db.update('environments', {'is_active': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearActive() async {
    final db = await DatabaseService.database;
    await db.update('environments', {'is_active': 0});
  }

  Future<void> deleteEnvironment(String id) async {
    final db = await DatabaseService.database;
    await db.delete('environments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBySourceType(String sourceType) async {
    final db = await DatabaseService.database;
    await db.delete('environments', where: 'source_type = ?', whereArgs: [sourceType]);
  }

  Future<void> deleteByCollectionId(String collectionId) async {
    final db = await DatabaseService.database;
    await db.delete('environments', where: 'source_type = ? AND name LIKE ?', whereArgs: ['openapi', '%$collectionId%']);
  }

  Future<List<Environment>> getAllEnvironments() async {
    final db = await DatabaseService.database;
    final rows = await db.query('environments', orderBy: 'name ASC');

    return rows.map((row) => Environment(
      id: row['id'] as String,
      name: row['name'] as String,
      variables: Map<String, String>.from(jsonDecode(row['variables'] as String? ?? '{}')),
      isActive: (row['is_active'] as int?) == 1,
      sourceType: row['source_type'] as String? ?? 'user',
    )).toList();
  }

  Future<List<Environment>> getUserEnvironments() async {
    final db = await DatabaseService.database;
    final rows = await db.query('environments', where: 'source_type = ?', whereArgs: ['user'], orderBy: 'name ASC');

    return rows.map((row) => Environment(
      id: row['id'] as String,
      name: row['name'] as String,
      variables: Map<String, String>.from(jsonDecode(row['variables'] as String? ?? '{}')),
      isActive: (row['is_active'] as int?) == 1,
      sourceType: 'user',
    )).toList();
  }

  Future<Environment?> getActive() async {
    final db = await DatabaseService.database;
    final rows = await db.query('environments', where: 'is_active = ?', whereArgs: [1]);
    if (rows.isEmpty) return null;

    final row = rows.first;
    return Environment(
      id: row['id'] as String,
      name: row['name'] as String,
      variables: Map<String, String>.from(jsonDecode(row['variables'] as String? ?? '{}')),
      isActive: true,
      sourceType: row['source_type'] as String? ?? 'user',
    );
  }

  Future<Environment?> getForCollection(String collectionId) async {
    final db = await DatabaseService.database;
    final collRows = await db.query('collections', where: 'id = ?', whereArgs: [collectionId]);
    if (collRows.isEmpty) return null;
    final specId = collRows.first['source_spec_id'] as String?;
    if (specId == null) return null;
    final rows = await db.query('environments', where: 'name LIKE ?', whereArgs: ['%API%']);
    for (final row in rows) {
      final vars = Map<String, String>.from(jsonDecode(row['variables'] as String? ?? '{}'));
      if (vars.containsKey('baseUrl')) {
        return Environment(
          id: row['id'] as String,
          name: row['name'] as String,
          variables: vars,
          isActive: (row['is_active'] as int?) == 1,
          sourceType: row['source_type'] as String? ?? 'openapi',
        );
      }
    }
    return null;
  }
}
