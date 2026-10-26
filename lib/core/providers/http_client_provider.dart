import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../http/http_client.dart';
import 'settings_provider.dart';

/// Rebuilt whenever the network settings change, so a new timeout or TLS
/// choice applies to the next request.
final httpClientProvider = Provider<DbugHttpClient>((ref) {
  final settings = ref.watch(settingsProvider.select(
    (s) => (s.timeoutSeconds, s.allowInsecureTls),
  ));
  final client = DbugHttpClient(
    timeout: Duration(seconds: settings.$1),
    allowInsecureTls: settings.$2,
  );
  ref.onDispose(client.dispose);
  return client;
});
