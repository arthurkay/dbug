import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/environment_model.dart';
import 'repository_providers.dart';

final activeEnvironmentProvider = StateNotifierProvider<ActiveEnvironmentNotifier, Environment?>((ref) {
  return ActiveEnvironmentNotifier(ref);
});

class ActiveEnvironmentNotifier extends StateNotifier<Environment?> {
  final Ref _ref;

  ActiveEnvironmentNotifier(this._ref) : super(null) {
    _loadActive();
  }

  Future<void> _loadActive() async {
    final repo = _ref.read(environmentRepositoryProvider);
    final env = await repo.getActive();
    state = env;
  }

  Future<void> setActive(Environment? env) async {
    final repo = _ref.read(environmentRepositoryProvider);
    if (env != null) {
      await repo.setActive(env.id);
    } else {
      await repo.clearActive();
    }
    state = env;
  }
}

final activeVariablesProvider = Provider<Map<String, String>>((ref) {
  final env = ref.watch(activeEnvironmentProvider);
  return env?.variables ?? {};
});

String substituteVariables(String input, Map<String, String> variables) {
  return input.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) {
    final key = match.group(1)!;
    return variables[key] ?? match.group(0)!;
  });
}
