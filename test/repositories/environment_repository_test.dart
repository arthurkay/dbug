import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/environment_repository.dart';
import 'package:dbug/core/models/environment_model.dart';
import '../helpers/test_database.dart';

void main() {
  late EnvironmentRepository repo;

  setUp(() async {
    await setupTestDatabase();
    repo = EnvironmentRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('createEnvironment', () {
    test('creates an environment with correct fields', () async {
      final env = await repo.createEnvironment(
        name: 'dev',
        variables: {'host': 'localhost'},
        sourceType: 'user',
      );

      expect(env.name, 'dev');
      expect(env.variables, {'host': 'localhost'});
      expect(env.sourceType, 'user');
      expect(env.id, isNotEmpty);
      expect(env.isActive, isFalse);
    });

    test('creates environment with default values', () async {
      final env = await repo.createEnvironment(name: 'test');
      expect(env.variables, isEmpty);
      expect(env.sourceType, 'user');
    });
  });

  group('updateEnvironment', () {
    test('updates environment fields', () async {
      final env = await repo.createEnvironment(name: 'old');
      final updated = env.copyWith(
        name: 'new',
        variables: {'key': 'value'},
      );
      await repo.updateEnvironment(updated);

      final envs = await repo.getAllEnvironments();
      expect(envs.first.name, 'new');
      expect(envs.first.variables, {'key': 'value'});
    });
  });

  group('setActive', () {
    test('sets one environment active and clears others', () async {
      final env1 = await repo.createEnvironment(name: 'A');
      final env2 = await repo.createEnvironment(name: 'B');

      await repo.setActive(env1.id);
      var active = await repo.getActive();
      expect(active?.id, env1.id);

      await repo.setActive(env2.id);
      active = await repo.getActive();
      expect(active?.id, env2.id);

      final all = await repo.getAllEnvironments();
      final activeEnvs = all.where((e) => e.isActive).toList();
      expect(activeEnvs, hasLength(1));
    });
  });

  group('clearActive', () {
    test('clears the active environment', () async {
      final env = await repo.createEnvironment(name: 'A');
      await repo.setActive(env.id);
      expect(await repo.getActive(), isNotNull);

      await repo.clearActive();
      expect(await repo.getActive(), isNull);
    });
  });

  group('deleteEnvironment', () {
    test('deletes an environment by id', () async {
      final env = await repo.createEnvironment(name: 'to-delete');
      await repo.deleteEnvironment(env.id);

      final envs = await repo.getAllEnvironments();
      expect(envs, isEmpty);
    });
  });

  group('deleteBySourceType', () {
    test('deletes environments by source type', () async {
      await repo.createEnvironment(name: 'User', sourceType: 'user');
      await repo.createEnvironment(name: 'API', sourceType: 'openapi');

      await repo.deleteBySourceType('openapi');
      final envs = await repo.getAllEnvironments();
      expect(envs, hasLength(1));
      expect(envs.first.sourceType, 'user');
    });
  });

  group('sourceSpecId', () {
    test('round-trips through create and getAllEnvironments', () async {
      await repo.createEnvironment(name: 'Spec API', sourceType: 'openapi', sourceSpecId: 'spec-1');

      final envs = await repo.getAllEnvironments();
      expect(envs.single.sourceSpecId, 'spec-1');
    });

    test('deleteBySpecId only removes environments of that spec', () async {
      await repo.createEnvironment(name: 'One API', sourceType: 'openapi', sourceSpecId: 'spec-1');
      await repo.createEnvironment(name: 'Two API', sourceType: 'openapi', sourceSpecId: 'spec-2');
      await repo.createEnvironment(name: 'User env');

      await repo.deleteBySpecId('spec-1');
      final envs = await repo.getAllEnvironments();
      expect(envs.map((e) => e.name).toList(), ['Two API', 'User env']);
    });
  });

  group('getAllEnvironments', () {
    test('returns all environments ordered by name ASC', () async {
      await repo.createEnvironment(name: 'Zebra');
      await repo.createEnvironment(name: 'Alpha');
      await repo.createEnvironment(name: 'Middle');

      final envs = await repo.getAllEnvironments();
      expect(envs.map((e) => e.name).toList(), ['Alpha', 'Middle', 'Zebra']);
    });
  });

  group('getUserEnvironments', () {
    test('returns only user-defined environments', () async {
      await repo.createEnvironment(name: 'User', sourceType: 'user');
      await repo.createEnvironment(name: 'API', sourceType: 'openapi');

      final envs = await repo.getUserEnvironments();
      expect(envs, hasLength(1));
      expect(envs.first.sourceType, 'user');
    });
  });

  group('getActive', () {
    test('returns null when no active environment', () async {
      final active = await repo.getActive();
      expect(active, isNull);
    });

    test('returns the active environment', () async {
      final env = await repo.createEnvironment(name: 'Active');
      await repo.setActive(env.id);

      final active = await repo.getActive();
      expect(active, isNotNull);
      expect(active!.id, env.id);
      expect(active.isActive, isTrue);
    });
  });
}
