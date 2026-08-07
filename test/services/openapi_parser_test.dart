import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/features/openapi/data/openapi_parser.dart';

void main() {
  group('OpenApiParser.parse', () {
    group('JSON input', () {
      test('parses a minimal valid OpenAPI 3.0 spec', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "Test API", "version": "1.0.0" },
  "paths": {}
}
''');
        expect(spec, isNotNull);
        expect(spec!.title, 'Test API');
        expect(spec.version, '1.0.0');
        expect(spec.endpoints, isEmpty);
        expect(spec.baseUrl, isNull);
      });

      test('parses spec with servers (baseUrl)', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" },
  "servers": [{ "url": "https://api.example.com/v1" }],
  "paths": {}
}
''');
        expect(spec?.baseUrl, 'https://api.example.com/v1');
      });

      test('parses endpoints with GET method', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" },
  "paths": {
    "/users": {
      "get": {
        "summary": "List users",
        "description": "Returns all users",
        "operationId": "listUsers",
        "tags": ["users"],
        "parameters": [
          {
            "name": "limit",
            "in": "query",
            "description": "Max items",
            "required": false,
            "schema": { "type": "integer" }
          }
        ],
        "responses": {
          "200": {
            "description": "Success",
            "content": {
              "application/json": {
                "schema": {
                  "type": "array",
                  "items": { "type": "object" }
                }
              }
            }
          }
        }
      }
    }
  }
}
''');
        expect(spec, isNotNull);
        expect(spec!.endpoints, hasLength(1));
        final ep = spec.endpoints.first;
        expect(ep.path, '/users');
        expect(ep.method, 'GET');
        expect(ep.summary, 'List users');
        expect(ep.description, 'Returns all users');
        expect(ep.operationId, 'listUsers');
        expect(ep.tags, ['users']);
        expect(ep.parameters, hasLength(1));
        expect(ep.parameters.first.name, 'limit');
        expect(ep.parameters.first.location, 'query');
        expect(ep.parameters.first.required, isFalse);
        expect(ep.parameters.first.type, 'integer');
        expect(ep.responseSchemas, isNotNull);
        expect(ep.responseSchemas!['200']?.type, 'array');
      });

      test('parses POST endpoint with request body', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" },
  "paths": {
    "/users": {
      "post": {
        "summary": "Create user",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "name": { "type": "string" },
                  "email": { "type": "string", "format": "email" }
                },
                "required": ["name", "email"]
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Created"
          }
        }
      }
    }
  }
}
''');
        expect(spec!.endpoints, hasLength(1));
        final ep = spec.endpoints.first;
        expect(ep.method, 'POST');
        expect(ep.requestBodySchema, isNotNull);
        expect(ep.requestBodySchema!.type, 'object');
        expect(ep.requestBodySchema!.properties, contains('name'));
        expect(ep.requestBodySchema!.properties['name']!.type, 'string');
        expect(ep.requestBodySchema!.requiredFields, ['name', 'email']);
      });

      test('parses multiple methods on same path', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" },
  "paths": {
    "/users": {
      "get": { "summary": "List" },
      "post": { "summary": "Create" },
      "delete": { "summary": "Delete all" }
    }
  }
}
''');
        expect(spec!.endpoints, hasLength(3));
        expect(spec.endpoints.map((e) => e.method).toList(), containsAll(['GET', 'POST', 'DELETE']));
      });

      test('resolves \$ref in schema', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" },
  "components": {
    "schemas": {
      "User": {
        "type": "object",
        "properties": {
          "id": { "type": "integer" },
          "name": { "type": "string" }
        },
        "required": ["id", "name"]
      }
    }
  },
  "paths": {
    "/users": {
      "get": {
        "responses": {
          "200": {
            "content": {
              "application/json": {
                "schema": { "\$ref": "#/components/schemas/User" }
              }
            }
          }
        }
      }
    }
  }
}
''');
        expect(spec!.endpoints.first.responseSchemas, isNotNull);
        final schema = spec.endpoints.first.responseSchemas!['200']!;
        expect(schema.type, 'object');
        expect(schema.properties, contains('id'));
        expect(schema.properties['id']!.type, 'integer');
        expect(schema.requiredFields, containsAll(['id', 'name']));
      });

      test('parses path parameters', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" },
  "paths": {
    "/users/{id}": {
      "get": {
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": { "type": "string" }
          }
        ]
      }
    }
  }
}
''');
        expect(spec!.endpoints.first.parameters, hasLength(1));
        expect(spec.endpoints.first.parameters.first.name, 'id');
        expect(spec.endpoints.first.parameters.first.location, 'path');
        expect(spec.endpoints.first.parameters.first.required, isTrue);
      });

      test('returns null for non-OpenAPI JSON', () {
        final spec = OpenApiParser.parse('{"hello": "world"}');
        expect(spec, isNull);
      });

      test('returns null for invalid JSON', () {
        final spec = OpenApiParser.parse('not json at all');
        expect(spec, isNull);
      });

      test('returns null for OpenAPI 2.x (swagger)', () {
        final spec = OpenApiParser.parse('''
{
  "swagger": "2.0",
  "info": { "title": "API" }
}
''');
        expect(spec, isNull);
      });
    });

    group('YAML input', () {
      test('parses YAML OpenAPI spec', () {
        final spec = OpenApiParser.parse('''
openapi: "3.0.0"
info:
  title: YAML API
  version: "1.0"
paths:
  /items:
    get:
      summary: List items
''');
        expect(spec, isNotNull);
        expect(spec!.title, 'YAML API');
        expect(spec.version, '1.0');
        expect(spec.endpoints, hasLength(1));
        expect(spec.endpoints.first.path, '/items');
        expect(spec.endpoints.first.method, 'GET');
        expect(spec.endpoints.first.summary, 'List items');
      });

      test('returns null for invalid YAML', () {
        final spec = OpenApiParser.parse('this: is: broken: yaml: [');
        expect(spec, isNull);
      });
    });

    group('edge cases', () {
      test('handles empty paths object', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" },
  "paths": {}
}
''');
        expect(spec!.endpoints, isEmpty);
      });

      test('handles missing info object', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "paths": {}
}
''');
        expect(spec, isNotNull);
        expect(spec!.title, isNull);
      });

      test('handles missing paths', () {
        final spec = OpenApiParser.parse('''
{
  "openapi": "3.0.0",
  "info": { "title": "API" }
}
''');
        expect(spec!.endpoints, isEmpty);
      });

      test('rawContent is preserved', () {
        const raw = '{"openapi": "3.0.0", "info": {"title": "X"}, "paths": {}}';
        final spec = OpenApiParser.parse(raw);
        expect(spec!.rawContent, raw);
      });
    });
  });
}
