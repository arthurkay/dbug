import 'package:dbug/core/repositories/mock_endpoint_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

void main() {
  late MockEndpointRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = MockEndpointRepository();
  });

  tearDown(tearDownTestDatabase);

  test('stores the method upper-case', () async {
    final ep = await repo.createEndpoint(method: 'patch', path: '/x');
    expect(ep.method, 'PATCH');
    expect((await repo.getAllEndpoints()).single.method, 'PATCH');
  });

  test('rejects a duplicate method + path regardless of method case', () async {
    await repo.createEndpoint(method: 'GET', path: '/dup');
    await expectLater(
      repo.createEndpoint(method: 'get', path: '/dup'),
      throwsA(isA<DatabaseException>().having((e) => e.isUniqueConstraintError(), 'unique', isTrue)),
    );
  });

  test('rejects an update that collides with another endpoint', () async {
    await repo.createEndpoint(method: 'GET', path: '/a');
    final b = await repo.createEndpoint(method: 'GET', path: '/b');
    await expectLater(
      repo.updateEndpoint(b.copyWith(path: '/a')),
      throwsA(isA<DatabaseException>()),
    );
  });
}
