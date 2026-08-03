import 'package:freezed_annotation/freezed_annotation.dart';

part 'openapi_spec.freezed.dart';
part 'openapi_spec.g.dart';

@freezed
class OpenApiSpec with _$OpenApiSpec {
  const factory OpenApiSpec({
    required String id,
    String? title,
    String? version,
    String? baseUrl,
    required String rawContent,
    @Default([]) List<OpenApiEndpoint> endpoints,
    required String sourceType,
    String? sourceUrl,
    required DateTime importedAt,
    DateTime? updatedAt,
  }) = _OpenApiSpec;

  factory OpenApiSpec.fromJson(Map<String, dynamic> json) =>
      _$OpenApiSpecFromJson(json);
}

@freezed
class OpenApiEndpoint with _$OpenApiEndpoint {
  const factory OpenApiEndpoint({
    required String path,
    required String method,
    String? summary,
    String? description,
    String? operationId,
    @Default([]) List<OpenApiParameter> parameters,
    OpenApiSchema? requestBodySchema,
    Map<String, OpenApiSchema>? responseSchemas,
    @Default([]) List<String> tags,
  }) = _OpenApiEndpoint;

  factory OpenApiEndpoint.fromJson(Map<String, dynamic> json) =>
      _$OpenApiEndpointFromJson(json);
}

@freezed
class OpenApiParameter with _$OpenApiParameter {
  const factory OpenApiParameter({
    required String name,
    required String location,
    String? description,
    @Default(false) bool required,
    String? type,
    String? schemaType,
  }) = _OpenApiParameter;

  factory OpenApiParameter.fromJson(Map<String, dynamic> json) =>
      _$OpenApiParameterFromJson(json);
}

@freezed
class OpenApiSchema with _$OpenApiSchema {
  const factory OpenApiSchema({
    String? type,
    String? format,
    String? ref,
    String? description,
    @Default({}) Map<String, OpenApiSchema> properties,
    @Default([]) List<String> requiredFields,
    OpenApiSchema? items,
    @Default([]) List<String> enumValues,
  }) = _OpenApiSchema;

  factory OpenApiSchema.fromJson(Map<String, dynamic> json) =>
      _$OpenApiSchemaFromJson(json);
}
