import 'package:dbug/core/repositories/openapi_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/models/openapi_spec.dart';
import 'package:dbug/features/openapi/data/schema_skeleton.dart';
import 'package:dbug/features/openapi/data/spec_paths.dart';

void main() {
  group('convertSpecPath', () {
    test('converts every path parameter, including hyphens and dots', () {
      expect(convertSpecPath('/users/{id}/posts/{post-id}/v/{a.b}'),
          '/users/{{id}}/posts/{{post-id}}/v/{{a.b}}');
    });

    test('leaves paths without parameters unchanged', () {
      expect(convertSpecPath('/health'), '/health');
    });

    test('specPathParams lists names in order', () {
      expect(specPathParams('/a/{x}/b/{user-id}'), ['x', 'user-id']);
    });

    test('specRequestUrl prefixes {{baseUrl}} only when the spec has one', () {
      expect(specRequestUrl('/u/{id}', hasBaseUrl: true), '{{baseUrl}}/u/{{id}}');
      expect(specRequestUrl('/u/{id}', hasBaseUrl: false), '/u/{{id}}');
    });
  });

  group('schemaSkeleton', () {
    test('primitives', () {
      expect(schemaSkeleton(const OpenApiSchema(type: 'string')), '');
      expect(schemaSkeleton(const OpenApiSchema(type: 'integer')), 0);
      expect(schemaSkeleton(const OpenApiSchema(type: 'number')), 0);
      expect(schemaSkeleton(const OpenApiSchema(type: 'boolean')), false);
      expect(schemaSkeleton(null), isNull);
    });

    test('enums use their first value with the right type', () {
      expect(schemaSkeleton(const OpenApiSchema(type: 'string', enumValues: ['b', 'a'])), 'b');
      expect(schemaSkeleton(const OpenApiSchema(type: 'integer', enumValues: ['3', '4'])), 3);
    });

    test('objects and arrays recurse', () {
      const schema = OpenApiSchema(type: 'object', properties: {
        'name': OpenApiSchema(type: 'string'),
        'tags': OpenApiSchema(type: 'array', items: OpenApiSchema(type: 'string')),
        'owner': OpenApiSchema(type: 'object', properties: {'id': OpenApiSchema(type: 'integer')}),
      });
      expect(schemaSkeleton(schema), {
        'name': '',
        'tags': [''],
        'owner': {'id': 0},
      });
    });

    test('infers object/array when type is missing', () {
      expect(schemaSkeleton(const OpenApiSchema(properties: {'a': OpenApiSchema(type: 'boolean')})), {'a': false});
      expect(schemaSkeleton(const OpenApiSchema(items: OpenApiSchema(type: 'integer'))), [0]);
    });

    test('stops at maxDepth', () {
      var schema = const OpenApiSchema(type: 'string');
      for (var i = 0; i < 10; i++) {
        schema = OpenApiSchema(type: 'object', properties: {'n': schema});
      }
      final result = schemaSkeleton(schema, maxDepth: 2);
      expect(result, {
        'n': {'n': <String, Object?>{}},
      });
    });
  });

  group('specEnvironmentName', () {
    test('does not repeat a trailing API', () {
      expect(specEnvironmentName('Billing Service API'), 'Billing Service API');
      expect(specEnvironmentName('Payments api'), 'Payments api');
    });
    test('appends API otherwise, and handles missing titles', () {
      expect(specEnvironmentName('ZIALE'), 'ZIALE API');
      expect(specEnvironmentName('Rapid'), 'Rapid API');
      expect(specEnvironmentName(null), 'Imported API');
      expect(specEnvironmentName('  '), 'Imported API');
    });
  });
}
