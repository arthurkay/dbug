// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HistoryEntryImpl _$$HistoryEntryImplFromJson(Map<String, dynamic> json) =>
    _$HistoryEntryImpl(
      id: json['id'] as String,
      requestId: json['requestId'] as String?,
      method: json['method'] as String,
      url: json['url'] as String,
      statusCode: (json['statusCode'] as num?)?.toInt(),
      responseTimeMs: (json['responseTimeMs'] as num?)?.toInt(),
      responseSize: (json['responseSize'] as num?)?.toInt(),
      responseBody: json['responseBody'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );

Map<String, dynamic> _$$HistoryEntryImplToJson(_$HistoryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requestId': instance.requestId,
      'method': instance.method,
      'url': instance.url,
      'statusCode': instance.statusCode,
      'responseTimeMs': instance.responseTimeMs,
      'responseSize': instance.responseSize,
      'responseBody': instance.responseBody,
      'sentAt': instance.sentAt.toIso8601String(),
    };
