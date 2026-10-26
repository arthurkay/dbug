import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dbug/core/database/database_service.dart';
import 'package:dbug/core/repositories/collection_repository.dart';
import 'package:dbug/core/repositories/environment_repository.dart';
import 'package:dbug/core/repositories/history_repository.dart';
import 'package:dbug/core/repositories/request_repository.dart';
import 'package:dbug/core/security/key_store.dart';
import 'package:dbug/core/security/secret_cipher.dart';

import '../helpers/test_database.dart';

/// In-memory keychain; [available] = false simulates no Secret Service.
class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};
  bool available = true;

  FakeSecureStorage();

  void _check() {
    if (!available) throw PlatformExceptionLike();
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

class PlatformExceptionLike implements Exception {}

void main() {
  late Database db;
  late Directory dataDir;
  late FakeSecureStorage keychain;

  KeyStore keyStore() => KeyStore(dataDir.path, storage: keychain);

  setUp(() async {
    db = await setupTestDatabase();
    dataDir = await Directory.systemTemp.createTemp('dbug-keys');
    keychain = FakeSecureStorage();
    Secrets.lockForTesting();
  });

  tearDown(() async {
    await tearDownTestDatabase();
    await dataDir.delete(recursive: true);
  });

  Future<String?> rawValue(String table, String column) async =>
      (await db.query(table, columns: [column])).first[column] as String?;

  Future<String?> storedFingerprint() async {
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: ['key_fingerprint']);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  test('first run generates a key in the keychain and records its fingerprint', () async {
    await DatabaseService.setUpSecrets(db, keyStore());

    expect(Secrets.storage, SecretStorage.keychain);
    expect(Secrets.isLocked, isFalse);
    expect(keychain.values, hasLength(1));
    expect(await storedFingerprint(), isNotNull);
    expect(File('${dataDir.path}/${KeyStore.keyFileName}').existsSync(), isFalse);
  });

  test('encrypts existing plaintext credentials and the app still reads them', () async {
    // Rows written before encryption existed.
    await db.insert('collections', {
      'id': 'c1', 'name': 'C', 'global_headers': '{"X-Api-Key":"k1"}',
      'auth_type': 'bearer', 'auth_data': '{"token":"t1"}', 'created_at': 0, 'updated_at': 0,
    });
    await db.insert('requests', {
      'id': 'r1', 'collection_id': 'c1', 'name': 'R', 'method': 'GET', 'url': 'u',
      'headers': '{"Authorization":"Bearer t2"}', 'auth_data': '{"token":"t3"}',
      'created_at': 0, 'updated_at': 0,
    });
    await db.insert('environments', {'id': 'e1', 'name': 'E', 'variables': '{"token":"t4"}'});
    await db.insert('history', {
      'id': 'h1', 'method': 'GET', 'url': '{{u}}', 'resolved_url': 'https://x/?key=t5',
      'sent_at': 0, 'headers': '{"a":"t6"}', 'collection_headers': '{"b":"t7"}',
      'auth_data': '{"token":"t8"}',
    });

    await DatabaseService.setUpSecrets(db, keyStore());

    for (final (table, column) in [
      ('collections', 'global_headers'), ('collections', 'auth_data'),
      ('requests', 'headers'), ('requests', 'auth_data'),
      ('environments', 'variables'),
      ('history', 'headers'), ('history', 'collection_headers'),
      ('history', 'auth_data'), ('history', 'resolved_url'), ('history', 'url'),
    ]) {
      final raw = await rawValue(table, column);
      expect(SecretCipher.isSealed(raw), isTrue, reason: '$table.$column');
      // Base64 never contains quotes, braces or ':' — so no JSON or URL
      // plaintext survives in the stored value.
      expect(raw!.substring(SecretCipher.prefix.length), isNot(matches(RegExp(r'["{}:]'))),
          reason: 'no plaintext in $table.$column');
    }

    final collection = (await CollectionRepository().getCollection('c1'))!;
    expect(collection.globalHeaders, {'X-Api-Key': 'k1'});
    expect(collection.authData, '{"token":"t1"}');
    final request = (await RequestRepository().getRequest('r1'))!;
    expect(request.headers, {'Authorization': 'Bearer t2'});
    expect(request.authData, '{"token":"t3"}');
    expect((await EnvironmentRepository().getAllEnvironments()).single.variables, {'token': 't4'});
    final entry = (await HistoryRepository().getEntry('h1'))!;
    expect(entry.resolvedUrl, 'https://x/?key=t5');
    expect(entry.url, '{{u}}');
    expect(entry.authData, '{"token":"t8"}');

    // A second sweep finds nothing left to encrypt.
    expect(await DatabaseService.encryptPlaintextSecrets(db), 0);
  });

  test('a restart with the same key unlocks the data', () async {
    await DatabaseService.setUpSecrets(db, keyStore());
    await CollectionRepository().createCollection(name: 'C', authType: 'bearer', authData: '{"token":"t"}');
    Secrets.lockForTesting();

    await DatabaseService.setUpSecrets(db, keyStore());
    expect(Secrets.isLocked, isFalse);
    expect((await CollectionRepository().getAllCollections()).single.authData, '{"token":"t"}');
  });

  test('never replaces a missing key once data is encrypted: runs locked instead', () async {
    await DatabaseService.setUpSecrets(db, keyStore());
    await CollectionRepository().createCollection(name: 'C', authType: 'bearer', authData: '{"token":"t"}');
    final sealedBefore = await rawValue('collections', 'auth_data');
    keychain.values.clear(); // e.g. keyring reset or not unlocked yet

    await DatabaseService.setUpSecrets(db, keyStore());

    expect(Secrets.storage, SecretStorage.locked);
    expect(keychain.values, isEmpty, reason: 'no new key generated');
    expect(await rawValue('collections', 'auth_data'), sealedBefore);
    // Unreadable credentials come back empty instead of crashing.
    expect((await CollectionRepository().getAllCollections()).single.authData, '{}');
  });

  test('a key that does not match the stored fingerprint locks instead of decrypting garbage', () async {
    await DatabaseService.setUpSecrets(db, keyStore());
    keychain.values.updateAll((_, _) => 'AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=');

    await DatabaseService.setUpSecrets(db, keyStore());
    expect(Secrets.storage, SecretStorage.locked);
  });

  test('while locked, updates keep the stored ciphertext and inserts store empty values', () async {
    await DatabaseService.setUpSecrets(db, keyStore());
    final repo = CollectionRepository();
    final c = await repo.createCollection(name: 'C', authType: 'bearer', authData: '{"token":"t"}');
    final sealedBefore = await rawValue('collections', 'auth_data');
    Secrets.lockForTesting();

    await repo.updateCollection(c.copyWith(name: 'Renamed', authData: '{}'));
    final row = (await db.query('collections')).single;
    expect(row['name'], 'Renamed');
    expect(row['auth_data'], sealedBefore);

    final r = await RequestRepository().createRequest(
      name: 'R', method: 'GET', url: 'u', headers: {'Authorization': 'x'}, authData: '{"token":"y"}',
    );
    final reqRow = (await db.query('requests', where: 'id = ?', whereArgs: [r.id])).single;
    expect(reqRow['headers'], '{}');
    expect(reqRow['auth_data'], '{}');
  });

  test('falls back to a private key file when no keychain is available', () async {
    keychain.available = false;
    await DatabaseService.setUpSecrets(db, keyStore());

    expect(Secrets.storage, SecretStorage.keyFile);
    final keyFile = File('${dataDir.path}/${KeyStore.keyFileName}');
    expect(keyFile.existsSync(), isTrue);
    if (!Platform.isWindows) {
      final mode = (await keyFile.stat()).mode & 0x1FF;
      expect(mode, 0x180, reason: 'key file must be 0600');
    }
  });

  test('moves a key-file key into the keychain once one is available', () async {
    keychain.available = false;
    await DatabaseService.setUpSecrets(db, keyStore());
    await CollectionRepository().createCollection(name: 'C', authType: 'bearer', authData: '{"token":"t"}');

    keychain.available = true;
    await DatabaseService.setUpSecrets(db, keyStore());

    expect(Secrets.storage, SecretStorage.keychain);
    expect(File('${dataDir.path}/${KeyStore.keyFileName}').existsSync(), isFalse);
    expect((await CollectionRepository().getAllCollections()).single.authData, '{"token":"t"}');
  });
}
