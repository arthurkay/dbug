import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class DbugHttpClient {
  late final Dio _dio;

  /// [allowInsecureTls] accepts self-signed / untrusted certificates; meant
  /// for internal and local APIs, off by default.
  DbugHttpClient({
    Duration timeout = AppConstants.defaultTimeout,
    bool allowInsecureTls = false,
  }) {
    _dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
    ));

    if (allowInsecureTls) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () =>
            HttpClient()..badCertificateCallback = (_, _, _) => true,
      );
    }

    if (kDebugMode) {
      _dio.interceptors.add(RedactingLogInterceptor());
    }
  }

  Dio get dio => _dio;

  Future<HttpResponse> sendRequest({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    Map<String, String> queryParams = const {},
    String? body,
    CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.request<List<int>>(
        url,
        options: Options(
          method: method.toUpperCase(),
          headers: headers.isNotEmpty ? headers : null,
          responseType: ResponseType.bytes,
          // Every status is a response to show, not an error.
          validateStatus: (_) => true,
        ),
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        data: body,
        cancelToken: cancelToken,
      );
      stopwatch.stop();
      return HttpResponse.fromBytes(
        statusCode: response.statusCode ?? 0,
        headers: _flattenHeaders(response.headers),
        bytes: response.data ?? const [],
        timeMs: stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      // Cancellation is the caller's decision; let it handle that case.
      if (CancelToken.isCancel(e)) rethrow;

      final data = e.response?.data;
      if (data is List<int>) {
        return HttpResponse.fromBytes(
          statusCode: e.response?.statusCode ?? 0,
          headers: _flattenHeaders(e.response?.headers),
          bytes: data,
          timeMs: stopwatch.elapsedMilliseconds,
        );
      }
      final message = e.message ?? e.error?.toString() ?? 'Unknown error';
      return HttpResponse(
        statusCode: e.response?.statusCode ?? 0,
        headers: _flattenHeaders(e.response?.headers),
        body: message,
        timeMs: stopwatch.elapsedMilliseconds,
        sizeBytes: utf8.encode(message).length,
      );
    }
  }

  static Map<String, String> _flattenHeaders(Headers? headers) {
    final out = <String, String>{};
    headers?.forEach((key, values) => out[key] = values.join(', '));
    return out;
  }

  /// Lets in-flight requests finish (settings changes rebuild the client
  /// mid-request); new requests use the replacement client.
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

  /// True when the body is not text; [body] then holds a short description.
  final bool isBinary;

  /// True when [body] was cut to the history size cap.
  final bool isTruncated;

  const HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.timeMs,
    required this.sizeBytes,
    this.isBinary = false,
    this.isTruncated = false,
  });

  factory HttpResponse.fromBytes({
    required int statusCode,
    required Map<String, String> headers,
    required List<int> bytes,
    required int timeMs,
  }) {
    final contentType = headers['content-type'];
    final textual = isTextContentType(contentType) ||
        (contentType == null && looksLikeUtf8(bytes));
    return HttpResponse(
      statusCode: statusCode,
      headers: headers,
      body: textual
          ? utf8.decode(bytes, allowMalformed: true)
          : '<binary content: ${bytes.length} bytes, ${contentType ?? 'unknown type'}>',
      timeMs: timeMs,
      sizeBytes: bytes.length,
      isBinary: !textual,
    );
  }

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

/// Whether a response with this content type should be shown as text.
bool isTextContentType(String? contentType) {
  if (contentType == null) return false;
  final ct = contentType.toLowerCase();
  return ct.startsWith('text/') ||
      ct.contains('json') ||
      ct.contains('xml') ||
      ct.contains('yaml') ||
      ct.contains('javascript') ||
      ct.contains('x-www-form-urlencoded') ||
      ct.contains('graphql');
}

/// True when [bytes] decode as strict UTF-8 (empty counts as text).
bool looksLikeUtf8(List<int> bytes) {
  try {
    utf8.decode(bytes);
    return true;
  } on FormatException {
    return false;
  }
}

/// Debug-only request/response logger that never prints credentials and
/// keeps bodies short.
class RedactingLogInterceptor extends Interceptor {
  static const maxBodyChars = 2048;
  static final _sensitive =
      RegExp(r'auth|token|secret|key|cookie|session|password', caseSensitive: false);

  final void Function(String) log;

  RedactingLogInterceptor({void Function(String)? log}) : log = log ?? debugPrint;

  static Map<String, String> redactHeaders(Map<String, dynamic> headers) {
    return headers.map((k, v) =>
        MapEntry(k, _sensitive.hasMatch(k) ? '<redacted>' : v.toString()));
  }

  static String truncate(String text) => text.length <= maxBodyChars
      ? text
      : '${text.substring(0, maxBodyChars)}… (${text.length - maxBodyChars} more chars)';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('→ ${options.method} ${options.uri}');
    log('  headers: ${redactHeaders(options.headers)}');
    if (options.data != null) log('  body: ${truncate(options.data.toString())}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    final size = data is List<int> ? data.length : null;
    log('← ${response.statusCode} ${response.requestOptions.uri}'
        '${size != null ? ' ($size bytes)' : ''}');
    log('  headers: ${redactHeaders(response.headers.map)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('✕ ${err.requestOptions.method} ${err.requestOptions.uri}: ${err.type} ${err.message ?? ''}');
    handler.next(err);
  }
}
