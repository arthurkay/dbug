// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_endpoint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MockEndpointImpl _$$MockEndpointImplFromJson(Map<String, dynamic> json) =>
    _$MockEndpointImpl(
      id: json['id'] as String,
      method: json['method'] as String,
      path: json['path'] as String,
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      headers:
          (json['headers'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      body: json['body'] as String?,
      delayMs: (json['delayMs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MockEndpointImplToJson(_$MockEndpointImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'method': instance.method,
      'path': instance.path,
      'statusCode': instance.statusCode,
      'headers': instance.headers,
      'body': instance.body,
      'delayMs': instance.delayMs,
    };
