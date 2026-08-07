import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/shared/widgets/key_value_editor.dart';

void main() {
  group('entriesToMap', () {
    test('converts enabled entries to map', () {
      final entries = [
        KeyValueEntry(key: 'Content-Type', value: 'application/json', enabled: true),
        KeyValueEntry(key: 'Authorization', value: 'Bearer token', enabled: true),
      ];
      final map = entriesToMap(entries);
      expect(map, {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer token',
      });
    });

    test('excludes disabled entries', () {
      final entries = [
        KeyValueEntry(key: 'Enabled', value: 'yes', enabled: true),
        KeyValueEntry(key: 'Disabled', value: 'no', enabled: false),
      ];
      final map = entriesToMap(entries);
      expect(map, {'Enabled': 'yes'});
      expect(map.containsKey('Disabled'), isFalse);
    });

    test('excludes entries with empty key', () {
      final entries = [
        KeyValueEntry(key: 'Valid', value: 'value', enabled: true),
        KeyValueEntry(key: '', value: 'orphan', enabled: true),
      ];
      final map = entriesToMap(entries);
      expect(map, {'Valid': 'value'});
    });

    test('returns empty map for empty list', () {
      expect(entriesToMap([]), isEmpty);
    });

    test('returns empty map when all entries disabled', () {
      final entries = [
        KeyValueEntry(key: 'a', value: '1', enabled: false),
        KeyValueEntry(key: 'b', value: '2', enabled: false),
      ];
      expect(entriesToMap(entries), isEmpty);
    });
  });

  group('mapToEntries', () {
    test('converts map to entries', () {
      final entries = mapToEntries({'a': '1', 'b': '2'});
      expect(entries, hasLength(2));
      expect(entries[0].key, 'a');
      expect(entries[0].value, '1');
      expect(entries[1].key, 'b');
      expect(entries[1].value, '2');
    });

    test('returns empty list for empty map', () {
      expect(mapToEntries({}), isEmpty);
    });

    test('entries have enabled = true by default', () {
      final entries = mapToEntries({'key': 'value'});
      expect(entries.first.enabled, isTrue);
    });
  });

  group('entriesToMap -> mapToEntries round-trip', () {
    test('preserves data through conversion', () {
      final original = [
        KeyValueEntry(key: 'Host', value: 'localhost', enabled: true),
        KeyValueEntry(key: 'Port', value: '3000', enabled: true),
      ];
      final map = entriesToMap(original);
      final restored = mapToEntries(map);

      expect(restored.length, 2);
      expect(restored[0].key, 'Host');
      expect(restored[0].value, 'localhost');
      expect(restored[1].key, 'Port');
      expect(restored[1].value, '3000');
    });
  });

  group('KeyValueEntry', () {
    test('isValid returns true when key is non-empty', () {
      final entry = KeyValueEntry(key: 'name', value: 'value');
      expect(entry.isValid, isTrue);
    });

    test('isValid returns false when key is empty', () {
      final entry = KeyValueEntry(key: '', value: 'value');
      expect(entry.isValid, isFalse);
    });

    test('key getter returns controller text', () {
      final entry = KeyValueEntry(key: 'myKey');
      expect(entry.key, 'myKey');
    });

    test('value getter returns controller text', () {
      final entry = KeyValueEntry(key: 'k', value: 'myValue');
      expect(entry.value, 'myValue');
    });

    test('dispose does not throw', () {
      final entry = KeyValueEntry(key: 'k', value: 'v');
      expect(() => entry.dispose(), returnsNormally);
    });
  });
}
