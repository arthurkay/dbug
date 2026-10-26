import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/providers/active_environment_provider.dart';

void main() {
  const vars = {
    'baseUrl': 'https://api.test',
    'api-key': 'k-1',
    'auth.token': 't-1',
    'empty': '',
  };

  test('replaces simple variables', () {
    expect(substituteVariables('{{baseUrl}}/users', vars), 'https://api.test/users');
  });

  test('allows spaces inside the braces', () {
    expect(substituteVariables('{{ baseUrl }}/x', vars), 'https://api.test/x');
    expect(substituteVariables('{{baseUrl  }}', vars), 'https://api.test');
  });

  test('supports hyphens and dots in names', () {
    expect(substituteVariables('key={{api-key}}&t={{auth.token}}', vars), 'key=k-1&t=t-1');
  });

  test('leaves unknown variables untouched', () {
    expect(substituteVariables('{{missing}}/{{ also-missing }}', vars), '{{missing}}/{{ also-missing }}');
  });

  test('substitutes empty values', () {
    expect(substituteVariables('a{{empty}}b', vars), 'ab');
  });

  test('ignores single braces and invalid names', () {
    expect(substituteVariables('{baseUrl} {{base url}}', vars), '{baseUrl} {{base url}}');
  });
}
