import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/history_entry.dart';

class HistoryRepository {
  static const _uuid = Uuid();

  Future<HistoryEntry> addEntry({
    String? requestId,
    required String method,
    required String url,
    int? statusCode,
    int? responseTimeMs,
    int? responseSize,
    String? responseBody,
    String? requestName,
    String? collectionId,
    String headers = '{}',
    String collectionHeaders = '{}',
    String? body,
    String? bodyType,
    String queryParams = '{}',
    String authType = 'none',
    String authData = '{}',
  }) async {
    final db = await DatabaseService.database;
    final id = _uuid.v4();
    final now = DateTime.now();

    await db.insert('history', {
      'id': id,
      'request_id': requestId,
      'method': method,
      'url': url,
      'status_code': statusCode,
      'response_time_ms': responseTimeMs,
      'response_size': responseSize,
      'response_body': responseBody,
      'sent_at': now.millisecondsSinceEpoch,
      'request_name': requestName,
      'collection_id': collectionId,
      'headers': headers,
      'collection_headers': collectionHeaders,
      'body': body,
      'body_type': bodyType,
      'query_params': queryParams,
      'auth_type': authType,
      'auth_data': authData,
    });

    return HistoryEntry(
      id: id,
      requestId: requestId,
      method: method,
      url: url,
      statusCode: statusCode,
      responseTimeMs: responseTimeMs,
      responseSize: responseSize,
      responseBody: responseBody,
      sentAt: now,
      requestName: requestName,
      collectionId: collectionId,
      headers: headers,
      collectionHeaders: collectionHeaders,
      body: body,
      bodyType: bodyType,
      queryParams: queryParams,
      authType: authType,
      authData: authData,
    );
  }

  Future<List<HistoryEntry>> getAllHistory() async {
    final db = await DatabaseService.database;
    final rows = await db.query('history', orderBy: 'sent_at DESC', limit: 500);

    return rows.map((row) => HistoryEntry(
      id: row['id'] as String,
      requestId: row['request_id'] as String?,
      method: row['method'] as String,
      url: row['url'] as String,
      statusCode: row['status_code'] as int?,
      responseTimeMs: row['response_time_ms'] as int?,
      responseSize: row['response_size'] as int?,
      responseBody: row['response_body'] as String?,
      sentAt: DateTime.fromMillisecondsSinceEpoch(row['sent_at'] as int),
      requestName: row['request_name'] as String?,
      collectionId: row['collection_id'] as String?,
      headers: (row['headers'] as String?) ?? '{}',
      collectionHeaders: (row['collection_headers'] as String?) ?? '{}',
      body: row['body'] as String?,
      bodyType: row['body_type'] as String?,
      queryParams: (row['query_params'] as String?) ?? '{}',
      authType: (row['auth_type'] as String?) ?? 'none',
      authData: (row['auth_data'] as String?) ?? '{}',
    )).toList();
  }

  Future<void> deleteEntry(String id) async {
    final db = await DatabaseService.database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await DatabaseService.database;
    await db.delete('history');
  }

  Future<int> count() async {
    final db = await DatabaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM history');
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<HistoryEntry?> getLatestByRequestId(String requestId) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'history',
      where: 'request_id = ?',
      whereArgs: [requestId],
      orderBy: 'sent_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return HistoryEntry(
      id: row['id'] as String,
      requestId: row['request_id'] as String?,
      method: row['method'] as String,
      url: row['url'] as String,
      statusCode: row['status_code'] as int?,
      responseTimeMs: row['response_time_ms'] as int?,
      responseSize: row['response_size'] as int?,
      responseBody: row['response_body'] as String?,
      sentAt: DateTime.fromMillisecondsSinceEpoch(row['sent_at'] as int),
      requestName: row['request_name'] as String?,
      collectionId: row['collection_id'] as String?,
      headers: (row['headers'] as String?) ?? '{}',
      collectionHeaders: (row['collection_headers'] as String?) ?? '{}',
      body: row['body'] as String?,
      bodyType: row['body_type'] as String?,
      queryParams: (row['query_params'] as String?) ?? '{}',
      authType: (row['auth_type'] as String?) ?? 'none',
      authData: (row['auth_data'] as String?) ?? '{}',
    );
  }
}
