import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/providers/active_environment_provider.dart';
import 'package:dbug/core/providers/repository_providers.dart';
import 'package:dbug/core/repositories/environment_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late ProviderContainer container;
  late EnvironmentRepository repo;

  setUp(() async {
    await setupTestDatabase();
    container = ProviderContainer();
    repo = container.read(environmentRepositoryProvider);
  });

  tearDown(() async {
    container.dispose();
    await tearDownTestDatabase();
  });

  Future<void> settle() async {
    await container.read(environmentsProvider.future);
  }

  test('is derived from the stored is_active flag', () async {
    final env = await repo.createEnvironment(name: 'Dev', variables: {'a': '1'});
    await repo.setActive(env.id);
    container.listen(activeEnvironmentProvider, (_, _) {});
    await settle();
    expect(container.read(activeEnvironmentProvider)?.id, env.id);
    expect(container.read(activeVariablesProvider), {'a': '1'});
  });

  test('setActive persists and updates immediately', () async {
    final env = await repo.createEnvironment(name: 'Dev');
    container.listen(activeEnvironmentProvider, (_, _) {});
    await settle();

    final future = container.read(activeEnvironmentProvider.notifier).setActive(env);
    expect(container.read(activeEnvironmentProvider)?.id, env.id);
    await future;
    await settle();
    expect(container.read(activeEnvironmentProvider)?.id, env.id);
    expect((await repo.getActive())?.id, env.id);

    await container.read(activeEnvironmentProvider.notifier).setActive(null);
    await settle();
    expect(container.read(activeEnvironmentProvider), isNull);
    expect(await repo.getActive(), isNull);
  });

  test('clears itself when the active environment is deleted elsewhere', () async {
    final env = await repo.createEnvironment(name: 'Spec env', variables: {'baseUrl': 'x'});
    await repo.setActive(env.id);
    container.listen(activeEnvironmentProvider, (_, _) {});
    await settle();
    expect(container.read(activeEnvironmentProvider), isNotNull);

    await repo.deleteEnvironment(env.id);
    container.invalidate(environmentsProvider);
    await settle();
    expect(container.read(activeEnvironmentProvider), isNull);
    expect(container.read(activeVariablesProvider), isEmpty);
  });

  test('reflects edits to the active environment without re-selecting it', () async {
    final env = await repo.createEnvironment(name: 'Dev', variables: {'a': '1'});
    await repo.setActive(env.id);
    container.listen(activeEnvironmentProvider, (_, _) {});
    await settle();

    await repo.updateEnvironment(env.copyWith(variables: {'a': '2'}, isActive: true));
    container.invalidate(environmentsProvider);
    await settle();
    expect(container.read(activeVariablesProvider), {'a': '2'});
  });

  test('userEnvironmentsProvider follows environmentsProvider', () async {
    await repo.createEnvironment(name: 'Mine');
    await repo.createEnvironment(name: 'Spec', sourceType: 'openapi');
    expect((await container.read(userEnvironmentsProvider.future)).map((e) => e.name), ['Mine']);

    await repo.createEnvironment(name: 'Another');
    container.invalidate(environmentsProvider);
    expect((await container.read(userEnvironmentsProvider.future)).map((e) => e.name), ['Another', 'Mine']);
  });
}
