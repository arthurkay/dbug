import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/environment_model.dart';

class EnvironmentRepository {
  static const _uuid = Uuid();

  Future<Environment> createEnvironment({
    required String name,
    Map<String, String> variables = const {},
  }) async {
    final db = await DatabaseService.database;
    final id = _uuid.v4();

    await db.insert('environments', {
      'id': id,
      'name': name,
      'variables': jsonEncode(variables),
      'is_active': 0,
    });

    return Environment(id: id, name: name, variables: variables);
  }

  Future<void> updateEnvironment(Environment env) async {
    final db = await DatabaseService.database;
    await db.update(
      'environments',
      {
        'name': env.name,
        'variables': jsonEncode(env.variables),
        'is_active': env.isActive ? 1 : 0,
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

  Future<void> deleteEnvironment(String id) async {
    final db = await DatabaseService.database;
    await db.delete('environments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Environment>> getAllEnvironments() async {
    final db = await DatabaseService.database;
    final rows = await db.query('environments', orderBy: 'name ASC');

    return rows.map((row) => Environment(
      id: row['id'] as String,
      name: row['name'] as String,
      variables: Map<String, String>.from(jsonDecode(row['variables'] as String? ?? '{}')),
      isActive: (row['is_active'] as int?) == 1,
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
    );
  }
}
