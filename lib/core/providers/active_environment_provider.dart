import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/environment_model.dart';

final activeEnvironmentProvider = StateProvider<Environment?>((ref) => null);

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
