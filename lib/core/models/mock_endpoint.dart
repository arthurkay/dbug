import 'package:freezed_annotation/freezed_annotation.dart';

part 'mock_endpoint.freezed.dart';
part 'mock_endpoint.g.dart';

@freezed
class MockEndpoint with _$MockEndpoint {
  const factory MockEndpoint({
    required String id,
    required String method,
    required String path,
    @Default(200) int statusCode,
    @Default({}) Map<String, String> headers,
    String? body,
    @Default(0) int delayMs,
  }) = _MockEndpoint;

  factory MockEndpoint.fromJson(Map<String, dynamic> json) =>
      _$MockEndpointFromJson(json);
}
