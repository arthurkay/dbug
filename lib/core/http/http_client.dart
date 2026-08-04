import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class DbugHttpClient {
  late final Dio _dio;

  DbugHttpClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: AppConstants.defaultTimeout,
      receiveTimeout: AppConstants.defaultTimeout,
      sendTimeout: AppConstants.defaultTimeout,
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Dio get dio => _dio;

  Future<HttpResponse> sendRequest({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    Map<String, String> queryParams = const {},
    String? body,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final options = Options(
        method: method.toUpperCase(),
        headers: headers.isNotEmpty ? headers : null,
        receiveTimeout: AppConstants.defaultTimeout,
        sendTimeout: AppConstants.defaultTimeout,
        responseType: ResponseType.plain,
      );

      final response = await _dio.request(
        url,
        options: options,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        data: body,
      );

      stopwatch.stop();

      final responseHeaders = <String, String>{};
      response.headers.forEach((key, values) {
        responseHeaders[key] = values.join(', ');
      });

      final bodyString = response.data?.toString() ?? '';
      return HttpResponse(
        statusCode: response.statusCode ?? 0,
        headers: responseHeaders,
        body: bodyString,
        timeMs: stopwatch.elapsedMilliseconds,
        sizeBytes: utf8.encode(bodyString).length,
      );
    } on DioException catch (e) {
      stopwatch.stop();

      final responseHeaders = <String, String>{};
      if (e.response?.headers != null) {
        e.response!.headers.forEach((key, values) {
          responseHeaders[key] = values.join(', ');
        });
      }

      final bodyString = e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      return HttpResponse(
        statusCode: e.response?.statusCode ?? 0,
        headers: responseHeaders,
        body: bodyString,
        timeMs: stopwatch.elapsedMilliseconds,
        sizeBytes: utf8.encode(bodyString).length,
      );
    }
  }

  void dispose() {
    _dio.close();
  }
}

class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final int timeMs;
  final int sizeBytes;

  const HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.timeMs,
    required this.sizeBytes,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  String get statusCodeLabel {
    if (statusCode == 0) return 'No Response';
    if (statusCode >= 200 && statusCode < 300) return 'Success';
    if (statusCode >= 300 && statusCode < 400) return 'Redirect';
    if (statusCode >= 400 && statusCode < 500) return 'Client Error';
    if (statusCode >= 500) return 'Server Error';
    return 'Unknown';
  }
}
