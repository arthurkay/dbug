import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/environment_model.dart';
import 'repository_providers.dart';

/// The active environment, derived from [environmentsProvider] (the row with
/// `is_active`), so edits, deletes and spec removals can never leave a stale
/// copy behind. Change it with `ref.read(activeEnvironmentProvider.notifier)
/// .setActive(env)`.
final activeEnvironmentProvider =
    NotifierProvider<ActiveEnvironmentNotifier, Environment?>(
  ActiveEnvironmentNotifier.new,
);

class ActiveEnvironmentNotifier extends Notifier<Environment?> {
  // Shown while environmentsProvider reloads after setActive, so the UI
  // doesn't flash the previous selection from the refreshing data.
  Environment? _optimistic;
  bool _hasOptimistic = false;

  @override
  Environment? build() {
    final envs = ref.watch(environmentsProvider);
    if (_hasOptimistic && envs.isLoading) return _optimistic;
    _hasOptimistic = false;
    return envs.valueOrNull?.where((e) => e.isActive).firstOrNull;
  }

  Future<void> setActive(Environment? env) async {
    _optimistic = env;
    _hasOptimistic = true;
    state = env;
    final repo = ref.read(environmentRepositoryProvider);
    if (env != null) {
      await repo.setActive(env.id);
    } else {
      await repo.clearActive();
    }
    ref.invalidate(environmentsProvider);
  }
}

final activeVariablesProvider = Provider<Map<String, String>>((ref) {
  final env = ref.watch(activeEnvironmentProvider);
  return env?.variables ?? {};
});

/// `{{name}}` or `{{ name }}`; names may contain letters, digits, `_`, `.`
/// and `-` (e.g. `{{api-key}}`, `{{auth.token}}`).
final _variablePattern = RegExp(r'\{\{\s*([\w.\-]+)\s*\}\}');

String substituteVariables(String input, Map<String, String> variables) {
  return input.replaceAllMapped(_variablePattern, (match) {
    final key = match.group(1)!;
    return variables[key] ?? match.group(0)!;
  });
}
