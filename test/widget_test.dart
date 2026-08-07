import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/shared/utils/method_colors.dart';
import 'package:dbug/shared/utils/body_type_helpers.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('methodColor edge cases', () {
    test('returns correct color for all standard methods', () {
      expect(methodColor('GET'), const Color(0xFF22C55E));
      expect(methodColor('POST'), const Color(0xFF3B82F6));
      expect(methodColor('PUT'), const Color(0xFFF59E0B));
      expect(methodColor('PATCH'), const Color(0xFFF97316));
      expect(methodColor('DELETE'), const Color(0xFFEF4444));
      expect(methodColor('HEAD'), const Color(0xFF8B5CF6));
      expect(methodColor('OPTIONS'), const Color(0xFF6B7280));
      expect(methodColor('TRACE'), const Color(0xFF6B7280));
    });

    test('case insensitivity', () {
      expect(methodColor('get'), methodColor('GET'));
      expect(methodColor('Post'), methodColor('POST'));
      expect(methodColor('delete'), methodColor('DELETE'));
    });

    test('unknown methods get gray', () {
      expect(methodColor('FOOBAR'), const Color(0xFF6B7280));
      expect(methodColor('CUSTOM'), const Color(0xFF6B7280));
    });
  });

  group('bodyTypeHelpers edge cases', () {
    test('all body type names', () {
      expect(bodyTypeNames, ['none', 'json', 'form', 'raw']);
    });

    test('stringToIndex and indexToString are inverses for valid types', () {
      for (final type in ['json', 'form', 'raw']) {
        final idx = bodyTypeStringToIndex(type);
        final str = bodyTypeIndexToString(idx);
        expect(str, type);
      }
    });

    test('invalid string maps to 0', () {
      expect(bodyTypeStringToIndex('xml'), 0);
      expect(bodyTypeStringToIndex('binary'), 0);
      expect(bodyTypeStringToIndex(''), 0);
    });

    test('invalid index maps to null', () {
      expect(bodyTypeIndexToString(-1), isNull);
      expect(bodyTypeIndexToString(0), isNull);
      expect(bodyTypeIndexToString(4), isNull);
      expect(bodyTypeIndexToString(100), isNull);
    });
  });
}
