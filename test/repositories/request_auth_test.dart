import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/request_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late RequestRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = RequestRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  test('requests default to no auth', () async {
    final r = await repo.createRequest(name: 'r', method: 'GET', url: 'u');
    final loaded = await repo.getRequest(r.id);
    expect(loaded!.authType, 'none');
    expect(loaded.authData, '{}');
  });

  test('request auth persists through create, update and reload', () async {
    final authData = jsonEncode({'token': 'abc'});
    final r = await repo.createRequest(
      name: 'r', method: 'GET', url: 'u', authType: 'bearer', authData: authData,
    );
    expect((await repo.getRequest(r.id))!.authType, 'bearer');
    expect((await repo.getRequest(r.id))!.authData, authData);

    final apiKey = jsonEncode({'name': 'X-Key', 'value': 'v', 'location': 'query'});
    await repo.updateRequest(r.copyWith(authType: 'apikey', authData: apiKey));
    final reloaded = await repo.getRequest(r.id);
    expect(reloaded!.authType, 'apikey');
    expect(reloaded.authData, apiKey);
  });
}
