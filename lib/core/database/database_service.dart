import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../security/key_store.dart';
import '../security/secret_cipher.dart';

class DatabaseService {
  static Database? _database;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialized = true;
  }

  static Future<Database>? _opening;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    // Concurrent first calls (several providers load at startup) must share
    // one open, or each would run the legacy-location move and open its own
    // connection.
    _opening ??= () async {
      await init();
      return _initDatabase();
    }();
    try {
      return _database = await _opening!;
    } finally {
      _opening = null;
    }
  }

  static Future<Database> _initDatabase() async {
    try {
      final dir = await _dataDirectory();
      await dir.create(recursive: true);
      final path = join(dir.path, AppConstants.dbName);
      await _migrateLegacyLocation(path);

      final db = await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
      await setUpSecrets(db, KeyStore(dir.path));
      return db;
    } catch (e) {
      debugPrint('Failed to initialize database: $e');
      rethrow;
    }
  }

  /// The directory holding the database. On Linux this is pinned to
  /// `$XDG_DATA_HOME/<app id>` instead of path_provider's support directory:
  /// when `<app id>` doesn't exist yet, path_provider falls back to
  /// `~/.local/share/<executable>` = `~/.local/share/dbug` if present — which
  /// is exactly where install.sh puts the app and deletes on every upgrade.
  static Future<Directory> _dataDirectory() async {
    if (Platform.isLinux) {
      return Directory(linuxDataDirectory(Platform.environment));
    }
    return getApplicationSupportDirectory();
  }

  @visibleForTesting
  static String linuxDataDirectory(Map<String, String> env) {
    final xdg = env['XDG_DATA_HOME'];
    final base = xdg != null && xdg.isNotEmpty && isAbsolute(xdg)
        ? xdg
        : join(env['HOME'] ?? '.', '.local', 'share');
    return join(base, AppConstants.appId);
  }

  /// Versions up to 0.1.6 kept the database in the Documents folder, where it
  /// sat in plain view (and possibly in a cloud-synced folder). Move it to the
  /// app-support directory once. Failures are logged and never fatal: the app
  /// then simply starts with a fresh database at the new location.
  static Future<void> _migrateLegacyLocation(String newPath) async {
    try {
      if (await File(newPath).exists()) return;
      final docs = await getApplicationDocumentsDirectory();
      final oldPath = join(docs.path, AppConstants.dbName);
      if (oldPath == newPath || !await File(oldPath).exists()) return;
      for (final suffix in const ['', '-wal', '-shm', '-journal']) {
        final src = File('$oldPath$suffix');
        if (!await src.exists()) continue;
        try {
          await src.rename('$newPath$suffix');
        } on FileSystemException {
          // rename fails across filesystems; copy then delete instead. Copy
          // to a temp name first so an interrupted copy never leaves a
          // partial file at the final path (which would hide the old data).
          final tmp = '$newPath$suffix.moving';
          await src.copy(tmp);
          await File(tmp).rename('$newPath$suffix');
          await src.delete();
        }
      }
      debugPrint('Moved database from $oldPath to $newPath');
    } catch (e) {
      debugPrint('Failed to move legacy database: $e');
    }
  }

  /// Creates the full, current-version schema. Also used by the test
  /// database helper so tests can never drift from the real schema.
  static Future<void> createSchema(Database db) async {
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
        auth_type TEXT DEFAULT 'none',
        auth_data TEXT DEFAULT '{}',
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
        auth_data TEXT DEFAULT '{}',
        resolved_url TEXT,
        response_headers TEXT DEFAULT '{}',
        response_truncated INTEGER DEFAULT 0
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
    await db.execute(
      'CREATE UNIQUE INDEX idx_mock_method_path ON mock_endpoints(method, path)',
    );

    await _createAppMeta(db);
  }

  static Future<void> _createAppMeta(DatabaseExecutor db) => db.execute(
        'CREATE TABLE IF NOT EXISTS app_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );

  static Future<void> _onCreate(Database db, int version) => createSchema(db);

  @visibleForTesting
  static Future<void> upgradeSchema(Database db, int oldVersion, int newVersion) =>
      _onUpgrade(db, oldVersion, newVersion);

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
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE environments ADD COLUMN source_spec_id TEXT");
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE requests ADD COLUMN auth_type TEXT DEFAULT 'none'");
      await db.execute("ALTER TABLE requests ADD COLUMN auth_data TEXT DEFAULT '{}'");
      await db.execute("ALTER TABLE history ADD COLUMN resolved_url TEXT");
      await db.execute("ALTER TABLE history ADD COLUMN response_headers TEXT DEFAULT '{}'");
      await db.execute("ALTER TABLE history ADD COLUMN response_truncated INTEGER DEFAULT 0");
      // Older history rows stored the resolved URL in `url`; that is the best
      // available value for both columns.
      await db.execute('UPDATE history SET resolved_url = url WHERE resolved_url IS NULL');
      // Duplicate method+path mocks made matching arbitrary; keep the oldest.
      await db.execute('''
        DELETE FROM mock_endpoints WHERE rowid NOT IN (
          SELECT MIN(rowid) FROM mock_endpoints GROUP BY method, path
        )
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX idx_mock_method_path ON mock_endpoints(method, path)',
      );
    }
    if (oldVersion < 8) {
      // Holds the encryption key fingerprint; existing plaintext credentials
      // are encrypted by setUpSecrets once the key is known.
      await _createAppMeta(db);
    }
  }

  /// Resolves the data key and encrypts any plaintext credentials.
  ///
  /// A new key is generated only when the database has never been encrypted
  /// (no stored fingerprint). If it has, but the key can't be found or
  /// doesn't match, the app runs locked rather than replacing the key, which
  /// would make every stored credential permanently unreadable.
  @visibleForTesting
  static Future<void> setUpSecrets(Database db, KeyStore keyStore) async {
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: ['key_fingerprint']);
    final storedFingerprint = rows.isEmpty ? null : rows.first['value'] as String;

    final List<int> key;
    final SecretStorage source;
    final loaded = await keyStore.load();
    if (loaded != null) {
      (key, source) = loaded;
      if (storedFingerprint != null && storedFingerprint != SecretCipher.fingerprint(key)) {
        debugPrint('Data key does not match this database; credentials are locked');
        Secrets.configure(SecretCipher.locked(), SecretStorage.locked);
        return;
      }
    } else if (storedFingerprint != null) {
      debugPrint('Data key not found; credentials are locked');
      Secrets.configure(SecretCipher.locked(), SecretStorage.locked);
      return;
    } else {
      key = SecretCipher.generateKey();
      source = await keyStore.save(key);
    }
    Secrets.configure(SecretCipher(key), source);

    if (storedFingerprint == null) {
      await db.insert(
        'app_meta',
        {'key': 'key_fingerprint', 'value': SecretCipher.fingerprint(key)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await encryptPlaintextSecrets(db);
  }

  /// Columns that can hold credentials, by table.
  static const secretColumns = {
    'collections': ['global_headers', 'auth_data'],
    'requests': ['headers', 'auth_data'],
    'environments': ['variables'],
    // `url` too: rows from before v7 stored the resolved URL there, with
    // environment values (tokens, keys) substituted in.
    'history': ['url', 'headers', 'collection_headers', 'auth_data', 'resolved_url'],
  };

  /// Seals every plaintext value in [secretColumns]; returns how many were
  /// changed. VACUUMs afterwards so the plaintext doesn't linger in freed
  /// database pages.
  @visibleForTesting
  static Future<int> encryptPlaintextSecrets(Database db) async {
    if (Secrets.isLocked) return 0;
    var changed = 0;
    await db.transaction((txn) async {
      for (final MapEntry(key: table, value: columns) in secretColumns.entries) {
        final rows = await txn.query(table, columns: ['rowid', ...columns]);
        for (final row in rows) {
          final updates = <String, String>{};
          for (final column in columns) {
            final value = row[column] as String?;
            if (value != null && !SecretCipher.isSealed(value)) {
              updates[column] = Secrets.cipher.seal(value);
            }
          }
          if (updates.isEmpty) continue;
          await txn.update(table, updates, where: 'rowid = ?', whereArgs: [row['rowid']]);
          changed++;
        }
      }
    });
    if (changed > 0) {
      await db.execute('VACUUM');
      debugPrint('Encrypted credentials in $changed rows');
    }
    return changed;
  }

  static Future<void> close() async {
    await _database?.close();
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
    _opening = null;
    _initialized = false;
  }
}
