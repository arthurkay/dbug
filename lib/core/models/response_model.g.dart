// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ResponseModelImpl _$$ResponseModelImplFromJson(Map<String, dynamic> json) =>
    _$ResponseModelImpl(
      statusCode: (json['statusCode'] as num).toInt(),
      headers: Map<String, String>.from(json['headers'] as Map),
      body: json['body'] as String,
      timeMs: (json['timeMs'] as num).toInt(),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
    );

Map<String, dynamic> _$$ResponseModelImplToJson(_$ResponseModelImpl instance) =>
    <String, dynamic>{
      'statusCode': instance.statusCode,
      'headers': instance.headers,
      'body': instance.body,
      'timeMs': instance.timeMs,
      'sizeBytes': instance.sizeBytes,
    };
