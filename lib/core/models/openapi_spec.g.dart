// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openapi_spec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OpenApiSpecImpl _$$OpenApiSpecImplFromJson(Map<String, dynamic> json) =>
    _$OpenApiSpecImpl(
      id: json['id'] as String,
      title: json['title'] as String?,
      version: json['version'] as String?,
      baseUrl: json['baseUrl'] as String?,
      rawContent: json['rawContent'] as String,
      endpoints:
          (json['endpoints'] as List<dynamic>?)
              ?.map((e) => OpenApiEndpoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sourceType: json['sourceType'] as String,
      sourceUrl: json['sourceUrl'] as String?,
      importedAt: DateTime.parse(json['importedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$OpenApiSpecImplToJson(_$OpenApiSpecImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'version': instance.version,
      'baseUrl': instance.baseUrl,
      'rawContent': instance.rawContent,
      'endpoints': instance.endpoints.map((e) => e.toJson()).toList(),
      'sourceType': instance.sourceType,
      'sourceUrl': instance.sourceUrl,
      'importedAt': instance.importedAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$OpenApiEndpointImpl _$$OpenApiEndpointImplFromJson(
  Map<String, dynamic> json,
) => _$OpenApiEndpointImpl(
  path: json['path'] as String,
  method: json['method'] as String,
  summary: json['summary'] as String?,
  description: json['description'] as String?,
  operationId: json['operationId'] as String?,
  parameters:
      (json['parameters'] as List<dynamic>?)
          ?.map((e) => OpenApiParameter.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  requestBodySchema: json['requestBodySchema'] == null
      ? null
      : OpenApiSchema.fromJson(
          json['requestBodySchema'] as Map<String, dynamic>,
        ),
  responseSchemas: (json['responseSchemas'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, OpenApiSchema.fromJson(e as Map<String, dynamic>)),
  ),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$OpenApiEndpointImplToJson(
  _$OpenApiEndpointImpl instance,
) => <String, dynamic>{
  'path': instance.path,
  'method': instance.method,
  'summary': instance.summary,
  'description': instance.description,
  'operationId': instance.operationId,
  'parameters': instance.parameters.map((e) => e.toJson()).toList(),
  'requestBodySchema': instance.requestBodySchema?.toJson(),
  'responseSchemas': instance.responseSchemas?.map((k, e) => MapEntry(k, e.toJson())),
  'tags': instance.tags,
};

_$OpenApiParameterImpl _$$OpenApiParameterImplFromJson(
  Map<String, dynamic> json,
) => _$OpenApiParameterImpl(
  name: json['name'] as String,
  location: json['location'] as String,
  description: json['description'] as String?,
  required: json['required'] as bool? ?? false,
  type: json['type'] as String?,
  schemaType: json['schemaType'] as String?,
);

Map<String, dynamic> _$$OpenApiParameterImplToJson(
  _$OpenApiParameterImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'location': instance.location,
  'description': instance.description,
  'required': instance.required,
  'type': instance.type,
  'schemaType': instance.schemaType,
};

_$OpenApiSchemaImpl _$$OpenApiSchemaImplFromJson(Map<String, dynamic> json) =>
    _$OpenApiSchemaImpl(
      type: json['type'] as String?,
      format: json['format'] as String?,
      ref: json['ref'] as String?,
      description: json['description'] as String?,
      properties:
          (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, OpenApiSchema.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      requiredFields:
          (json['requiredFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      items: json['items'] == null
          ? null
          : OpenApiSchema.fromJson(json['items'] as Map<String, dynamic>),
      enumValues:
          (json['enumValues'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$OpenApiSchemaImplToJson(_$OpenApiSchemaImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'format': instance.format,
      'ref': instance.ref,
      'description': instance.description,
      'properties': instance.properties.map((k, e) => MapEntry(k, e.toJson())),
      'requiredFields': instance.requiredFields,
      'items': instance.items?.toJson(),
      'enumValues': instance.enumValues,
    };
