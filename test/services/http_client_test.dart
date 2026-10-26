import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/http/http_client.dart';
import 'package:dbug/core/constants/app_constants.dart';

void main() {
  group('HttpResponse', () {
    test('isSuccess returns true for 2xx status codes', () {
      expect(const HttpResponse(statusCode: 200, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isTrue);
      expect(const HttpResponse(statusCode: 201, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isTrue);
      expect(const HttpResponse(statusCode: 299, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isTrue);
    });

    test('isSuccess returns false for non-2xx status codes', () {
      expect(const HttpResponse(statusCode: 0, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isFalse);
      expect(const HttpResponse(statusCode: 100, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isFalse);
      expect(const HttpResponse(statusCode: 301, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isFalse);
      expect(const HttpResponse(statusCode: 404, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isFalse);
      expect(const HttpResponse(statusCode: 500, headers: {}, body: '', timeMs: 0, sizeBytes: 0).isSuccess, isFalse);
    });

    group('statusCodeLabel', () {
      test('0 -> "No Response"', () {
        expect(const HttpResponse(statusCode: 0, headers: {}, body: '', timeMs: 0, sizeBytes: 0).statusCodeLabel, 'No Response');
      });

      test('200 -> "Success"', () {
        expect(const HttpResponse(statusCode: 200, headers: {}, body: '', timeMs: 0, sizeBytes: 0).statusCodeLabel, 'Success');
      });

      test('301 -> "Redirect"', () {
        expect(const HttpResponse(statusCode: 301, headers: {}, body: '', timeMs: 0, sizeBytes: 0).statusCodeLabel, 'Redirect');
      });

      test('404 -> "Client Error"', () {
        expect(const HttpResponse(statusCode: 404, headers: {}, body: '', timeMs: 0, sizeBytes: 0).statusCodeLabel, 'Client Error');
      });

      test('500 -> "Server Error"', () {
        expect(const HttpResponse(statusCode: 500, headers: {}, body: '', timeMs: 0, sizeBytes: 0).statusCodeLabel, 'Server Error');
      });
    });

    test('headers are preserved', () {
      const resp = HttpResponse(
        statusCode: 200,
        headers: {'content-type': 'application/json', 'x-custom': 'value'},
        body: '{}',
        timeMs: 50,
        sizeBytes: 2,
      );
      expect(resp.headers['content-type'], 'application/json');
      expect(resp.headers['x-custom'], 'value');
    });

    test('body is preserved', () {
      const resp = HttpResponse(
        statusCode: 200,
        headers: {},
        body: '{"key": "value"}',
        timeMs: 100,
        sizeBytes: 16,
      );
      expect(resp.body, '{"key": "value"}');
    });

    test('timeMs and sizeBytes are preserved', () {
      const resp = HttpResponse(
        statusCode: 200,
        headers: {},
        body: '',
        timeMs: 1234,
        sizeBytes: 5678,
      );
      expect(resp.timeMs, 1234);
      expect(resp.sizeBytes, 5678);
    });
  });

  group('DbugHttpClient', () {
    test('default timeout is 30 seconds', () {
      expect(AppConstants.defaultTimeout, const Duration(seconds: 30));
    });

    test('can be instantiated', () {
      final client = DbugHttpClient();
      expect(client, isA<DbugHttpClient>());
      client.dispose();
    });

    test('dio getter returns non-null Dio instance', () {
      final client = DbugHttpClient();
      expect(client.dio, isNotNull);
      client.dispose();
    });
  });

  group('AppConstants', () {
    test('app name is dbug', () {
      expect(AppConstants.appName, 'dbug');
    });

    test('app version matches pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(r'^version:\s*([^\s+]+)', multiLine: true)
          .firstMatch(pubspec)!
          .group(1);
      expect(AppConstants.appVersion, version);
    });

    test('database name is dbug.db', () {
      expect(AppConstants.dbName, 'dbug.db');
    });

    test('database version is 8', () {
      expect(AppConstants.dbVersion, 8);
    });

    test('default mock port is 3001', () {
      expect(AppConstants.defaultMockPort, 3001);
    });
  });

  group('content detection', () {
    test('text-like content types', () {
      for (final ct in [
        'text/html; charset=utf-8',
        'application/json',
        'application/problem+json',
        'application/xml',
        'application/x-yaml',
        'application/javascript',
        'application/x-www-form-urlencoded',
      ]) {
        expect(isTextContentType(ct), isTrue, reason: ct);
      }
      for (final ct in ['image/png', 'application/pdf', 'application/octet-stream', null]) {
        expect(isTextContentType(ct), isFalse, reason: '$ct');
      }
    });

    test('UTF-8 sniffing', () {
      expect(looksLikeUtf8(utf8.encode('héllo')), isTrue);
      expect(looksLikeUtf8(const []), isTrue);
      expect(looksLikeUtf8(const [0xff, 0xfe, 0x00]), isFalse);
    });

    test('fromBytes decodes text and describes binary', () {
      final text = HttpResponse.fromBytes(
          statusCode: 200, headers: {'content-type': 'application/json'}, bytes: utf8.encode('{"é":1}'), timeMs: 1);
      expect(text.body, '{"é":1}');
      expect(text.isBinary, isFalse);
      expect(text.sizeBytes, 8, reason: 'raw byte length (é is 2 bytes), not char count');

      final png = HttpResponse.fromBytes(
          statusCode: 200, headers: {'content-type': 'image/png'}, bytes: const [0x89, 0x50, 0x4e, 0x47], timeMs: 1);
      expect(png.isBinary, isTrue);
      expect(png.body, contains('4 bytes'));
      expect(png.sizeBytes, 4);

      final untyped = HttpResponse.fromBytes(statusCode: 200, headers: {}, bytes: utf8.encode('plain'), timeMs: 1);
      expect(untyped.isBinary, isFalse);
      expect(untyped.body, 'plain');
    });
  });

  group('RedactingLogInterceptor', () {
    test('masks credential-like headers', () {
      final out = RedactingLogInterceptor.redactHeaders({
        'Authorization': 'Bearer x',
        'X-Api-Key': 'k',
        'Cookie': 'c',
        'x-session-id': 's',
        'Accept': 'application/json',
      });
      expect(out['Authorization'], '<redacted>');
      expect(out['X-Api-Key'], '<redacted>');
      expect(out['Cookie'], '<redacted>');
      expect(out['x-session-id'], '<redacted>');
      expect(out['Accept'], 'application/json');
    });

    test('truncates long bodies', () {
      final long = 'a' * 5000;
      final out = RedactingLogInterceptor.truncate(long);
      expect(out.length, lessThan(2200));
      expect(out, contains('more chars'));
      expect(RedactingLogInterceptor.truncate('short'), 'short');
    });
  });

  group('DbugHttpClient against a local server', () {
    late HttpServer server;
    late String base;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = 'http://127.0.0.1:${server.port}';
      server.listen((req) async {
        switch (req.uri.path) {
          case '/json':
            req.response.headers.contentType = ContentType.json;
            req.response.write('{"q":"${req.uri.queryParameters['q']}","auth":"${req.headers.value('authorization')}"}');
          case '/png':
            req.response.headers.contentType = ContentType('image', 'png');
            req.response.add(const [0x89, 0x50, 0x4e, 0x47, 0x00, 0xff]);
          case '/missing':
            req.response.statusCode = 404;
            req.response.headers.contentType = ContentType.json;
            req.response.write('{"error":"nope"}');
          case '/slow':
            await Future.delayed(const Duration(seconds: 5));
            req.response.write('late');
        }
        await req.response.close();
      });
    });

    tearDown(() => server.close(force: true));

    test('sends headers and query params, decodes JSON', () async {
      final client = DbugHttpClient();
      final resp = await client.sendRequest(
        method: 'get',
        url: '$base/json',
        headers: {'Authorization': 'Bearer t'},
        queryParams: {'q': 'a b'},
      );
      expect(resp.statusCode, 200);
      expect(jsonDecode(resp.body), {'q': 'a b', 'auth': 'Bearer t'});
      expect(resp.headers['content-type'], contains('application/json'));
      client.dispose();
    });

    test('binary responses are not decoded', () async {
      final client = DbugHttpClient();
      final resp = await client.sendRequest(method: 'GET', url: '$base/png');
      expect(resp.isBinary, isTrue);
      expect(resp.sizeBytes, 6);
      client.dispose();
    });

    test('4xx is a normal response with its body', () async {
      final client = DbugHttpClient();
      final resp = await client.sendRequest(method: 'GET', url: '$base/missing');
      expect(resp.statusCode, 404);
      expect(resp.body, '{"error":"nope"}');
      client.dispose();
    });

    test('cancellation throws a cancel DioException', () async {
      final client = DbugHttpClient();
      final token = CancelToken();
      final future = client.sendRequest(method: 'GET', url: '$base/slow', cancelToken: token);
      await Future.delayed(const Duration(milliseconds: 100));
      token.cancel('user');
      await expectLater(
        future,
        throwsA(isA<DioException>().having(CancelToken.isCancel, 'isCancel', isTrue)),
      );
      client.dispose();
    });

    test('timeout yields a status-0 response with a message', () async {
      final client = DbugHttpClient(timeout: const Duration(milliseconds: 200));
      final resp = await client.sendRequest(method: 'GET', url: '$base/slow');
      expect(resp.statusCode, 0);
      expect(resp.body, isNotEmpty);
      client.dispose();
    });

    test('connection errors yield a status-0 response', () async {
      final client = DbugHttpClient(timeout: const Duration(seconds: 2));
      final resp = await client.sendRequest(method: 'GET', url: 'http://127.0.0.1:1/');
      expect(resp.statusCode, 0);
      expect(resp.statusCodeLabel, 'No Response');
      client.dispose();
    });
  });
}
