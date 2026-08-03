import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/mock_endpoint.dart';

class MockEndpointRepository {
  static const _uuid = Uuid();

  Future<MockEndpoint> createEndpoint({
    required String method,
    required String path,
    int statusCode = 200,
    Map<String, String> headers = const {},
    String? body,
    int delayMs = 0,
  }) async {
    final db = await DatabaseService.database;
    final id = _uuid.v4();

    await db.insert('mock_endpoints', {
      'id': id,
      'method': method,
      'path': path,
      'status_code': statusCode,
      'headers': jsonEncode(headers),
      'body': body,
      'delay_ms': delayMs,
    });

    return MockEndpoint(
      id: id,
      method: method,
      path: path,
      statusCode: statusCode,
      headers: headers,
      body: body,
      delayMs: delayMs,
    );
  }

  Future<void> updateEndpoint(MockEndpoint endpoint) async {
    final db = await DatabaseService.database;
    await db.update(
      'mock_endpoints',
      {
        'method': endpoint.method,
        'path': endpoint.path,
        'status_code': endpoint.statusCode,
        'headers': jsonEncode(endpoint.headers),
        'body': endpoint.body,
        'delay_ms': endpoint.delayMs,
      },
      where: 'id = ?',
      whereArgs: [endpoint.id],
    );
  }

  Future<void> deleteEndpoint(String id) async {
    final db = await DatabaseService.database;
    await db.delete('mock_endpoints', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MockEndpoint>> getAllEndpoints() async {
    final db = await DatabaseService.database;
    final rows = await db.query('mock_endpoints', orderBy: 'path ASC');

    return rows.map((row) => MockEndpoint(
      id: row['id'] as String,
      method: row['method'] as String,
      path: row['path'] as String,
      statusCode: row['status_code'] as int? ?? 200,
      headers: Map<String, String>.from(jsonDecode(row['headers'] as String? ?? '{}')),
      body: row['body'] as String?,
      delayMs: row['delay_ms'] as int? ?? 0,
    )).toList();
  }

  Future<MockEndpoint?> matchEndpoint(String method, String path) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'mock_endpoints',
      where: 'method = ? AND path = ?',
      whereArgs: [method.toUpperCase(), path],
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    return MockEndpoint(
      id: row['id'] as String,
      method: row['method'] as String,
      path: row['path'] as String,
      statusCode: row['status_code'] as int? ?? 200,
      headers: Map<String, String>.from(jsonDecode(row['headers'] as String? ?? '{}')),
      body: row['body'] as String?,
      delayMs: row['delay_ms'] as int? ?? 0,
    );
  }
}
