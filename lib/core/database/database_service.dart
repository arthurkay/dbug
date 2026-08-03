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
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        source_type TEXT DEFAULT 'manual',
        source_spec_id TEXT,
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
        is_active INTEGER DEFAULT 0
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
        sent_at INTEGER NOT NULL
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
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
