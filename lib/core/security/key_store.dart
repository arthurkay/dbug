import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

import 'secret_cipher.dart';

/// Reads and writes the 32-byte data key. The OS keychain is preferred; a
/// 0600 key file in the data directory is the fallback when no keychain is
/// reachable (e.g. no Secret Service on a minimal Linux desktop).
class KeyStore {
  static const _keychainEntry = 'dbug.data-key.v1';
  static const keyFileName = '.data-key';

  final String dataDir;
  final FlutterSecureStorage _storage;

  KeyStore(this.dataDir, {FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // The legacy login keychain needs no keychain-access-groups
              // entitlement, which unsigned/ad-hoc builds can't carry.
              mOptions: MacOsOptions(usesDataProtectionKeychain: false),
            );

  File get _keyFile => File(p.join(dataDir, keyFileName));

  /// Loads an existing key. Never generates one: the caller decides that,
  /// because a missing key may only mean the keychain is temporarily locked.
  Future<(List<int>, SecretStorage)?> load() async {
    try {
      final stored = await _storage.read(key: _keychainEntry);
      if (stored != null) return (base64.decode(stored), SecretStorage.keychain);
    } catch (e) {
      debugPrint('Keychain unavailable: $e');
    }
    if (await _keyFile.exists()) {
      final key = base64.decode((await _keyFile.readAsString()).trim());
      // Promote a fallback key into the keychain once it becomes available.
      if (await _writeKeychain(key)) {
        await _keyFile.delete();
        return (key, SecretStorage.keychain);
      }
      return (key, SecretStorage.keyFile);
    }
    return null;
  }

  /// Persists a newly generated key; returns where it ended up.
  Future<SecretStorage> save(List<int> key) async {
    if (await _writeKeychain(key)) return SecretStorage.keychain;
    await _keyFile.writeAsString(base64.encode(key), flush: true);
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', _keyFile.path]);
    }
    return SecretStorage.keyFile;
  }

  Future<bool> _writeKeychain(List<int> key) async {
    try {
      final encoded = base64.encode(key);
      await _storage.write(key: _keychainEntry, value: encoded);
      // Read back: some backends accept writes they can't persist.
      return await _storage.read(key: _keychainEntry) == encoded;
    } catch (e) {
      debugPrint('Keychain write failed: $e');
      return false;
    }
  }
}
