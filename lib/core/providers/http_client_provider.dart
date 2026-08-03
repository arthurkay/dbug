import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../http/http_client.dart';

final httpClientProvider = Provider<DbugHttpClient>((ref) {
  final client = DbugHttpClient();
  ref.onDispose(() => client.dispose());
  return client;
});
