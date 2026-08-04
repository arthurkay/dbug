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

final requestsByCollectionProvider = FutureProvider.family((ref, String collectionId) {
  return ref.watch(requestRepositoryProvider).getRequestsByCollection(collectionId);
});

final allSpecsProvider = FutureProvider((ref) {
  return ref.watch(openApiRepositoryProvider).getAllSpecs();
});

final historyProvider = FutureProvider((ref) {
  return ref.watch(historyRepositoryProvider).getAllHistory();
});

final environmentsProvider = FutureProvider((ref) {
  return ref.watch(environmentRepositoryProvider).getAllEnvironments();
});

final userEnvironmentsProvider = FutureProvider((ref) {
  return ref.watch(environmentRepositoryProvider).getUserEnvironments();
});

final mockEndpointsProvider = FutureProvider((ref) {
  return ref.watch(mockEndpointRepositoryProvider).getAllEndpoints();
});
