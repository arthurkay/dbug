import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/models/environment_model.dart';
import 'package:dbug/core/models/request_model.dart';
import 'package:dbug/core/models/response_model.dart';
import 'package:dbug/core/models/collection_model.dart';
import 'package:dbug/core/models/history_entry.dart';
import 'package:dbug/core/models/mock_endpoint.dart';
import 'package:dbug/core/models/openapi_spec.dart';

void main() {
  group('Environment edge cases', () {
    test('fromJson with empty map produces valid object', () {
      final env = Environment.fromJson({
        'id': '1',
        'name': 'test',
      });
      expect(env.id, '1');
      expect(env.name, 'test');
      expect(env.variables, isEmpty);
      expect(env.isActive, isFalse);
      expect(env.sourceType, 'user');
    });

    test('copyWith preserves unmodified fields', () {
      final env = Environment(
        id: '1', name: 'A', variables: {'k': 'v'},
        isActive: true, sourceType: 'openapi',
      );
      final copy = env.copyWith(name: 'B');
      expect(copy.id, '1');
      expect(copy.variables, {'k': 'v'});
      expect(copy.isActive, isTrue);
      expect(copy.sourceType, 'openapi');
      expect(copy.name, 'B');
    });

    test('equality works correctly', () {
      final env1 = Environment(id: '1', name: 'A');
      final env2 = Environment(id: '1', name: 'A');
      final env3 = Environment(id: '2', name: 'A');
      expect(env1, equals(env2));
      expect(env1 == env3, isFalse);
    });
  });

  group('RequestModel edge cases', () {
    test('fromJson with minimal fields', () {
      final req = RequestModel.fromJson({
        'id': '1',
        'name': 'test',
        'method': 'GET',
        'url': 'http://test.com',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      });
      expect(req.id, '1');
      expect(req.collectionId, isNull);
      expect(req.bodyType, isNull);
      expect(req.body, isNull);
    });

    test('copyWith with all fields', () {
      final now = DateTime(2024);
      final req = RequestModel(
        id: '1', name: 'Old', method: 'GET', url: 'http://old.com',
        createdAt: now, updatedAt: now,
      );
      final updated = req.copyWith(
        name: 'New',
        method: 'POST',
        url: 'http://new.com',
        collectionId: 'c1',
        headers: {'X-Key': 'val'},
        bodyType: 'json',
        body: '{"data": true}',
        queryParams: {'page': '1'},
        updatedAt: DateTime(2025),
      );
      expect(updated.name, 'New');
      expect(updated.method, 'POST');
      expect(updated.collectionId, 'c1');
      expect(updated.headers, {'X-Key': 'val'});
    });
  });

  group('ResponseModel edge cases', () {
    test('fromJson with all fields', () {
      final resp = ResponseModel.fromJson({
        'statusCode': 404,
        'headers': {'x-error': 'not found'},
        'body': 'Not Found',
        'timeMs': 50,
        'sizeBytes': 9,
      });
      expect(resp.statusCode, 404);
      expect(resp.body, 'Not Found');
    });

    test('toJson produces correct keys', () {
      const resp = ResponseModel(
        statusCode: 200,
        headers: {'ct': 'json'},
        body: '{}',
        timeMs: 10,
        sizeBytes: 2,
      );
      final json = resp.toJson();
      expect(json['statusCode'], 200);
      expect(json['headers'], {'ct': 'json'});
      expect(json['body'], '{}');
      expect(json['timeMs'], 10);
      expect(json['sizeBytes'], 2);
    });
  });

  group('Collection edge cases', () {
    test('fromJson with nulls', () {
      final coll = Collection.fromJson({
        'id': '1',
        'name': 'Test',
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      });
      expect(coll.description, isNull);
      expect(coll.sourceSpecId, isNull);
      expect(coll.sourceType, 'manual');
    });

    test('copyWith modifies specific fields', () {
      final now = DateTime(2024);
      final coll = Collection(
        id: '1', name: 'Old', description: 'desc',
        sourceType: 'manual', globalHeaders: {},
        createdAt: now, updatedAt: now,
      );
      final updated = coll.copyWith(
        name: 'New',
        globalHeaders: {'X-Tenant': 'acme'},
      );
      expect(updated.name, 'New');
      expect(updated.description, 'desc');
      expect(updated.globalHeaders, {'X-Tenant': 'acme'});
    });
  });

  group('HistoryEntry edge cases', () {
    test('fromJson with all nullable fields as null', () {
      final entry = HistoryEntry.fromJson({
        'id': '1',
        'method': 'GET',
        'url': 'http://test.com',
        'sentAt': '2024-01-01T00:00:00.000',
      });
      expect(entry.requestId, isNull);
      expect(entry.statusCode, isNull);
      expect(entry.responseTimeMs, isNull);
      expect(entry.responseSize, isNull);
      expect(entry.responseBody, isNull);
      expect(entry.requestName, isNull);
      expect(entry.collectionId, isNull);
      expect(entry.body, isNull);
      expect(entry.bodyType, isNull);
    });

    test('fromJson defaults for string-encoded JSON fields', () {
      final entry = HistoryEntry.fromJson({
        'id': '1',
        'method': 'GET',
        'url': 'http://test.com',
        'sentAt': '2024-01-01T00:00:00.000',
      });
      expect(entry.headers, '{}');
      expect(entry.collectionHeaders, '{}');
      expect(entry.queryParams, '{}');
      expect(entry.authType, 'none');
      expect(entry.authData, '{}');
    });
  });

  group('MockEndpoint edge cases', () {
    test('fromJson with minimal fields', () {
      final ep = MockEndpoint.fromJson({
        'id': '1',
        'method': 'GET',
        'path': '/test',
      });
      expect(ep.statusCode, 200);
      expect(ep.headers, isEmpty);
      expect(ep.body, isNull);
      expect(ep.delayMs, 0);
    });

    test('copyWith modifies specific fields', () {
      const ep = MockEndpoint(id: '1', method: 'GET', path: '/old');
      final updated = ep.copyWith(method: 'POST', path: '/new', statusCode: 201);
      expect(updated.method, 'POST');
      expect(updated.path, '/new');
      expect(updated.statusCode, 201);
      expect(updated.id, '1');
    });
  });

  group('OpenApiSpec edge cases', () {
    test('fromJson with empty endpoints list', () {
      final spec = OpenApiSpec.fromJson({
        'id': '1',
        'rawContent': '{}',
        'sourceType': 'file',
        'importedAt': '2024-01-01T00:00:00.000',
        'endpoints': [],
      });
      expect(spec.endpoints, isEmpty);
      expect(spec.title, isNull);
      expect(spec.baseUrl, isNull);
      expect(spec.sourceUrl, isNull);
      expect(spec.updatedAt, isNull);
    });

    test('copyWith modifies specific fields', () {
      final now = DateTime(2024);
      final spec = OpenApiSpec(
        id: '1', rawContent: '{}', sourceType: 'file',
        importedAt: now, endpoints: [],
      );
      final updated = spec.copyWith(title: 'New API', version: '2.0');
      expect(updated.title, 'New API');
      expect(updated.version, '2.0');
      expect(updated.id, '1');
      expect(updated.rawContent, '{}');
    });
  });

  group('OpenApiParameter edge cases', () {
    test('fromJson with defaults', () {
      final param = OpenApiParameter.fromJson({
        'name': 'id',
        'location': 'path',
      });
      expect(param.description, isNull);
      expect(param.required, isFalse);
      expect(param.type, isNull);
      expect(param.schemaType, isNull);
    });
  });

  group('OpenApiSchema edge cases', () {
    test('fromJson with empty schema', () {
      final schema = OpenApiSchema.fromJson({});
      expect(schema.type, isNull);
      expect(schema.format, isNull);
      expect(schema.ref, isNull);
      expect(schema.description, isNull);
      expect(schema.properties, isEmpty);
      expect(schema.requiredFields, isEmpty);
      expect(schema.items, isNull);
      expect(schema.enumValues, isEmpty);
    });

    test('nested schema round-trip', () {
      final schema = OpenApiSchema(
        type: 'object',
        properties: {
          'items': OpenApiSchema(
            type: 'array',
            items: OpenApiSchema(type: 'string'),
          ),
        },
      );
      final json = schema.toJson();
      final restored = OpenApiSchema.fromJson(json);
      expect(restored.type, 'object');
      expect(restored.properties['items']!.type, 'array');
      expect(restored.properties['items']!.items!.type, 'string');
    });
  });

  group('OpenApiEndpoint edge cases', () {
    test('fromJson with empty parameters', () {
      final ep = OpenApiEndpoint.fromJson({
        'path': '/test',
        'method': 'GET',
      });
      expect(ep.summary, isNull);
      expect(ep.description, isNull);
      expect(ep.operationId, isNull);
      expect(ep.parameters, isEmpty);
      expect(ep.requestBodySchema, isNull);
      expect(ep.responseSchemas, isNull);
      expect(ep.tags, isEmpty);
    });
  });
}
