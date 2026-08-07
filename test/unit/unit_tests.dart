import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/shared/utils/body_type_helpers.dart';
import 'package:dbug/shared/utils/method_colors.dart';
import 'package:dbug/core/providers/active_environment_provider.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('substituteVariables', () {
    test('replaces single variable', () {
      final result = substituteVariables(
        'https://api.example.com/users/{{id}}',
        {'id': '42'},
      );
      expect(result, 'https://api.example.com/users/42');
    });

    test('replaces multiple variables', () {
      final result = substituteVariables(
        'https://{{host}}/{{resource}}/{{id}}',
        {'host': 'api.example.com', 'resource': 'users', 'id': '42'},
      );
      expect(result, 'https://api.example.com/users/42');
    });

    test('leaves unmatched variables intact', () {
      final result = substituteVariables(
        'https://api.example.com/{{id}}/{{unknown}}',
        {'id': '42'},
      );
      expect(result, 'https://api.example.com/42/{{unknown}}');
    });

    test('returns original when no variables', () {
      final result = substituteVariables(
        'https://api.example.com/users',
        {},
      );
      expect(result, 'https://api.example.com/users');
    });

    test('handles empty input', () {
      final result = substituteVariables('', {'key': 'value'});
      expect(result, '');
    });

    test('does not replace single-brace braces', () {
      final result = substituteVariables(
        '{not_a_var} {{is_a_var}}',
        {'is_a_var': 'yes'},
      );
      expect(result, '{not_a_var} yes');
    });

    test('handles variables with underscores', () {
      final result = substituteVariables(
        '{{user_name}}',
        {'user_name': 'john'},
      );
      expect(result, 'john');
    });
  });

  group('bodyTypeStringToIndex', () {
    test('json -> 1', () => expect(bodyTypeStringToIndex('json'), 1));
    test('form -> 2', () => expect(bodyTypeStringToIndex('form'), 2));
    test('raw -> 3', () => expect(bodyTypeStringToIndex('raw'), 3));
    test('none -> 0', () => expect(bodyTypeStringToIndex('none'), 0));
    test('null -> 0', () => expect(bodyTypeStringToIndex(null), 0));
    test('unknown -> 0', () => expect(bodyTypeStringToIndex('xml'), 0));
  });

  group('bodyTypeIndexToString', () {
    test('0 -> null', () => expect(bodyTypeIndexToString(0), isNull));
    test('1 -> json', () => expect(bodyTypeIndexToString(1), 'json'));
    test('2 -> form', () => expect(bodyTypeIndexToString(2), 'form'));
    test('3 -> raw', () => expect(bodyTypeIndexToString(3), 'raw'));
    test('4 -> null', () => expect(bodyTypeIndexToString(4), isNull));
    test('-1 -> null', () => expect(bodyTypeIndexToString(-1), isNull));
  });

  group('bodyType round-trip', () {
    test('string -> index -> string is identity', () {
      for (final type in ['json', 'form', 'raw']) {
        final index = bodyTypeStringToIndex(type);
        final result = bodyTypeIndexToString(index);
        expect(result, type);
      }
    });

    test('null -> 0 -> null', () {
      final index = bodyTypeStringToIndex(null);
      final result = bodyTypeIndexToString(index);
      expect(result, isNull);
    });
  });

  group('methodColor', () {
    test('GET returns green', () {
      expect(methodColor('GET'), const Color(0xFF22C55E));
    });

    test('POST returns blue', () {
      expect(methodColor('POST'), const Color(0xFF3B82F6));
    });

    test('PUT returns amber', () {
      expect(methodColor('PUT'), const Color(0xFFF59E0B));
    });

    test('PATCH returns orange', () {
      expect(methodColor('PATCH'), const Color(0xFFF97316));
    });

    test('DELETE returns red', () {
      expect(methodColor('DELETE'), const Color(0xFFEF4444));
    });

    test('HEAD returns purple', () {
      expect(methodColor('HEAD'), const Color(0xFF8B5CF6));
    });

    test('OPTIONS returns gray', () {
      expect(methodColor('OPTIONS'), const Color(0xFF6B7280));
    });

    test('TRACE returns gray', () {
      expect(methodColor('TRACE'), const Color(0xFF6B7280));
    });

    test('lowercase get still returns green', () {
      expect(methodColor('get'), const Color(0xFF22C55E));
    });

    test('unknown method returns gray', () {
      expect(methodColor('CUSTOM'), const Color(0xFF6B7280));
    });
  });
}
