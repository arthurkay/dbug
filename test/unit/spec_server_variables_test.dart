import 'dart:convert';

import 'package:dbug/core/database/database_service.dart';
import 'package:dbug/core/providers/active_environment_provider.dart';
import 'package:dbug/core/repositories/environment_repository.dart';
import 'package:dbug/core/repositories/openapi_repository.dart';
import 'package:dbug/core/security/secret_cipher.dart';
import 'package:dbug/features/openapi/data/openapi_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

const _spec = '''
{
  "openapi": "3.0.0",
  "info": {"title": "Pay", "version": "1"},
  "servers": [{
    "url": "https://{url}:{port}/api/{version}",
    "variables": {"port": {"default": "443"}, "version": {"default": "v2.0"}}
  }],
  "paths": {"/payments/{id}": {"get": {"responses": {"200": {"description": "ok"}}}}}
}
''';

void main() {
  group('substituteVariables nesting', () {
    test('expands variables inside variable values', () {
      const vars = {'baseUrl': 'https://{{host}}:{{port}}', 'host': 'staging.test', 'port': '8443'};
      expect(substituteVariables('{{baseUrl}}/x', vars), 'https://staging.test:8443/x');
    });

    test('self-reference terminates and leaves the placeholder', () {
      expect(substituteVariables('{{a}}', const {'a': '{{a}}'}), '{{a}}');
    });

    test('placeholderNames lists remaining names once', () {
      expect(placeholderNames('{{a}}/{{ b }}/{{a}}'), ['a', 'b']);
    });
  });

  group('case-insensitive names', () {
    test('{{baseUrl}} finds baseurl; exact match wins', () {
      expect(substituteVariables('{{baseUrl}}/x', const {'baseurl': 'https://a'}), 'https://a/x');
      expect(substituteVariables('{{baseUrl}}', const {'baseurl': 'a', 'baseUrl': 'b'}), 'b');
    });

    test('active baseurl overrides the spec baseUrl', () {
      final merged = layerVariables({'baseurl': 'https://staging'}, {'baseUrl': 'https://{{url}}'});
      expect(substituteVariables('{{baseUrl}}/p', merged), 'https://staging/p');
    });
  });

  group('layerVariables', () {
    test('active environment wins; blank fallback values are skipped', () {
      final merged = layerVariables(
        {'url': 'staging.test', 'port': '8443'},
        {'baseUrl': 'https://{{url}}:{{port}}', 'url': 'localhost', 'port': '', 'id': ''},
      );
      expect(merged, {'baseUrl': 'https://{{url}}:{{port}}', 'url': 'staging.test', 'port': '8443'});
      expect(substituteVariables('{{baseUrl}}/p/{{id}}', merged), 'https://staging.test:8443/p/{{id}}');
    });

    test('active values override a spec baseUrl entirely', () {
      final merged = layerVariables({'baseUrl': 'https://prod.test'}, {'baseUrl': 'https://{{url}}'});
      expect(substituteVariables('{{baseUrl}}/x', merged), 'https://prod.test/x');
    });
  });

  group('server variables', () {
    test('parser keeps them as placeholders with defaults', () {
      final parsed = OpenApiParser.parse(_spec)!;
      expect(parsed.baseUrl, 'https://{url}:443/api/v2.0');
      expect(parsed.baseUrlTemplate, 'https://{{url}}:{{port}}/api/{{version}}');
      expect(parsed.serverVariables, {'url': '', 'port': '443', 'version': 'v2.0'});
    });

    group('with database', () {
      setUp(() async => setupTestDatabase());
      tearDown(() async => tearDownTestDatabase());

      test('import puts the template and defaults in the spec environment', () async {
        await OpenApiRepository().saveParsedSpec(OpenApiParser.parse(_spec)!);
        final env = (await EnvironmentRepository().getAllEnvironments()).single;
        expect(env.variables, {
          'baseUrl': 'https://{{url}}:{{port}}/api/{{version}}',
          'url': '',
          'port': '443',
          'version': 'v2.0',
          'id': '',
        });
      });

      test('upgrade rewrites legacy single-brace baseUrl once', () async {
        final db = await DatabaseService.database;
        await db.insert('environments', {
          'id': 'e1',
          'name': 'Pay API',
          'variables': Secrets.cipher.seal(jsonEncode({'baseUrl': 'https://{url}:{port}/api', 'port': '1'})),
          'is_active': 0,
          'source_type': 'openapi',
        });
        expect(await DatabaseService.upgradeSpecServerVariables(db), 1);
        final env = (await EnvironmentRepository().getAllEnvironments()).single;
        expect(env.variables, {'baseUrl': 'https://{{url}}:{{port}}/api', 'port': '1', 'url': ''});
        expect(await DatabaseService.upgradeSpecServerVariables(db), 0);
      });
    });
  });
}
