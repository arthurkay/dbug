import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/active_environment_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../shared/widgets/toast_helper.dart';

/// When a request from an OpenAPI collection is opened and no environment is
/// active, activates the environment generated for that spec so `{{baseUrl}}`
/// and path params resolve. An environment the user already picked is never
/// replaced. Returns the activated environment's name, if any.
Future<String?> activateSpecEnvironmentIfNone(
  WidgetRef ref,
  BuildContext context,
  String collectionId,
) async {
  try {
    final envs = await ref.read(environmentsProvider.future);
    if (envs.any((e) => e.isActive)) return null;

    final env = await ref.read(environmentRepositoryProvider).getForCollection(collectionId);
    if (env == null) return null;

    await ref.read(activeEnvironmentProvider.notifier).setActive(env);
    if (context.mounted) {
      showDbugToast(context, message: 'Activated environment "${env.name}"', type: ToastType.info);
    }
    return env.name;
  } catch (e) {
    debugPrint('Failed to activate spec environment: $e');
    return null;
  }
}
