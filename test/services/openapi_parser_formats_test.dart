import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/features/openapi/data/openapi_parser.dart';

void main() {
  group('Swagger 2.0', () {
    const spec = '''
{
  "swagger": "2.0",
  "info": {"title": "Pets", "version": "1.0"},
  "host": "petstore.example.com",
  "basePath": "/v2",
  "schemes": ["http", "https"],
  "paths": {
    "/pets/{pet-id}": {
      "parameters": [{"name": "pet-id", "in": "path", "required": true, "type": "string"}],
      "put": {
        "parameters": [
          {"name": "body", "in": "body", "schema": {"\$ref": "#/definitions/Pet"}},
          {"name": "dryRun", "in": "query", "type": "boolean", "default": false},
          {"name": "X-Trace", "in": "header", "type": "string"},
          {"name": "file", "in": "formData", "type": "file"}
        ],
        "responses": {"200": {"description": "ok", "schema": {"\$ref": "#/definitions/Pet"}}}
      }
    }
  },
  "definitions": {
    "Pet": {"type": "object", "properties": {"name": {"type": "string"}, "age": {"type": "integer"}}}
  }
}''';

    test('builds the base URL from schemes/host/basePath, preferring https', () {
      expect(OpenApiParser.parse(spec)!.baseUrl, 'https://petstore.example.com/v2');
    });

    test('maps the body parameter to the request body schema', () {
      final ep = OpenApiParser.parse(spec)!.endpoints.single;
      expect(ep.method, 'PUT');
      expect(ep.requestBodySchema!.properties.keys, ['name', 'age']);
      expect(ep.responseSchemas!['200']!.properties.keys, ['name', 'age']);
    });

    test('keeps path/query/header params, drops body and formData', () {
      final params = OpenApiParser.parse(spec)!.endpoints.single.parameters;
      expect(params.map((p) => '${p.location}:${p.name}'), ['path:pet-id', 'query:dryRun', 'header:X-Trace']);
      expect(params[1].type, 'boolean');
      expect(params[1].example, 'false');
    });

    test('base URL is just basePath when host is missing', () {
      final parsed = OpenApiParser.parse('{"swagger":"2.0","info":{},"basePath":"/api","paths":{}}');
      expect(parsed!.baseUrl, '/api');
    });
  });

  group('OpenAPI 3 servers', () {
    test('expands server variables with their defaults', () {
      final parsed = OpenApiParser.parse('''
{"openapi":"3.0.0","info":{},"paths":{},
 "servers":[{"url":"{scheme}://{host}/v1","variables":{
   "scheme":{"default":"https"},"host":{"default":"api.test"}}}]}''');
      expect(parsed!.baseUrl, 'https://api.test/v1');
    });

    test('keeps relative server URLs', () {
      final parsed = OpenApiParser.parse('{"openapi":"3.1.0","info":{},"paths":{},"servers":[{"url":"/api/v2"}]}');
      expect(parsed!.baseUrl, '/api/v2');
    });
  });

  group('parameters', () {
    test('captures examples/defaults and resolves \$ref parameters', () {
      final parsed = OpenApiParser.parse('''
{"openapi":"3.0.0","info":{},
 "components":{"parameters":{"Limit":{"name":"limit","in":"query","schema":{"type":"integer","default":20}}}},
 "paths":{"/items":{"get":{"parameters":[
   {"\$ref":"#/components/parameters/Limit"},
   {"name":"q","in":"query","example":"shoes","schema":{"type":"string"}}
 ],"responses":{}}}}}''');
      final params = parsed!.endpoints.single.parameters;
      expect(params.map((p) => p.name), ['limit', 'q']);
      expect(params[0].example, '20');
      expect(params[1].example, 'shoes');
    });

    test('resolves \$ref request bodies and vendor JSON content types', () {
      final parsed = OpenApiParser.parse('''
{"openapi":"3.0.0","info":{},
 "components":{"requestBodies":{"Item":{"content":{"application/vnd.api+json":{"schema":{"type":"object","properties":{"id":{"type":"string"}}}}}}}},
 "paths":{"/items":{"post":{"requestBody":{"\$ref":"#/components/requestBodies/Item"},"responses":{}}}}}''');
      expect(parsed!.endpoints.single.requestBodySchema!.properties.keys, ['id']);
    });
  });

  group('parseOrThrow', () {
    void expectReason(String content, Object reason) {
      expect(
        () => OpenApiParser.parseOrThrow(content),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', reason)),
      );
    }

    test('explains each failure', () {
      expectReason('', contains('empty'));
      expectReason('{not json', startsWith('Invalid JSON'));
      expectReason('a: [b', startsWith('Invalid YAML'));
      expectReason('{"info":{}}', 'Not an OpenAPI 3.x or Swagger 2.0 document');
      expectReason('- just\n- a list', 'Not an OpenAPI 3.x or Swagger 2.0 document');
      expectReason('{"swagger":"1.2"}', contains('Swagger 1.2'));
    });

    test('parse still returns null on failure', () {
      expect(OpenApiParser.parse('{"info":{}}'), isNull);
    });
  });
}
