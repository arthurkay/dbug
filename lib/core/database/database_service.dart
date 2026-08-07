import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  static Database? _database;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialized = true;
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, AppConstants.dbName);

      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize database: $e');
      rethrow;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
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

    await db.execute(
      'CREATE INDEX idx_history_sent_at ON history(sent_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_requests_collection ON requests(collection_id)',
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE collections ADD COLUMN global_headers TEXT DEFAULT '{}'");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE environments ADD COLUMN source_type TEXT DEFAULT 'user'");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE history ADD COLUMN request_name TEXT");
      await db.execute("ALTER TABLE history ADD COLUMN collection_id TEXT");
      await db.execute("ALTER TABLE history ADD COLUMN headers TEXT DEFAULT '{}'");
      await db.execute("ALTER TABLE history ADD COLUMN collection_headers TEXT DEFAULT '{}'");
      await db.execute("ALTER TABLE history ADD COLUMN body TEXT");
      await db.execute("ALTER TABLE history ADD COLUMN body_type TEXT");
      await db.execute("ALTER TABLE history ADD COLUMN query_params TEXT DEFAULT '{}'");
      await db.execute("ALTER TABLE history ADD COLUMN auth_type TEXT DEFAULT 'none'");
      await db.execute("ALTER TABLE history ADD COLUMN auth_data TEXT DEFAULT '{}'");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE collections ADD COLUMN auth_type TEXT DEFAULT 'none'");
      await db.execute("ALTER TABLE collections ADD COLUMN auth_data TEXT DEFAULT '{}'");
    }
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  @visibleForTesting
  static Future<void> setTestDatabase(Database db) async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = db;
    _initialized = true;
  }

  @visibleForTesting
  static Future<void> resetState() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
    }
    _database = null;
    _initialized = false;
  }
}
