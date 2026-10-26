import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../../core/constants/app_constants.dart';
import '../../../core/models/mock_endpoint.dart';
import '../../../core/providers/repository_providers.dart';
import '../data/mock_matcher.dart';

class MockServerState {
  final bool isRunning;
  final int port;

  const MockServerState({required this.isRunning, required this.port});
}

/// Owns the shelf server independently of any screen, so navigating away
/// from the Mock Server tab no longer kills a running server.
final mockServerProvider =
    StateNotifierProvider<MockServerController, MockServerState>((ref) {
  final controller = MockServerController(ref);
  // Keep the in-memory endpoint list in step with the database: every
  // add/edit/delete invalidates mockEndpointsProvider, which lands here.
  ref.listen<AsyncValue<List<MockEndpoint>>>(
    mockEndpointsProvider,
    (_, next) => next.whenData(controller.updateEndpoints),
    fireImmediately: true,
  );
  ref.onDispose(controller.stop);
  return controller;
});

class MockServerController extends StateNotifier<MockServerState> {
  final Ref _ref;
  HttpServer? _server;
  List<MockEndpoint> _endpoints = const [];

  MockServerController(this._ref)
      : super(const MockServerState(
          isRunning: false,
          port: AppConstants.defaultMockPort,
        ));

  void updateEndpoints(List<MockEndpoint> endpoints) => _endpoints = endpoints;

  /// Starts the server on [port]. Returns null on success, otherwise an
  /// error message for the UI.
  Future<String?> start(int port) async {
    if (_server != null) return 'Mock server is already running';

    // Load fresh rather than trusting the cache, which may still be loading.
    _endpoints = await _ref.read(mockEndpointRepositoryProvider).getAllEndpoints();

    try {
      _server = await shelf_io.serve(
        (request) => handleMockRequest(request, _endpoints),
        'localhost',
        port,
      );
    } catch (e) {
      return 'Failed to start server: $e';
    }
    state = MockServerState(isRunning: true, port: port);
    return null;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    if (mounted) {
      state = MockServerState(isRunning: false, port: state.port);
    }
  }
}
