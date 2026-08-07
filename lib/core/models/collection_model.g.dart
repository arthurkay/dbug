// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CollectionImpl _$$CollectionImplFromJson(Map<String, dynamic> json) =>
    _$CollectionImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sourceType: json['sourceType'] as String? ?? 'manual',
      sourceSpecId: json['sourceSpecId'] as String?,
      globalHeaders:
          (json['globalHeaders'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
      authType: json['authType'] as String? ?? 'none',
      authData: json['authData'] as String? ?? '{}',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CollectionImplToJson(_$CollectionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'sourceType': instance.sourceType,
      'sourceSpecId': instance.sourceSpecId,
      'globalHeaders': instance.globalHeaders,
      'authType': instance.authType,
      'authData': instance.authData,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
