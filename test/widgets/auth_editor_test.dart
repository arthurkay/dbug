import 'package:dbug/core/models/auth_config.dart';
import 'package:dbug/shared/widgets/auth_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, AuthConfig value, ValueChanged<AuthConfig> onChanged) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AuthEditor(value: value, onChanged: onChanged)),
    ));
  }

  testWidgets('emits type changes and typed credentials', (tester) async {
    AuthConfig? last;
    await pump(tester, AuthConfig.none, (v) => last = v);
    expect(find.text('No authentication'), findsOneWidget);

    await tester.tap(find.text('Bearer'));
    await tester.pump();
    expect(last!.type, AuthType.bearer);

    await tester.enterText(find.byType(TextField), 'abc');
    expect(last!.token, 'abc');
    expect(last!.headers(), {'Authorization': 'Bearer abc'});
  });

  testWidgets('api key location toggles', (tester) async {
    AuthConfig? last;
    await pump(tester, const AuthConfig(type: AuthType.apiKey, apiKeyName: 'k', apiKeyValue: 'v'), (v) => last = v);
    await tester.tap(find.text('Query Param'));
    await tester.pump();
    expect(last!.queryParams(), {'k': 'v'});
  });

  testWidgets('resets fields when the parent loads a different config', (tester) async {
    await pump(tester, const AuthConfig(type: AuthType.bearer, token: 'one'), (_) {});
    expect(find.text('one'), findsOneWidget);
    await pump(tester, const AuthConfig(type: AuthType.bearer, token: 'two'), (_) {});
    expect(find.text('two'), findsOneWidget);
    await pump(tester, const AuthConfig(type: AuthType.basic, username: 'u'), (_) {});
    expect(find.text('u'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2), reason: 'username + password fields');
  });
}
