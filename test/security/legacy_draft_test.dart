import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dbug/core/security/secret_cipher.dart';
import 'package:dbug/features/request_builder/screens/request_screen.dart';

void main() {
  const key = 'request_builder_state';
  const plain = '{"authData":"{\\"token\\":\\"secret\\"}"}';

  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  test('a plaintext draft is re-saved sealed, and stays readable', () async {
    SharedPreferences.setMockInitialValues({key: plain});
    Secrets.useKeyForTesting();

    await sealLegacyRequestDraft();

    final stored = (await SharedPreferences.getInstance()).getString(key)!;
    expect(SecretCipher.isSealed(stored), isTrue);
    expect(stored, isNot(contains('secret')));
    expect(Secrets.cipher.open(stored), plain);
  });

  test('a sealed draft is left alone, and nothing is written while locked', () async {
    Secrets.useKeyForTesting();
    final sealed = Secrets.cipher.seal(plain);
    SharedPreferences.setMockInitialValues({key: sealed});
    await sealLegacyRequestDraft();
    expect((await SharedPreferences.getInstance()).getString(key), sealed);

    SharedPreferences.setMockInitialValues({key: plain});
    Secrets.lockForTesting();
    await sealLegacyRequestDraft();
    expect((await SharedPreferences.getInstance()).getString(key), plain);
  });
}
