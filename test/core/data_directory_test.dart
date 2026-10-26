import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/database/database_service.dart';

void main() {
  group('DatabaseService.linuxDataDirectory', () {
    test('uses ~/.local/share/<app id>, never the install dir', () {
      final dir = DatabaseService.linuxDataDirectory({'HOME': '/home/u'});
      expect(dir, '/home/u/.local/share/zm.co.cloud.dbug');
      expect(dir, isNot('/home/u/.local/share/dbug'));
    });

    test('honours an absolute XDG_DATA_HOME', () {
      expect(
        DatabaseService.linuxDataDirectory({'HOME': '/home/u', 'XDG_DATA_HOME': '/data'}),
        '/data/zm.co.cloud.dbug',
      );
    });

    test('ignores an empty or relative XDG_DATA_HOME', () {
      expect(
        DatabaseService.linuxDataDirectory({'HOME': '/home/u', 'XDG_DATA_HOME': ''}),
        '/home/u/.local/share/zm.co.cloud.dbug',
      );
      expect(
        DatabaseService.linuxDataDirectory({'HOME': '/home/u', 'XDG_DATA_HOME': 'rel'}),
        '/home/u/.local/share/zm.co.cloud.dbug',
      );
    });
  });
}
