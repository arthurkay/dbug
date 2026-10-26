import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Thrown when credentials must be written but the data key is unavailable.
class SecretsLockedException implements Exception {
  @override
  String toString() => 'Stored credentials are locked: the encryption key is unavailable';
}

/// AES-256-GCM encryption for credential-bearing database fields.
///
/// Values are stored as `enc:v1:<base64(nonce ‖ ciphertext ‖ tag)>`. Anything
/// without the prefix is legacy plaintext and is returned as-is by [open], so
/// databases written before encryption keep working until they are swept.
class SecretCipher {
  static const prefix = 'enc:v1:';
  static const _nonceLength = 12;
  static const _macLength = 16;
  static final _aad = utf8.encode('dbug');

  final SecretKeyData? _key;
  final _aes = DartAesGcm.with256bits();

  SecretCipher(List<int> key) : _key = SecretKeyData(key) {
    if (key.length != 32) throw ArgumentError('Expected a 32-byte key');
  }

  /// A cipher without a key: stored secrets can't be read or written.
  SecretCipher.locked() : _key = null;

  bool get isLocked => _key == null;

  static bool isSealed(String? value) => value != null && value.startsWith(prefix);

  static List<int> generateKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  /// Short, non-reversible identifier of [key], stored next to the data so a
  /// wrong key is detected instead of silently replacing the real one.
  static String fingerprint(List<int> key) {
    final hash = const DartSha256().hashSync([...utf8.encode('dbug-key-fingerprint'), ...key]);
    return base64Url.encode(hash.bytes.sublist(0, 12));
  }

  /// Encrypts [plain]. Throws [SecretsLockedException] when locked.
  String seal(String plain) {
    final key = _key;
    if (key == null) throw SecretsLockedException();
    final box = _aes.encryptSync(utf8.encode(plain), secretKeyData: key, aad: _aad);
    return prefix + base64.encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Decrypts a sealed value; plaintext passes through unchanged. Returns null
  /// when the value is sealed but can't be decrypted (locked or wrong key).
  String? open(String? value) {
    if (value == null || !value.startsWith(prefix)) return value;
    final key = _key;
    if (key == null) return null;
    try {
      final bytes = base64.decode(value.substring(prefix.length));
      if (bytes.length < _nonceLength + _macLength) return null;
      final box = SecretBox(
        bytes.sublist(_nonceLength, bytes.length - _macLength),
        nonce: bytes.sublist(0, _nonceLength),
        mac: Mac(bytes.sublist(bytes.length - _macLength)),
      );
      return utf8.decode(_aes.decryptSync(box, secretKeyData: key, aad: _aad));
    } catch (_) {
      return null;
    }
  }
}

/// Where the data key came from, shown in Settings.
enum SecretStorage {
  /// The OS keychain / Secret Service / Credential Manager.
  keychain,

  /// A 0600 key file next to the database (no keychain was reachable).
  keyFile,

  /// The database has encrypted data but its key couldn't be found.
  locked,
}

/// The process-wide cipher used by the repositories. Set up by
/// DatabaseService when the database opens.
class Secrets {
  Secrets._();

  static SecretCipher _cipher = SecretCipher.locked();
  static SecretStorage storage = SecretStorage.locked;

  static SecretCipher get cipher => _cipher;
  static bool get isLocked => _cipher.isLocked;

  static void configure(SecretCipher cipher, SecretStorage source) {
    _cipher = cipher;
    storage = source;
  }

  /// Seals [value] for storage, or returns null when locked so callers can
  /// leave the stored column untouched instead of overwriting it.
  static String? sealOrNull(String value) => isLocked ? null : _cipher.seal(value);

  /// For inserts: seals [value]; when locked stores [lockedFallback] (an empty
  /// value), since a new row has no previous secret to preserve.
  static String sealForInsert(String value, {String lockedFallback = '{}'}) =>
      isLocked ? lockedFallback : _cipher.seal(value);

  /// Returns [values] with [secrets] added sealed, for an UPDATE. While
  /// locked the secret columns are left out, preserving what's stored.
  static Map<String, Object?> sealedUpdate(
    Map<String, Object?> values,
    Map<String, String> secrets,
  ) {
    if (isLocked) return values;
    return {...values, for (final e in secrets.entries) e.key: _cipher.seal(e.value)};
  }

  /// Reads a stored column; sealed values that can't be opened yield
  /// [unreadable].
  static String openOr(String? stored, String unreadable) =>
      _cipher.open(stored) ?? unreadable;

  @visibleForTesting
  static void useKeyForTesting([List<int>? key]) {
    configure(SecretCipher(key ?? List<int>.filled(32, 7)), SecretStorage.keychain);
  }

  @visibleForTesting
  static void lockForTesting() => configure(SecretCipher.locked(), SecretStorage.locked);
}
