import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

@freezed
class RequestModel with _$RequestModel {
  const factory RequestModel({
    required String id,
    String? collectionId,
    required String name,
    required String method,
    required String url,
    @Default({}) Map<String, String> headers,
    String? bodyType,
    String? body,
    @Default({}) Map<String, String> queryParams,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RequestModel;

  factory RequestModel.fromJson(Map<String, dynamic> json) =>
      _$RequestModelFromJson(json);
}
