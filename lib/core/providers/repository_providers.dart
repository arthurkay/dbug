import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/collection_repository.dart';
import '../repositories/request_repository.dart';
import '../repositories/openapi_repository.dart';
import '../repositories/history_repository.dart';
import '../repositories/environment_repository.dart';
import '../repositories/mock_endpoint_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository();
});

final openApiRepositoryProvider = Provider<OpenApiRepository>((ref) {
  return OpenApiRepository();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

final environmentRepositoryProvider = Provider<EnvironmentRepository>((ref) {
  return EnvironmentRepository();
});

final mockEndpointRepositoryProvider = Provider<MockEndpointRepository>((ref) {
  return MockEndpointRepository();
});

final collectionsProvider = FutureProvider((ref) {
  return ref.watch(collectionRepositoryProvider).getAllCollections();
});

final collectionByIdProvider = FutureProvider.family((ref, String collectionId) {
  return ref.watch(collectionRepositoryProvider).getCollection(collectionId);
});

final requestsByCollectionProvider = FutureProvider.family((ref, String collectionId) {
  return ref.watch(requestRepositoryProvider).getRequestsByCollection(collectionId);
});

/// Lightweight list rows (no raw content or parsed endpoints).
final specSummariesProvider = FutureProvider((ref) {
  return ref.watch(openApiRepositoryProvider).getSpecSummaries();
});

final specByIdProvider = FutureProvider.family((ref, String specId) {
  return ref.watch(openApiRepositoryProvider).getSpec(specId);
});

/// The collection generated when the spec was imported, if it still exists.
final collectionForSpecProvider = FutureProvider.family((ref, String specId) {
  return ref.watch(openApiRepositoryProvider).getCollectionForSpec(specId);
});

final historyEntryProvider = FutureProvider.family((ref, String id) {
  return ref.watch(historyRepositoryProvider).getEntry(id);
});

final historyProvider = FutureProvider((ref) {
  return ref.watch(historyRepositoryProvider).getAllHistory();
});

final environmentsProvider = FutureProvider((ref) {
  return ref.watch(environmentRepositoryProvider).getAllEnvironments();
});

/// Derived from [environmentsProvider] so it refreshes whenever that does.
final userEnvironmentsProvider = FutureProvider((ref) async {
  final envs = await ref.watch(environmentsProvider.future);
  return envs.where((e) => e.isUserDefined).toList();
});

final mockEndpointsProvider = FutureProvider((ref) {
  return ref.watch(mockEndpointRepositoryProvider).getAllEndpoints();
});
