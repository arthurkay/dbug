import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/repository_providers.dart';

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
  ref.onDispose(controller.stop);
  return controller;
});

class MockServerController extends StateNotifier<MockServerState> {
  final Ref _ref;
  HttpServer? _server;

  MockServerController(this._ref)
      : super(const MockServerState(
          isRunning: false,
          port: AppConstants.defaultMockPort,
        ));

  /// Starts the server on [port]. Returns null on success, otherwise an
  /// error message for the UI.
  Future<String?> start(int port) async {
    if (_server != null) return 'Mock server is already running';

    final repo = _ref.read(mockEndpointRepositoryProvider);

    Future<shelf.Response> handler(shelf.Request request) async {
      // Look up the endpoint per request so additions and edits made while
      // the server is running take effect immediately.
      final match =
          await repo.matchEndpoint(request.method, request.requestedUri.path);

      if (match == null) {
        return shelf.Response.notFound(
          '{"error": "Not found"}',
          headers: {'content-type': 'application/json'},
        );
      }

      if (match.delayMs > 0) {
        await Future.delayed(Duration(milliseconds: match.delayMs));
      }

      return shelf.Response(
        match.statusCode,
        body: match.body ?? '{"status": "ok"}',
        headers: {'content-type': 'application/json', ...match.headers},
      );
    }

    try {
      _server = await shelf_io.serve(handler, 'localhost', port);
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
