import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../security/secret_cipher.dart';
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
    String authType = 'none',
    String authData = '{}',
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
      'headers': Secrets.sealForInsert(jsonEncode(headers)),
      'body_type': bodyType,
      'body': body,
      'query_params': jsonEncode(queryParams),
      'auth_type': authType,
      'auth_data': Secrets.sealForInsert(authData),
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
      authType: authType,
      authData: authData,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateRequest(RequestModel request) async {
    final db = await DatabaseService.database;
    await db.update(
      'requests',
      Secrets.sealedUpdate({
        'collection_id': request.collectionId,
        'name': request.name,
        'method': request.method,
        'url': request.url,
        'body_type': request.bodyType,
        'body': request.body,
        'query_params': jsonEncode(request.queryParams),
        'auth_type': request.authType,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, {
        'headers': jsonEncode(request.headers),
        'auth_data': request.authData,
      }),
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
    final headersRaw = Secrets.openOr(row['headers'] as String?, '{}');
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
      authType: row['auth_type'] as String? ?? 'none',
      authData: Secrets.openOr(row['auth_data'] as String?, '{}'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
