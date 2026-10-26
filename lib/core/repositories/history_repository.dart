import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../security/secret_cipher.dart';
import '../models/history_entry.dart';

class HistoryRepository {
  static const _uuid = Uuid();

  /// Response bodies larger than this many UTF-8 bytes are truncated before
  /// being stored. Settable so a user setting can change it at runtime.
  static int maxBodyBytes = 1024 * 1024;

  /// Only the newest [maxEntries] rows are kept; older ones are pruned on
  /// every insert. Settable so a user setting can change it at runtime.
  static int maxEntries = 500;

  /// Columns needed to render the history list — everything except the
  /// potentially large response body and headers.
  static const _listColumns = [
    'id', 'request_id', 'method', 'url', 'resolved_url', 'status_code',
    'response_time_ms', 'response_size', 'sent_at', 'request_name',
    'collection_id', 'headers', 'collection_headers', 'body', 'body_type',
    'query_params', 'auth_type', 'auth_data', 'response_truncated',
  ];

  Future<HistoryEntry> addEntry({
    String? requestId,
    required String method,
    required String url,
    String? resolvedUrl,
    int? statusCode,
    int? responseTimeMs,
    int? responseSize,
    String? responseBody,
    Map<String, String> responseHeaders = const {},
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

    final (storedBody, truncated) = truncateUtf8(responseBody, maxBodyBytes);
    final headersJson = jsonEncode(responseHeaders);

    await db.insert('history', {
      'id': id,
      'request_id': requestId,
      'method': method,
      'url': Secrets.sealForInsert(url, lockedFallback: ''),
      'resolved_url': resolvedUrl == null ? null : Secrets.sealForInsert(resolvedUrl, lockedFallback: ''),
      'status_code': statusCode,
      'response_time_ms': responseTimeMs,
      'response_size': responseSize,
      'response_body': storedBody,
      'response_headers': headersJson,
      'response_truncated': truncated ? 1 : 0,
      'sent_at': now.millisecondsSinceEpoch,
      'request_name': requestName,
      'collection_id': collectionId,
      'headers': Secrets.sealForInsert(headers),
      'collection_headers': Secrets.sealForInsert(collectionHeaders),
      'body': body,
      'body_type': bodyType,
      'query_params': queryParams,
      'auth_type': authType,
      'auth_data': Secrets.sealForInsert(authData),
    });
    await prune();

    return HistoryEntry(
      id: id,
      requestId: requestId,
      method: method,
      url: url,
      resolvedUrl: resolvedUrl,
      statusCode: statusCode,
      responseTimeMs: responseTimeMs,
      responseSize: responseSize,
      responseBody: storedBody,
      responseHeaders: headersJson,
      responseTruncated: truncated,
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

  /// Deletes all but the newest [maxEntries] rows.
  Future<void> prune() async {
    final db = await DatabaseService.database;
    await db.rawDelete(
      'DELETE FROM history WHERE id NOT IN '
      '(SELECT id FROM history ORDER BY sent_at DESC, rowid DESC LIMIT ?)',
      [maxEntries],
    );
  }

  /// Lists history without response bodies/headers (they can be megabytes
  /// each); load a full entry with [getEntry].
  Future<List<HistoryEntry>> getAllHistory() async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'history',
      columns: _listColumns,
      orderBy: 'sent_at DESC, rowid DESC',
      limit: maxEntries,
    );
    return rows.map(_rowToEntry).toList();
  }

  Future<HistoryEntry?> getEntry(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('history', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToEntry(rows.first);
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
      orderBy: 'sent_at DESC, rowid DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToEntry(rows.first);
  }

  HistoryEntry _rowToEntry(Map<String, dynamic> row) {
    return HistoryEntry(
      id: row['id'] as String,
      requestId: row['request_id'] as String?,
      method: row['method'] as String,
      url: Secrets.openOr(row['url'] as String?, ''),
      resolvedUrl: Secrets.cipher.open(row['resolved_url'] as String?),
      statusCode: row['status_code'] as int?,
      responseTimeMs: row['response_time_ms'] as int?,
      responseSize: row['response_size'] as int?,
      responseBody: row['response_body'] as String?,
      responseHeaders: (row['response_headers'] as String?) ?? '{}',
      responseTruncated: (row['response_truncated'] as int?) == 1,
      sentAt: DateTime.fromMillisecondsSinceEpoch(row['sent_at'] as int),
      requestName: row['request_name'] as String?,
      collectionId: row['collection_id'] as String?,
      headers: Secrets.openOr(row['headers'] as String?, '{}'),
      collectionHeaders: Secrets.openOr(row['collection_headers'] as String?, '{}'),
      body: row['body'] as String?,
      bodyType: row['body_type'] as String?,
      queryParams: (row['query_params'] as String?) ?? '{}',
      authType: (row['auth_type'] as String?) ?? 'none',
      authData: Secrets.openOr(row['auth_data'] as String?, '{}'),
    );
  }
}

/// Cuts [text] to at most [maxBytes] UTF-8 bytes without splitting a
/// multi-byte character. Returns the (possibly shortened) text and whether it
/// was cut.
(String?, bool) truncateUtf8(String? text, int maxBytes) {
  if (text == null) return (null, false);
  final bytes = utf8.encode(text);
  if (bytes.length <= maxBytes) return (text, false);
  var end = maxBytes;
  // Back up over continuation bytes (10xxxxxx) to a character boundary.
  while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
    end--;
  }
  return (utf8.decode(bytes.sublist(0, end)), true);
}
