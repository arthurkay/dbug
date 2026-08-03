import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/openapi_spec.dart';
import '../../features/openapi/data/openapi_parser.dart';

class OpenApiRepository {
  static const _uuid = Uuid();

  static Future<OpenApiSpec> saveParsedSpec(ParsedSpec parsed, {String sourceType = 'file', String? sourceUrl}) async {
    final db = await DatabaseService.database;
    final id = _uuid.v4();
    final now = DateTime.now();

    final endpointsJson = parsed.endpoints.map((e) => e.toJson()).toList();

    await db.insert('openapi_specs', {
      'id': id,
      'title': parsed.title,
      'version': parsed.version,
      'base_url': parsed.baseUrl,
      'raw_content': parsed.rawContent,
      'parsed_endpoints': jsonEncode(endpointsJson),
      'source_type': sourceType,
      'source_url': sourceUrl,
      'imported_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    return OpenApiSpec(
      id: id,
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

  static Future<List<OpenApiSpec>> getAllSpecs() async {
    final db = await DatabaseService.database;
    final rows = await db.query('openapi_specs', orderBy: 'imported_at DESC');

    return rows.map((row) {
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
    }).toList();
  }

  static Future<void> deleteSpec(String id) async {
    final db = await DatabaseService.database;
    await db.delete('openapi_specs', where: 'id = ?', whereArgs: [id]);
  }

  static Future<OpenApiSpec?> getSpec(String id) async {
    final db = await DatabaseService.database;
    final rows = await db.query('openapi_specs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final row = rows.first;
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
