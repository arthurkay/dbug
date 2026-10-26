import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dbug/core/constants/app_constants.dart';
import 'package:dbug/core/database/database_service.dart';

/// The v1 schema, as originally shipped. Later versions are built from it by
/// applying [_deltas] — this intentionally restates the migration history so
/// the test catches any drift between `_onUpgrade` and `createSchema`.
const _v1 = [
  '''CREATE TABLE collections (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT,
    source_type TEXT DEFAULT 'manual', source_spec_id TEXT,
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''',
  '''CREATE TABLE requests (
    id TEXT PRIMARY KEY, collection_id TEXT, name TEXT NOT NULL,
    method TEXT NOT NULL, url TEXT NOT NULL, headers TEXT DEFAULT '{}',
    body_type TEXT, body TEXT, query_params TEXT DEFAULT '{}',
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
    FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE)''',
  '''CREATE TABLE openapi_specs (
    id TEXT PRIMARY KEY, title TEXT, version TEXT, base_url TEXT,
    raw_content TEXT NOT NULL, parsed_endpoints TEXT DEFAULT '[]',
    source_type TEXT NOT NULL, source_url TEXT, imported_at INTEGER NOT NULL,
    updated_at INTEGER)''',
  '''CREATE TABLE environments (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, variables TEXT DEFAULT '{}',
    is_active INTEGER DEFAULT 0)''',
  '''CREATE TABLE history (
    id TEXT PRIMARY KEY, request_id TEXT, method TEXT NOT NULL,
    url TEXT NOT NULL, status_code INTEGER, response_time_ms INTEGER,
    response_size INTEGER, response_body TEXT, sent_at INTEGER NOT NULL)''',
  '''CREATE TABLE mock_endpoints (
    id TEXT PRIMARY KEY, method TEXT NOT NULL, path TEXT NOT NULL,
    status_code INTEGER DEFAULT 200, headers TEXT DEFAULT '{}', body TEXT,
    delay_ms INTEGER DEFAULT 0)''',
  'CREATE INDEX idx_history_sent_at ON history(sent_at DESC)',
  'CREATE INDEX idx_requests_collection ON requests(collection_id)',
];

/// Schema changes introduced by each version (the state *at* that version).
const _deltas = <int, List<String>>{
  2: ["ALTER TABLE collections ADD COLUMN global_headers TEXT DEFAULT '{}'"],
  3: ["ALTER TABLE environments ADD COLUMN source_type TEXT DEFAULT 'user'"],
  4: [
    'ALTER TABLE history ADD COLUMN request_name TEXT',
    'ALTER TABLE history ADD COLUMN collection_id TEXT',
    "ALTER TABLE history ADD COLUMN headers TEXT DEFAULT '{}'",
    "ALTER TABLE history ADD COLUMN collection_headers TEXT DEFAULT '{}'",
    'ALTER TABLE history ADD COLUMN body TEXT',
    'ALTER TABLE history ADD COLUMN body_type TEXT',
    "ALTER TABLE history ADD COLUMN query_params TEXT DEFAULT '{}'",
    "ALTER TABLE history ADD COLUMN auth_type TEXT DEFAULT 'none'",
    "ALTER TABLE history ADD COLUMN auth_data TEXT DEFAULT '{}'",
  ],
  5: [
    "ALTER TABLE collections ADD COLUMN auth_type TEXT DEFAULT 'none'",
    "ALTER TABLE collections ADD COLUMN auth_data TEXT DEFAULT '{}'",
  ],
  6: ['ALTER TABLE environments ADD COLUMN source_spec_id TEXT'],
  7: [
    "ALTER TABLE requests ADD COLUMN auth_type TEXT DEFAULT 'none'",
    "ALTER TABLE requests ADD COLUMN auth_data TEXT DEFAULT '{}'",
    'ALTER TABLE history ADD COLUMN resolved_url TEXT',
    "ALTER TABLE history ADD COLUMN response_headers TEXT DEFAULT '{}'",
    'ALTER TABLE history ADD COLUMN response_truncated INTEGER DEFAULT 0',
    'CREATE UNIQUE INDEX idx_mock_method_path ON mock_endpoints(method, path)',
  ],
  8: ['CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)'],
};

