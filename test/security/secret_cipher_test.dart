import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/security/secret_cipher.dart';

void main() {
  final key = List<int>.generate(32, (i) => i);
  final cipher = SecretCipher(key);

  test('round-trips text, including unicode', () {
    for (final plain in ['', '{"token":"abc"}', 'héllo ✓ 🔑']) {
      final sealed = cipher.seal(plain);
      expect(SecretCipher.isSealed(sealed), isTrue);
      expect(sealed, isNot(contains(plain.isEmpty ? '\u0000' : plain)));
      expect(cipher.open(sealed), plain);
    }
  });

  test('uses a fresh nonce per seal', () {
    expect(cipher.seal('same'), isNot(cipher.seal('same')));
  });

  test('passes legacy plaintext through unchanged', () {
    expect(cipher.open('{"token":"abc"}'), '{"token":"abc"}');
    expect(cipher.open(null), isNull);
  });

  test('returns null for a wrong key, tampering or truncation', () {
    final sealed = cipher.seal('secret');
    expect(SecretCipher(List<int>.filled(32, 9)).open(sealed), isNull);
    final tampered = '${sealed.substring(0, sealed.length - 4)}AAAA';
    expect(cipher.open(tampered), isNull);
    expect(cipher.open('${SecretCipher.prefix}AAAA'), isNull);
    expect(cipher.open('${SecretCipher.prefix}not base64!'), isNull);
  });

  test('a locked cipher cannot seal and cannot open sealed values', () {
    final locked = SecretCipher.locked();
    expect(() => locked.seal('x'), throwsA(isA<SecretsLockedException>()));
    expect(locked.open(cipher.seal('x')), isNull);
    expect(locked.open('plain'), 'plain');
  });

  test('fingerprints are stable, short and key-specific', () {
    expect(SecretCipher.fingerprint(key), SecretCipher.fingerprint(List.of(key)));
    expect(SecretCipher.fingerprint(key), isNot(SecretCipher.fingerprint(List<int>.filled(32, 1))));
    expect(SecretCipher.fingerprint(key).length, 16);
  });

  test('generated keys are 32 random bytes', () {
    final a = SecretCipher.generateKey();
    expect(a, hasLength(32));
    expect(a, isNot(SecretCipher.generateKey()));
  });
}
