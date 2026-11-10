import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show DatabaseException;
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../security/secret_cipher.dart';
import '../models/openapi_spec.dart';
import '../../features/openapi/data/openapi_parser.dart';
import '../../features/openapi/data/schema_skeleton.dart';
import '../../features/openapi/data/spec_paths.dart';

/// List-row data for a spec, without its raw content or parsed endpoints.
class OpenApiSpecSummary {
  final String id;
  final String? title;
  final String? version;
  final int endpointCount;
  final DateTime importedAt;

  const OpenApiSpecSummary({
    required this.id,
    this.title,
    this.version,
    required this.endpointCount,
    required this.importedAt,
  });
}

/// Name of the environment created for an imported spec. Titles usually
/// already end in "API" ("Billing Service API"), so don't repeat it.
String specEnvironmentName(String? title) {
  final t = title?.trim();
  if (t == null || t.isEmpty) return 'Imported API';
  return RegExp(r'\bapi$', caseSensitive: false).hasMatch(t) ? t : '$t API';
}

class OpenApiRepository {
  static const _uuid = Uuid();

  /// Saves the spec plus a generated collection (one request per endpoint,
  /// prefilled with query/header params and a JSON body skeleton) and an
  /// environment holding `baseUrl` and the path parameters. Runs in a single
  /// transaction, so a failure leaves nothing half-imported.
  Future<OpenApiSpec> saveParsedSpec(ParsedSpec parsed, {String sourceType = 'file', String? sourceUrl}) async {
    final db = await DatabaseService.database;
    final specId = _uuid.v4();
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final endpointsJson = parsed.endpoints.map((e) => e.toJson()).toList();
    final baseUrl = parsed.baseUrlTemplate ?? parsed.baseUrl ?? '';
    final allPathParams = <String>{};

    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.insert('openapi_specs', {
        'id': specId,
        'title': parsed.title,
        'version': parsed.version,
        'base_url': parsed.baseUrl,
        'raw_content': parsed.rawContent,
        'parsed_endpoints': jsonEncode(endpointsJson),
        'source_type': sourceType,
        'source_url': sourceUrl,
        'imported_at': nowMs,
        'updated_at': nowMs,
      });

      final collectionId = _uuid.v4();
      batch.insert('collections', {
        'id': collectionId,
        'name': parsed.title ?? 'Imported Spec',
        'description': '${parsed.endpoints.length} endpoints • ${parsed.version ?? ''}',
        'source_type': 'openapi',
        'source_spec_id': specId,
        'created_at': nowMs,
        'updated_at': nowMs,
      });

      for (final ep in parsed.endpoints) {
        allPathParams.addAll(specPathParams(ep.path));
        final query = {
          for (final p in ep.parameters.where((p) => p.location == 'query')) p.name: p.example ?? '',
        };
        final headers = {
          for (final p in ep.parameters.where((p) => p.location == 'header')) p.name: p.example ?? '',
        };
        final skeleton = schemaSkeleton(ep.requestBodySchema);

        batch.insert('requests', {
          'id': _uuid.v4(),
          'collection_id': collectionId,
          'name': ep.summary ?? '${ep.method} ${ep.path}',
          'method': ep.method,
          'url': specRequestUrl(ep.path, hasBaseUrl: baseUrl.isNotEmpty),
          'headers': Secrets.sealForInsert(jsonEncode(headers)),
          'body_type': skeleton != null ? 'json' : null,
          'body': skeleton != null ? const JsonEncoder.withIndent('  ').convert(skeleton) : null,
          'query_params': jsonEncode(query),
          'created_at': nowMs,
          'updated_at': nowMs,
        });
      }

      if (baseUrl.isNotEmpty || allPathParams.isNotEmpty) {
        final variables = <String, String>{};
        if (baseUrl.isNotEmpty) {
          variables['baseUrl'] = baseUrl;
          variables.addAll(parsed.serverVariables);
        }
        for (final param in allPathParams) {
          variables[param] = '';
        }
        batch.insert('environments', {
          'id': _uuid.v4(),
          'name': specEnvironmentName(parsed.title),
          'variables': Secrets.sealForInsert(jsonEncode(variables)),
          'is_active': 0,
          'source_type': 'openapi',
          'source_spec_id': specId,
        });
      }

      await batch.commit(noResult: true);
    });

    return OpenApiSpec(
      id: specId,
      title: parsed.title,
      version: parsed.version,
      baseUrl: parsed.baseUrl,
      rawContent: parsed.rawContent,
      endpoints: parsed.endpoints,
      sourceType: sourceType,
      sourceUrl: sourceUrl,
      importedAt: now,
      updatedAt: now,
    );
  }

  Future<List<OpenApiSpec>> getAllSpecs() async {
    final db = await DatabaseService.database;
    final rows = await db.query('openapi_specs', orderBy: 'imported_at DESC');
    return rows.map(_rowToSpec).toList();
  }

  /// Specs for list views, without loading raw content or endpoints.
  Future<List<OpenApiSpecSummary>> getSpecSummaries() async {
    final db = await DatabaseService.database;
    List<Map<String, Object?>> rows;
    try {
      rows = await db.rawQuery(
        'SELECT id, title, version, imported_at, '
        'json_array_length(parsed_endpoints) AS endpoint_count '
        'FROM openapi_specs ORDER BY imported_at DESC',
      );
    } on DatabaseException {
      // System SQLite built without JSON1: count in Dart (still skips the
      // much larger raw_content column).
      final full = await db.query(
        'openapi_specs',
        columns: ['id', 'title', 'version', 'imported_at', 'parsed_endpoints'],
        orderBy: 'imported_at DESC',
      );
      rows = full
          .map((r) => {
                ...r,
                'endpoint_count': (jsonDecode(r['parsed_endpoints'] as String? ?? '[]') as List).length,
              })
          .toList();
    }
    return rows
        .map((row) => OpenApiSpecSummary(
              id: row['id'] as String,
              title: row['title'] as String?,
              version: row['version'] as String?,
              endpointCount: (row['endpoint_count'] as int?) ?? 0,
              importedAt: DateTime.fromMillisecondsSinceEpoch(row['imported_at'] as int),
            ))
        .toList();
  }

  /// Deletes the spec with its generated collection, requests and
  /// environment, in one transaction.
  Future<void> deleteSpec(String id) async {
    final db = await DatabaseService.database;
    await db.transaction((txn) async {
      final specRows = await txn.query('openapi_specs', where: 'id = ?', whereArgs: [id], columns: ['title']);
      final specTitle = specRows.isNotEmpty ? specRows.first['title'] as String? : null;

      await txn.delete(
        'requests',
        where: 'collection_id IN (SELECT id FROM collections WHERE source_spec_id = ?)',
        whereArgs: [id],
      );
      await txn.delete('collections', where: 'source_spec_id = ?', whereArgs: [id]);

      await txn.delete('environments', where: 'source_spec_id = ?', whereArgs: [id]);
      // Legacy fallback: environments created before source_spec_id existed can
      // only be matched by their generated name.
      final legacyName = specTitle != null ? '$specTitle API' : 'Imported API';
      await txn.delete(
        'environments',
        where: 'source_spec_id IS NULL AND name = ? AND source_type = ?',
        whereArgs: [legacyName, 'openapi'],
      );

      await txn.delete('openapi_specs', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<OpenApiSpec?> getSpec(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('openapi_specs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToSpec(rows.first);
  }

  /// The id of the collection generated for [specId], or null if it was
  /// deleted.
  Future<String?> getCollectionForSpec(String specId) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'collections',
      columns: ['id'],
      where: 'source_spec_id = ?',
      whereArgs: [specId],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as String;
  }

  OpenApiSpec _rowToSpec(Map<String, dynamic> row) {
    final endpointsRaw = jsonDecode(row['parsed_endpoints'] as String? ?? '[]') as List;
    final endpoints = endpointsRaw.map((e) => OpenApiEndpoint.fromJson(e as Map<String, dynamic>)).toList();

    return OpenApiSpec(
      id: row['id'] as String,
      title: row['title'] as String?,
      version: row['version'] as String?,
      baseUrl: row['base_url'] as String?,
      rawContent: row['raw_content'] as String,
      endpoints: endpoints,
      sourceType: row['source_type'] as String,
      sourceUrl: row['source_url'] as String?,
      importedAt: DateTime.fromMillisecondsSinceEpoch(row['imported_at'] as int),
      updatedAt: row['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int)
          : null,
    );
  }
}
