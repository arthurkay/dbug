import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dbug/core/database/database_service.dart';

Future<Database> setupTestDatabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactoryFfi.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collections (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            source_type TEXT DEFAULT 'manual',
            source_spec_id TEXT,
            global_headers TEXT DEFAULT '{}',
            auth_type TEXT DEFAULT 'none',
            auth_data TEXT DEFAULT '{}',
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
            source_type TEXT DEFAULT 'user',
            source_spec_id TEXT
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
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );

  await DatabaseService.setTestDatabase(db);
  return db;
}

Future<void> tearDownTestDatabase() async {
  await DatabaseService.resetState();
}
