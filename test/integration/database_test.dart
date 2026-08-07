import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      ':memory:',
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE collections (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              source_type TEXT DEFAULT 'manual',
              source_spec_id TEXT,
              global_headers TEXT DEFAULT '{}',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE requests (
              id TEXT PRIMARY KEY,
              collection_id TEXT,
              name TEXT NOT NULL,
              method TEXT NOT NULL,
              url TEXT NOT NULL,
              headers TEXT DEFAULT '{}',
              body_type TEXT,
              body TEXT,
              query_params TEXT DEFAULT '{}',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
            )
          ''');
          await db.execute('''
            CREATE TABLE openapi_specs (
              id TEXT PRIMARY KEY,
              title TEXT,
              version TEXT,
              base_url TEXT,
              raw_content TEXT NOT NULL,
              parsed_endpoints TEXT DEFAULT '[]',
              source_type TEXT NOT NULL,
              source_url TEXT,
              imported_at INTEGER NOT NULL,
              updated_at INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE environments (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              variables TEXT DEFAULT '{}',
              is_active INTEGER DEFAULT 0,
              source_type TEXT DEFAULT 'user'
            )
          ''');
          await db.execute('''
            CREATE TABLE history (
              id TEXT PRIMARY KEY,
              request_id TEXT,
              method TEXT NOT NULL,
              url TEXT NOT NULL,
              status_code INTEGER,
              response_time_ms INTEGER,
              response_size INTEGER,
              response_body TEXT,
              sent_at INTEGER NOT NULL,
              request_name TEXT,
              collection_id TEXT,
              headers TEXT DEFAULT '{}',
              collection_headers TEXT DEFAULT '{}',
              body TEXT,
              body_type TEXT,
              query_params TEXT DEFAULT '{}',
              auth_type TEXT DEFAULT 'none',
              auth_data TEXT DEFAULT '{}'
            )
          ''');
          await db.execute('''
            CREATE TABLE mock_endpoints (
              id TEXT PRIMARY KEY,
              method TEXT NOT NULL,
              path TEXT NOT NULL,
              status_code INTEGER DEFAULT 200,
              headers TEXT DEFAULT '{}',
              body TEXT,
              delay_ms INTEGER DEFAULT 0
            )
          ''');
          await db.execute('CREATE INDEX idx_history_sent_at ON history(sent_at DESC)');
          await db.execute('CREATE INDEX idx_requests_collection ON requests(collection_id)');
        },
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Database Schema', () {
    test('all 6 tables exist', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final names = tables.map((t) => t['name'] as String).toSet();
      expect(names, containsAll([
        'collections', 'requests', 'openapi_specs',
        'environments', 'history', 'mock_endpoints',
      ]));
    });

    test('history has all v4 columns', () async {
      final columns = await db.rawQuery('PRAGMA table_info(history)');
      final names = columns.map((c) => c['name'] as String).toSet();
      expect(names, containsAll([
        'request_name', 'collection_id', 'headers',
        'collection_headers', 'body', 'body_type',
        'query_params', 'auth_type', 'auth_data',
      ]));
    });

    test('foreign key cascade on requests', () async {
      final fkInfo = await db.rawQuery('PRAGMA foreign_key_list(requests)');
      expect(fkInfo, isNotEmpty);
      final ondelete = fkInfo.first['on_delete'] as String;
      expect(ondelete, 'CASCADE');
    });
  });

  group('Collections CRUD', () {
    test('create and read', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = 'coll-1';
      await db.insert('collections', {
        'id': id,
        'name': 'Test API',
        'description': 'A test collection',
        'global_headers': '{"X-Key": "val"}',
        'created_at': now,
        'updated_at': now,
      });
      final rows = await db.query('collections', where: 'id = ?', whereArgs: [id]);
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Test API');
      expect(rows.first['global_headers'], '{"X-Key": "val"}');
    });

    test('cascade delete requests on collection delete', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('collections', {
        'id': 'c1', 'name': 'C', 'created_at': now, 'updated_at': now,
      });
      await db.insert('requests', {
        'id': 'r1', 'collection_id': 'c1', 'name': 'R',
        'method': 'GET', 'url': 'http://x', 'created_at': now, 'updated_at': now,
      });
      await db.delete('collections', where: 'id = ?', whereArgs: ['c1']);
      final reqs = await db.query('requests', where: 'collection_id = ?', whereArgs: ['c1']);
      expect(reqs, isEmpty);
    });

    test('update collection', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('collections', {
        'id': 'c1', 'name': 'Old', 'created_at': now, 'updated_at': now,
      });
      await db.update('collections', {'name': 'New'}, where: 'id = ?', whereArgs: ['c1']);
      final row = await db.query('collections', where: 'id = ?', whereArgs: ['c1']);
      expect(row.first['name'], 'New');
    });
  });

  group('Environments CRUD', () {
    test('create with variables', () async {
      await db.insert('environments', {
        'id': 'e1',
        'name': 'dev',
        'variables': '{"host": "localhost", "port": "3000"}',
        'is_active': 0,
        'source_type': 'user',
      });
      final row = await db.query('environments', where: 'id = ?', whereArgs: ['e1']);
      expect(row.first['name'], 'dev');
      expect(row.first['variables'], '{"host": "localhost", "port": "3000"}');
    });

    test('set active clears other active', () async {
      await db.insert('environments', {'id': 'e1', 'name': 'A', 'is_active': 1, 'source_type': 'user'});
      await db.insert('environments', {'id': 'e2', 'name': 'B', 'is_active': 0, 'source_type': 'user'});
      await db.update('environments', {'is_active': 0});
      await db.update('environments', {'is_active': 1}, where: 'id = ?', whereArgs: ['e2']);
      final actives = await db.query('environments', where: 'is_active = 1');
      expect(actives, hasLength(1));
      expect(actives.first['id'], 'e2');
    });

    test('delete by source_type', () async {
      await db.insert('environments', {'id': 'e1', 'name': 'User', 'source_type': 'user'});
      await db.insert('environments', {'id': 'e2', 'name': 'API', 'source_type': 'openapi'});
      await db.delete('environments', where: 'source_type = ?', whereArgs: ['openapi']);
      final remaining = await db.query('environments');
      expect(remaining, hasLength(1));
      expect(remaining.first['source_type'], 'user');
    });
  });

  group('History CRUD', () {
    test('create with all v4 fields', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('history', {
        'id': 'h1',
        'method': 'POST',
        'url': 'https://api.test.com/users',
        'status_code': 201,
        'response_time_ms': 150,
        'response_size': 256,
        'response_body': '{"id": 1}',
        'sent_at': now,
        'request_name': 'Create User',
        'collection_id': 'c1',
        'headers': '{"Auth": "Bearer tok"}',
        'collection_headers': '{"Tenant": "acme"}',
        'body': '{"name": "test"}',
        'body_type': 'json',
        'query_params': '{"verbose": "true"}',
        'auth_type': 'bearer',
        'auth_data': '{"token": "abc123"}',
      });
      final row = await db.query('history', where: 'id = ?', whereArgs: ['h1']);
      expect(row, hasLength(1));
      expect(row.first['request_name'], 'Create User');
      expect(row.first['auth_type'], 'bearer');
      expect(row.first['auth_data'], '{"token": "abc123"}');
    });

    test('history ordered by sent_at DESC', () async {
      await db.insert('history', {'id': 'h1', 'method': 'GET', 'url': 'a', 'sent_at': 100});
      await db.insert('history', {'id': 'h2', 'method': 'GET', 'url': 'b', 'sent_at': 200});
      await db.insert('history', {'id': 'h3', 'method': 'GET', 'url': 'c', 'sent_at': 150});
      final rows = await db.query('history', orderBy: 'sent_at DESC');
      expect(rows.map((r) => r['id']).toList(), ['h2', 'h3', 'h1']);
    });

    test('clear all history', () async {
      await db.insert('history', {'id': 'h1', 'method': 'GET', 'url': 'a', 'sent_at': 1});
      await db.insert('history', {'id': 'h2', 'method': 'GET', 'url': 'b', 'sent_at': 2});
      await db.delete('history');
      final rows = await db.query('history');
      expect(rows, isEmpty);
    });
  });

  group('Mock Endpoints', () {
    test('create and match', () async {
      await db.insert('mock_endpoints', {
        'id': 'm1',
        'method': 'GET',
        'path': '/api/status',
        'status_code': 200,
        'headers': '{"Content-Type": "application/json"}',
        'body': '{"status": "ok"}',
        'delay_ms': 50,
      });
      final match = await db.query(
        'mock_endpoints',
        where: 'method = ? AND path = ?',
        whereArgs: ['GET', '/api/status'],
      );
      expect(match, hasLength(1));
      expect(match.first['body'], '{"status": "ok"}');
    });
  });

  group('Requests CRUD', () {
    test('cascade delete on collection delete', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('collections', {
        'id': 'c1', 'name': 'C', 'created_at': now, 'updated_at': now,
      });
      await db.insert('requests', {
        'id': 'r1', 'collection_id': 'c1', 'name': 'R',
        'method': 'GET', 'url': 'http://x', 'created_at': now, 'updated_at': now,
      });
      await db.delete('collections', where: 'id = ?', whereArgs: ['c1']);
      final reqs = await db.query('requests');
      expect(reqs, isEmpty);
    });

    test('count by collection', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('collections', {
        'id': 'c1', 'name': 'C', 'created_at': now, 'updated_at': now,
      });
      await db.insert('requests', {
        'id': 'r1', 'collection_id': 'c1', 'name': 'A',
        'method': 'GET', 'url': 'http://x', 'created_at': now, 'updated_at': now,
      });
      await db.insert('requests', {
        'id': 'r2', 'collection_id': 'c1', 'name': 'B',
        'method': 'POST', 'url': 'http://y', 'created_at': now, 'updated_at': now,
      });
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM requests WHERE collection_id = ?',
        ['c1'],
      );
      expect(result.first['cnt'], 2);
    });
  });
}
