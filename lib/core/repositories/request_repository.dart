import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/request_model.dart';

class RequestRepository {
  static const _uuid = Uuid();

  Future<RequestModel> createRequest({
    String? collectionId,
    required String name,
    required String method,
    required String url,
    Map<String, String> headers = const {},
    String? bodyType,
    String? body,
    Map<String, String> queryParams = const {},
  }) async {
    final db = await DatabaseService.database;
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.insert('requests', {
      'id': id,
      'collection_id': collectionId,
      'name': name,
      'method': method,
      'url': url,
      'headers': jsonEncode(headers),
      'body_type': bodyType,
      'body': body,
      'query_params': jsonEncode(queryParams),
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    return RequestModel(
      id: id,
      collectionId: collectionId,
      name: name,
      method: method,
      url: url,
      headers: headers,
      bodyType: bodyType,
      body: body,
      queryParams: queryParams,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateRequest(RequestModel request) async {
    final db = await DatabaseService.database;
    await db.update(
      'requests',
      {
        'collection_id': request.collectionId,
        'name': request.name,
        'method': request.method,
        'url': request.url,
        'headers': jsonEncode(request.headers),
        'body_type': request.bodyType,
        'body': request.body,
        'query_params': jsonEncode(request.queryParams),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  Future<List<RequestModel>> getRequestsByCollection(String collectionId) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'requests',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'created_at ASC',
    );

    return rows.map(_rowToRequest).toList();
  }

  Future<List<RequestModel>> getAllRequests() async {
    final db = await DatabaseService.database;
    final rows = await db.query('requests', orderBy: 'created_at DESC');
    return rows.map(_rowToRequest).toList();
  }

  Future<RequestModel?> getRequest(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('requests', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToRequest(rows.first);
  }

  Future<void> deleteRequest(String id) async {
    final db = await DatabaseService.database;
    await db.delete('requests', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByCollection(String collectionId) async {
    final db = await DatabaseService.database;
    await db.delete('requests', where: 'collection_id = ?', whereArgs: [collectionId]);
  }

  Future<int> countByCollection(String collectionId) async {
    final db = await DatabaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM requests WHERE collection_id = ?',
      [collectionId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  RequestModel _rowToRequest(Map<String, dynamic> row) {
    final headersRaw = row['headers'] as String? ?? '{}';
    final queryParamsRaw = row['query_params'] as String? ?? '{}';

    return RequestModel(
      id: row['id'] as String,
      collectionId: row['collection_id'] as String?,
      name: row['name'] as String,
      method: row['method'] as String,
      url: row['url'] as String,
      headers: Map<String, String>.from(jsonDecode(headersRaw)),
      bodyType: row['body_type'] as String?,
      body: row['body'] as String?,
      queryParams: Map<String, String>.from(jsonDecode(queryParamsRaw)),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
