// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HistoryEntry _$HistoryEntryFromJson(Map<String, dynamic> json) {
  return _HistoryEntry.fromJson(json);
}

/// @nodoc
mixin _$HistoryEntry {
  String get id => throw _privateConstructorUsedError;
  String? get requestId => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  int? get statusCode => throw _privateConstructorUsedError;
  int? get responseTimeMs => throw _privateConstructorUsedError;
  int? get responseSize => throw _privateConstructorUsedError;
  String? get responseBody => throw _privateConstructorUsedError;
  DateTime get sentAt => throw _privateConstructorUsedError;

  /// Serializes this HistoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HistoryEntryCopyWith<HistoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HistoryEntryCopyWith<$Res> {
  factory $HistoryEntryCopyWith(
    HistoryEntry value,
    $Res Function(HistoryEntry) then,
  ) = _$HistoryEntryCopyWithImpl<$Res, HistoryEntry>;
  @useResult
  $Res call({
    String id,
    String? requestId,
    String method,
    String url,
    int? statusCode,
    int? responseTimeMs,
    int? responseSize,
    String? responseBody,
    DateTime sentAt,
  });
}

/// @nodoc
class _$HistoryEntryCopyWithImpl<$Res, $Val extends HistoryEntry>
    implements $HistoryEntryCopyWith<$Res> {
  _$HistoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requestId = freezed,
    Object? method = null,
    Object? url = null,
    Object? statusCode = freezed,
    Object? responseTimeMs = freezed,
    Object? responseSize = freezed,
    Object? responseBody = freezed,
    Object? sentAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            requestId: freezed == requestId
                ? _value.requestId
                : requestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            statusCode: freezed == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int?,
            responseTimeMs: freezed == responseTimeMs
                ? _value.responseTimeMs
                : responseTimeMs // ignore: cast_nullable_to_non_nullable
                      as int?,
            responseSize: freezed == responseSize
                ? _value.responseSize
                : responseSize // ignore: cast_nullable_to_non_nullable
                      as int?,
            responseBody: freezed == responseBody
                ? _value.responseBody
                : responseBody // ignore: cast_nullable_to_non_nullable
                      as String?,
            sentAt: null == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HistoryEntryImplCopyWith<$Res>
    implements $HistoryEntryCopyWith<$Res> {
  factory _$$HistoryEntryImplCopyWith(
    _$HistoryEntryImpl value,
    $Res Function(_$HistoryEntryImpl) then,
  ) = __$$HistoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? requestId,
    String method,
    String url,
    int? statusCode,
    int? responseTimeMs,
    int? responseSize,
    String? responseBody,
    DateTime sentAt,
  });
}

/// @nodoc
class __$$HistoryEntryImplCopyWithImpl<$Res>
    extends _$HistoryEntryCopyWithImpl<$Res, _$HistoryEntryImpl>
    implements _$$HistoryEntryImplCopyWith<$Res> {
  __$$HistoryEntryImplCopyWithImpl(
    _$HistoryEntryImpl _value,
    $Res Function(_$HistoryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? requestId = freezed,
    Object? method = null,
    Object? url = null,
    Object? statusCode = freezed,
    Object? responseTimeMs = freezed,
    Object? responseSize = freezed,
    Object? responseBody = freezed,
    Object? sentAt = null,
  }) {
    return _then(
      _$HistoryEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        requestId: freezed == requestId
            ? _value.requestId
            : requestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: freezed == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int?,
        responseTimeMs: freezed == responseTimeMs
            ? _value.responseTimeMs
            : responseTimeMs // ignore: cast_nullable_to_non_nullable
                  as int?,
        responseSize: freezed == responseSize
            ? _value.responseSize
            : responseSize // ignore: cast_nullable_to_non_nullable
                  as int?,
        responseBody: freezed == responseBody
            ? _value.responseBody
            : responseBody // ignore: cast_nullable_to_non_nullable
                  as String?,
        sentAt: null == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HistoryEntryImpl implements _HistoryEntry {
  const _$HistoryEntryImpl({
    required this.id,
    this.requestId,
    required this.method,
    required this.url,
    this.statusCode,
    this.responseTimeMs,
    this.responseSize,
    this.responseBody,
    required this.sentAt,
  });

  factory _$HistoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$HistoryEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String? requestId;
  @override
  final String method;
  @override
  final String url;
  @override
  final int? statusCode;
  @override
  final int? responseTimeMs;
  @override
  final int? responseSize;
  @override
  final String? responseBody;
  @override
  final DateTime sentAt;

  @override
  String toString() {
    return 'HistoryEntry(id: $id, requestId: $requestId, method: $method, url: $url, statusCode: $statusCode, responseTimeMs: $responseTimeMs, responseSize: $responseSize, responseBody: $responseBody, sentAt: $sentAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HistoryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.responseTimeMs, responseTimeMs) ||
                other.responseTimeMs == responseTimeMs) &&
            (identical(other.responseSize, responseSize) ||
                other.responseSize == responseSize) &&
            (identical(other.responseBody, responseBody) ||
                other.responseBody == responseBody) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    requestId,
    method,
    url,
    statusCode,
    responseTimeMs,
    responseSize,
    responseBody,
    sentAt,
  );

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HistoryEntryImplCopyWith<_$HistoryEntryImpl> get copyWith =>
      __$$HistoryEntryImplCopyWithImpl<_$HistoryEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HistoryEntryImplToJson(this);
  }
}

abstract class _HistoryEntry implements HistoryEntry {
  const factory _HistoryEntry({
    required final String id,
    final String? requestId,
    required final String method,
    required final String url,
    final int? statusCode,
    final int? responseTimeMs,
    final int? responseSize,
    final String? responseBody,
    required final DateTime sentAt,
  }) = _$HistoryEntryImpl;

  factory _HistoryEntry.fromJson(Map<String, dynamic> json) =
      _$HistoryEntryImpl.fromJson;

  @override
  String get id;
  @override
  String? get requestId;
  @override
  String get method;
  @override
  String get url;
  @override
  int? get statusCode;
  @override
  int? get responseTimeMs;
  @override
  int? get responseSize;
  @override
  String? get responseBody;
  @override
  DateTime get sentAt;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryEntryImplCopyWith<_$HistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
