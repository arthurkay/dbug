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

    test('app version is 0.0.9', () {
      expect(AppConstants.appVersion, '0.0.9');
    });

    test('database name is dbug.db', () {
      expect(AppConstants.dbName, 'dbug.db');
    });

    test('database version is 5', () {
      expect(AppConstants.dbVersion, 5);
    });

    test('default mock port is 3001', () {
      expect(AppConstants.defaultMockPort, 3001);
    });
  });
}
