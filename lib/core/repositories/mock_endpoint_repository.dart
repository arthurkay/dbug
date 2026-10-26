import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/mock_endpoint.dart';

class MockEndpointRepository {
  static const _uuid = Uuid();

  /// Inserts a new endpoint. A second endpoint with the same method and path
  /// violates the unique index and throws a `DatabaseException`
  /// (`isUniqueConstraintError()`).
  Future<MockEndpoint> createEndpoint({
    required String method,
    required String path,
    int statusCode = 200,
    Map<String, String> headers = const {},
    String? body,
    int delayMs = 0,
  }) async {
    final db = await DatabaseService.database;
    final endpoint = MockEndpoint(
      id: _uuid.v4(),
      // Stored upper-case so matching and the unique index are case-blind.
      method: method.toUpperCase(),
      path: path,
      statusCode: statusCode,
      headers: headers,
      body: body,
      delayMs: delayMs,
    );

    await db.insert('mock_endpoints', {'id': endpoint.id, ..._toRow(endpoint)});
    return endpoint;
  }

  /// Updates an endpoint; throws like [createEndpoint] when the new method
  /// and path collide with another endpoint.
  Future<void> updateEndpoint(MockEndpoint endpoint) async {
    final db = await DatabaseService.database;
    await db.update(
      'mock_endpoints',
      _toRow(endpoint.copyWith(method: endpoint.method.toUpperCase())),
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
    return rows.map(_rowToEndpoint).toList();
  }

  /// Exact method + path lookup. The mock server itself matches in memory
  /// (see `matchMockEndpoint`), which also handles path parameters.
  Future<MockEndpoint?> matchEndpoint(String method, String path) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'mock_endpoints',
      where: 'method = ? AND path = ?',
      whereArgs: [method.toUpperCase(), path],
    );
    if (rows.isEmpty) return null;
    return _rowToEndpoint(rows.first);
  }

  Map<String, Object?> _toRow(MockEndpoint endpoint) => {
        'method': endpoint.method,
        'path': endpoint.path,
        'status_code': endpoint.statusCode,
        'headers': jsonEncode(endpoint.headers),
        'body': endpoint.body,
        'delay_ms': endpoint.delayMs,
      };

  MockEndpoint _rowToEndpoint(Map<String, dynamic> row) => MockEndpoint(
        id: row['id'] as String,
        method: row['method'] as String,
        path: row['path'] as String,
        statusCode: row['status_code'] as int? ?? 200,
        headers: Map<String, String>.from(jsonDecode(row['headers'] as String? ?? '{}')),
        body: row['body'] as String?,
        delayMs: row['delay_ms'] as int? ?? 0,
      );
}
