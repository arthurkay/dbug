import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/models/environment_model.dart';
import 'package:dbug/core/models/request_model.dart';
import 'package:dbug/core/models/response_model.dart';
import 'package:dbug/core/models/collection_model.dart';
import 'package:dbug/core/models/history_entry.dart';
import 'package:dbug/core/models/mock_endpoint.dart';
import 'package:dbug/core/models/openapi_spec.dart';

void main() {
  group('Environment', () {
    test('serialization round-trip', () {
      final env = Environment(
        id: 'env-1',
        name: 'dev',
        variables: {'host': 'localhost', 'port': '3000'},
        isActive: true,
        sourceType: 'user',
      );
      final json = env.toJson();
      final restored = Environment.fromJson(json);
      expect(restored, env);
    });

    test('isUserDefined returns true for user sourceType', () {
      final env = Environment(id: '1', name: 'test', sourceType: 'user');
      expect(env.isUserDefined, isTrue);
      expect(env.isOpenApiDefined, isFalse);
    });

    test('isOpenApiDefined returns true for openapi sourceType', () {
      final env = Environment(id: '1', name: 'test', sourceType: 'openapi');
      expect(env.isOpenApiDefined, isTrue);
      expect(env.isUserDefined, isFalse);
    });

    test('defaults are correct', () {
      final env = Environment(id: '1', name: 'test');
      expect(env.variables, isEmpty);
      expect(env.isActive, isFalse);
      expect(env.sourceType, 'user');
    });
  });

  group('RequestModel', () {
    test('serialization round-trip', () {
      final now = DateTime(2024);
      final req = RequestModel(
        id: 'req-1',
        collectionId: 'coll-1',
        name: 'Get Users',
        method: 'GET',
        url: 'https://api.example.com/users',
        headers: {'Authorization': 'Bearer token'},
        bodyType: 'json',
        body: '{"name": "test"}',
        queryParams: {'page': '1'},
        createdAt: now,
        updatedAt: now,
      );
      final json = req.toJson();
      final restored = RequestModel.fromJson(json);
      expect(restored.id, req.id);
      expect(restored.collectionId, req.collectionId);
      expect(restored.name, req.name);
      expect(restored.method, req.method);
      expect(restored.url, req.url);
      expect(restored.headers, req.headers);
      expect(restored.bodyType, req.bodyType);
      expect(restored.body, req.body);
      expect(restored.queryParams, req.queryParams);
    });

    test('nullable fields', () {
      final req = RequestModel(
        id: 'req-1',
        name: 'Test',
        method: 'GET',
        url: 'https://example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(req.collectionId, isNull);
      expect(req.bodyType, isNull);
      expect(req.body, isNull);
    });
  });

  group('ResponseModel', () {
    test('serialization round-trip', () {
      final resp = ResponseModel(
        statusCode: 200,
        headers: {'content-type': 'application/json'},
        body: '{"ok": true}',
        timeMs: 150,
        sizeBytes: 42,
      );
      final json = resp.toJson();
      final restored = ResponseModel.fromJson(json);
      expect(restored.statusCode, 200);
      expect(restored.headers, {'content-type': 'application/json'});
      expect(restored.body, '{"ok": true}');
      expect(restored.timeMs, 150);
      expect(restored.sizeBytes, 42);
    });
  });

  group('Collection', () {
    test('serialization round-trip', () {
      final now = DateTime(2024);
      final coll = Collection(
        id: 'coll-1',
        name: 'My API',
        description: 'Test collection',
        sourceType: 'manual',
        sourceSpecId: 'spec-1',
        globalHeaders: {'X-Custom': 'value'},
        createdAt: now,
        updatedAt: now,
      );
      final json = coll.toJson();
      final restored = Collection.fromJson(json);
      expect(restored.id, coll.id);
      expect(restored.name, coll.name);
      expect(restored.description, coll.description);
      expect(restored.sourceType, coll.sourceType);
      expect(restored.sourceSpecId, coll.sourceSpecId);
      expect(restored.globalHeaders, coll.globalHeaders);
    });

    test('defaults are correct', () {
      final coll = Collection(
        id: '1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(coll.sourceType, 'manual');
      expect(coll.globalHeaders, isEmpty);
    });
  });

  group('HistoryEntry', () {
    test('serialization round-trip', () {
      final now = DateTime(2024);
      final entry = HistoryEntry(
        id: 'hist-1',
        requestId: 'req-1',
        method: 'POST',
        url: 'https://api.example.com/users',
        statusCode: 201,
        responseTimeMs: 200,
        responseSize: 1024,
        responseBody: '{"id": 1}',
        sentAt: now,
        requestName: 'Create User',
        collectionId: 'coll-1',
        headers: '{"Authorization": "Bearer token"}',
        collectionHeaders: '{"X-Tenant": "acme"}',
        body: '{"name": "test"}',
        bodyType: 'json',
        queryParams: '{"verbose": "true"}',
        authType: 'bearer',
        authData: '{"token": "abc123"}',
      );
      final json = entry.toJson();
      final restored = HistoryEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.requestId, entry.requestId);
      expect(restored.method, entry.method);
      expect(restored.url, entry.url);
      expect(restored.statusCode, entry.statusCode);
      expect(restored.responseTimeMs, entry.responseTimeMs);
      expect(restored.responseSize, entry.responseSize);
      expect(restored.responseBody, entry.responseBody);
      expect(restored.requestName, entry.requestName);
      expect(restored.collectionId, entry.collectionId);
      expect(restored.headers, entry.headers);
      expect(restored.collectionHeaders, entry.collectionHeaders);
      expect(restored.body, entry.body);
      expect(restored.bodyType, entry.bodyType);
      expect(restored.queryParams, entry.queryParams);
      expect(restored.authType, entry.authType);
      expect(restored.authData, entry.authData);
    });

    test('defaults are correct', () {
      final entry = HistoryEntry(
        id: '1',
        method: 'GET',
        url: 'https://example.com',
        sentAt: DateTime.now(),
      );
      expect(entry.requestId, isNull);
      expect(entry.statusCode, isNull);
      expect(entry.headers, '{}');
      expect(entry.collectionHeaders, '{}');
      expect(entry.queryParams, '{}');
      expect(entry.authType, 'none');
      expect(entry.authData, '{}');
    });
  });

  group('MockEndpoint', () {
    test('serialization round-trip', () {
      final endpoint = MockEndpoint(
        id: 'mock-1',
        method: 'GET',
        path: '/api/status',
        statusCode: 200,
        headers: {'Content-Type': 'application/json'},
        body: '{"status": "ok"}',
        delayMs: 100,
      );
      final json = endpoint.toJson();
      final restored = MockEndpoint.fromJson(json);
      expect(restored.id, endpoint.id);
      expect(restored.method, endpoint.method);
      expect(restored.path, endpoint.path);
      expect(restored.statusCode, endpoint.statusCode);
      expect(restored.headers, endpoint.headers);
      expect(restored.body, endpoint.body);
      expect(restored.delayMs, endpoint.delayMs);
    });

    test('defaults are correct', () {
      final endpoint = MockEndpoint(
        id: '1',
        method: 'GET',
        path: '/test',
      );
      expect(endpoint.statusCode, 200);
      expect(endpoint.headers, isEmpty);
      expect(endpoint.delayMs, 0);
    });
  });

  group('OpenApiEndpoint', () {
    test('serialization round-trip', () {
      final endpoint = OpenApiEndpoint(
        path: '/users/{id}',
        method: 'GET',
        summary: 'Get user by ID',
        description: 'Returns a single user',
        operationId: 'getUser',
        parameters: [
          OpenApiParameter(
            name: 'id',
            location: 'path',
            description: 'User ID',
            required: true,
            type: 'integer',
            schemaType: 'integer',
          ),
        ],
        requestBodySchema: OpenApiSchema(
          type: 'object',
          properties: {
            'name': OpenApiSchema(type: 'string'),
          },
          requiredFields: ['name'],
        ),
        responseSchemas: {
          '200': OpenApiSchema(
            type: 'object',
            properties: {
              'id': OpenApiSchema(type: 'integer'),
              'name': OpenApiSchema(type: 'string'),
            },
          ),
        },
        tags: ['users'],
      );
      final json = endpoint.toJson();
      final restored = OpenApiEndpoint.fromJson(json);
      expect(restored.path, '/users/{id}');
      expect(restored.method, 'GET');
      expect(restored.summary, 'Get user by ID');
      expect(restored.operationId, 'getUser');
      expect(restored.parameters, hasLength(1));
      expect(restored.parameters.first.name, 'id');
      expect(restored.parameters.first.location, 'path');
      expect(restored.parameters.first.required, isTrue);
      expect(restored.requestBodySchema?.type, 'object');
      expect(restored.responseSchemas, isNotNull);
      expect(restored.responseSchemas!['200']?.type, 'object');
      expect(restored.tags, ['users']);
    });
  });

  group('OpenApiSchema', () {
    test('serialization round-trip with nested properties', () {
      final schema = OpenApiSchema(
        type: 'object',
        properties: {
          'address': OpenApiSchema(
            type: 'object',
            properties: {
              'street': OpenApiSchema(type: 'string'),
              'city': OpenApiSchema(type: 'string'),
            },
            requiredFields: ['street'],
          ),
        },
        requiredFields: ['address'],
        enumValues: ['active', 'inactive'],
      );
      final json = schema.toJson();
      final restored = OpenApiSchema.fromJson(json);
      expect(restored.type, 'object');
      expect(restored.properties, contains('address'));
      expect(restored.properties['address']!.properties, contains('street'));
      expect(restored.properties['address']!.requiredFields, ['street']);
      expect(restored.requiredFields, ['address']);
      expect(restored.enumValues, ['active', 'inactive']);
    });

    test('array schema with items', () {
      final schema = OpenApiSchema(
        type: 'array',
        items: OpenApiSchema(type: 'string'),
      );
      final json = schema.toJson();
      final restored = OpenApiSchema.fromJson(json);
      expect(restored.type, 'array');
      expect(restored.items?.type, 'string');
    });

    test('schema with ref', () {
      final schema = OpenApiSchema(ref: '#/components/schemas/User');
      final json = schema.toJson();
      final restored = OpenApiSchema.fromJson(json);
      expect(restored.ref, '#/components/schemas/User');
    });
  });
}