const _tables = ['collections', 'requests', 'openapi_specs', 'environments', 'history', 'mock_endpoints', 'app_meta'];

Future<Database> _openBlank() async {
  return databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false));
}

Future<Database> _schemaAtVersion(int version) async {
  final db = await _openBlank();
  for (final sql in _v1) {
    await db.execute(sql);
  }
  for (var v = 2; v <= version; v++) {
    for (final sql in _deltas[v] ?? const <String>[]) {
      await db.execute(sql);
    }
  }
  return db;
}

/// Column definitions keyed by name (order-independent: ALTER TABLE appends,
/// createSchema declares columns in logical order).
Future<Map<String, String>> _columns(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return {
    for (final r in rows)
      r['name'] as String: '${r['type']}|notnull=${r['notnull']}|default=${r['dflt_value']}|pk=${r['pk']}',
  };
}

Future<Set<String>> _indexes(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'index' AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((r) => r['name'] as String).toSet();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late Map<String, Map<String, String>> fresh;
  late Set<String> freshIndexes;

  setUpAll(() async {
    final db = await _openBlank();
    await DatabaseService.createSchema(db);
    fresh = {for (final t in _tables) t: await _columns(db, t)};
    freshIndexes = await _indexes(db);
    await db.close();
  });

  test('current dbVersion has a migration path covered by this test', () {
    expect(AppConstants.dbVersion, 8);
  });

  for (var version = 1; version < AppConstants.dbVersion; version++) {
    test('upgrading from v$version matches a fresh schema and keeps data', () async {
      final db = await _schemaAtVersion(version);

      final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      await db.insert('collections', {'id': 'c1', 'name': 'C', 'created_at': now, 'updated_at': now});
      await db.insert('requests', {
        'id': 'r1', 'collection_id': 'c1', 'name': 'R', 'method': 'GET',
        'url': 'https://x', 'created_at': now, 'updated_at': now,
      });
      await db.insert('environments', {'id': 'e1', 'name': 'Env'});
      await db.insert('history', {
        'id': 'h1', 'method': 'GET', 'url': 'https://api/x?id=1', 'sent_at': now,
      });
      // Duplicates were allowed before v7.
      await db.insert('mock_endpoints', {'id': 'm1', 'method': 'GET', 'path': '/a'});
      if (version < 7) {
        await db.insert('mock_endpoints', {'id': 'm2', 'method': 'GET', 'path': '/a'});
      }
      await db.insert('mock_endpoints', {'id': 'm3', 'method': 'POST', 'path': '/a'});

      await DatabaseService.upgradeSchema(db, version, AppConstants.dbVersion);

      for (final t in _tables) {
        expect(await _columns(db, t), fresh[t], reason: 'table $t after upgrade from v$version');
      }
      expect(await _indexes(db), freshIndexes);

      // Data survived and new columns took their defaults.
      final request = (await db.query('requests')).single;
      expect(request['auth_type'], 'none');
      expect(request['auth_data'], '{}');
      final history = (await db.query('history')).single;
      expect(history['url'], 'https://api/x?id=1');
      // Pre-v7 rows stored the resolved URL in `url`; the v7 upgrade copies it.
      if (version < 7) expect(history['resolved_url'], 'https://api/x?id=1');
      expect(history['response_headers'], '{}');
      expect(history['response_truncated'], 0);

      // Oldest duplicate kept; the unique index now rejects new duplicates.
      final mocks = await db.query('mock_endpoints', orderBy: 'id');
      expect(mocks.map((m) => m['id']), ['m1', 'm3']);
      await expectLater(
        db.insert('mock_endpoints', {'id': 'm4', 'method': 'GET', 'path': '/a'}),
        throwsA(isA<DatabaseException>()),
      );

      await db.close();
    });
  }
}
