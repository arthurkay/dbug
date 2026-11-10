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

/// The variables a request in [collectionId] resolves against: the active
/// environment's, layered over the environment generated for the
/// collection's OpenAPI spec. The active environment always wins; the spec
/// environment only fills in names it doesn't define (blank spec values are
/// skipped), so e.g. a "Staging" environment that sets `url`/`port` still
/// gets the spec's `baseUrl = https://{{url}}:{{port}}/api`.
final requestVariablesProvider =
    Provider.family<Map<String, String>, String?>((ref, collectionId) {
  final active = ref.watch(activeVariablesProvider);
  if (collectionId == null) return active;
  final specId = ref.watch(collectionByIdProvider(collectionId)).valueOrNull?.sourceSpecId;
  if (specId == null) return active;
  final specEnv = ref
      .watch(environmentsProvider)
      .valueOrNull
      ?.where((e) => e.sourceSpecId == specId)
      .firstOrNull;
  return layerVariables(active, specEnv?.variables ?? const {});
});

/// [primary] over the non-blank entries of [fallback]. Names match
/// case-insensitively, so a primary `baseurl` replaces a fallback `baseUrl`.
Map<String, String> layerVariables(Map<String, String> primary, Map<String, String> fallback) {
  final overridden = primary.keys.map((k) => k.toLowerCase()).toSet();
  return {
    for (final e in fallback.entries)
      if (e.value.isNotEmpty && !overridden.contains(e.key.toLowerCase())) e.key: e.value,
    ...primary,
  };
}

/// `{{name}}` or `{{ name }}`; names may contain letters, digits, `_`, `.`
/// and `-` (e.g. `{{api-key}}`, `{{auth.token}}`).
final _variablePattern = RegExp(r'\{\{\s*([\w.\-]+)\s*\}\}');

/// Replaces `{{name}}` placeholders with their values. Values may refer to
/// other variables (`baseUrl = https://{{host}}:{{port}}`); those are expanded
/// too, up to a fixed depth so self-references can't loop forever. Names
/// match exactly first, then ignoring case. Unknown names are left as-is.
String substituteVariables(String input, Map<String, String> variables) {
  if (variables.isEmpty) return input;
  Map<String, String>? folded;
  var current = input;
  for (var depth = 0; depth < _maxNesting; depth++) {
    final next = current.replaceAllMapped(_variablePattern, (match) {
      final key = match.group(1)!;
      final exact = variables[key];
      if (exact != null) return exact;
      // `{{baseUrl}}` also finds `baseurl`/`BASEURL`.
      folded ??= {for (final e in variables.entries) e.key.toLowerCase(): e.value};
      return folded![key.toLowerCase()] ?? match.group(0)!;
    });
    if (next == current) break;
    current = next;
  }
  return current;
}

const _maxNesting = 8;

/// The `{{name}}` placeholders still present in [text], in order, without
/// duplicates.
List<String> placeholderNames(String text) =>
    _variablePattern.allMatches(text).map((m) => m.group(1)!).toSet().toList();
