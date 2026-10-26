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
  String? get requestName => throw _privateConstructorUsedError;
  String? get collectionId => throw _privateConstructorUsedError;
  String get headers => throw _privateConstructorUsedError;
  String get collectionHeaders => throw _privateConstructorUsedError;
  String? get body => throw _privateConstructorUsedError;
  String? get bodyType => throw _privateConstructorUsedError;
  String get queryParams => throw _privateConstructorUsedError;
  String get authType => throw _privateConstructorUsedError;
  String get authData => throw _privateConstructorUsedError;

  /// The URL actually sent (variables substituted). [url] keeps the raw
  /// `{{var}}` template so replaying an entry stays environment-agnostic.
  String? get resolvedUrl => throw _privateConstructorUsedError;

  /// Response headers as a JSON object string.
  String get responseHeaders => throw _privateConstructorUsedError;

  /// True when [responseBody] was cut to the history size cap.
  bool get responseTruncated => throw _privateConstructorUsedError;

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
    String? requestName,
    String? collectionId,
    String headers,
    String collectionHeaders,
    String? body,
    String? bodyType,
    String queryParams,
    String authType,
    String authData,
    String? resolvedUrl,
    String responseHeaders,
    bool responseTruncated,
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
    Object? requestName = freezed,
    Object? collectionId = freezed,
    Object? headers = null,
    Object? collectionHeaders = null,
    Object? body = freezed,
    Object? bodyType = freezed,
    Object? queryParams = null,
    Object? authType = null,
    Object? authData = null,
    Object? resolvedUrl = freezed,
    Object? responseHeaders = null,
    Object? responseTruncated = null,
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
            requestName: freezed == requestName
                ? _value.requestName
                : requestName // ignore: cast_nullable_to_non_nullable
                      as String?,
            collectionId: freezed == collectionId
                ? _value.collectionId
                : collectionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            headers: null == headers
                ? _value.headers
                : headers // ignore: cast_nullable_to_non_nullable
                      as String,
            collectionHeaders: null == collectionHeaders
                ? _value.collectionHeaders
                : collectionHeaders // ignore: cast_nullable_to_non_nullable
                      as String,
            body: freezed == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String?,
            bodyType: freezed == bodyType
                ? _value.bodyType
                : bodyType // ignore: cast_nullable_to_non_nullable
                      as String?,
            queryParams: null == queryParams
                ? _value.queryParams
                : queryParams // ignore: cast_nullable_to_non_nullable
                      as String,
            authType: null == authType
                ? _value.authType
                : authType // ignore: cast_nullable_to_non_nullable
                      as String,
            authData: null == authData
                ? _value.authData
                : authData // ignore: cast_nullable_to_non_nullable
                      as String,
            resolvedUrl: freezed == resolvedUrl
                ? _value.resolvedUrl
                : resolvedUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            responseHeaders: null == responseHeaders
                ? _value.responseHeaders
                : responseHeaders // ignore: cast_nullable_to_non_nullable
                      as String,
            responseTruncated: null == responseTruncated
                ? _value.responseTruncated
                : responseTruncated // ignore: cast_nullable_to_non_nullable
                      as bool,
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
    String? requestName,
    String? collectionId,
    String headers,
    String collectionHeaders,
    String? body,
    String? bodyType,
    String queryParams,
    String authType,
    String authData,
    String? resolvedUrl,
    String responseHeaders,
    bool responseTruncated,
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
    Object? requestName = freezed,
    Object? collectionId = freezed,
    Object? headers = null,
    Object? collectionHeaders = null,
    Object? body = freezed,
    Object? bodyType = freezed,
    Object? queryParams = null,
    Object? authType = null,
    Object? authData = null,
    Object? resolvedUrl = freezed,
    Object? responseHeaders = null,
    Object? responseTruncated = null,
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
        requestName: freezed == requestName
            ? _value.requestName
            : requestName // ignore: cast_nullable_to_non_nullable
                  as String?,
        collectionId: freezed == collectionId
            ? _value.collectionId
            : collectionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        headers: null == headers
            ? _value.headers
            : headers // ignore: cast_nullable_to_non_nullable
                  as String,
        collectionHeaders: null == collectionHeaders
            ? _value.collectionHeaders
            : collectionHeaders // ignore: cast_nullable_to_non_nullable
                  as String,
        body: freezed == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String?,
        bodyType: freezed == bodyType
            ? _value.bodyType
            : bodyType // ignore: cast_nullable_to_non_nullable
                  as String?,
        queryParams: null == queryParams
            ? _value.queryParams
            : queryParams // ignore: cast_nullable_to_non_nullable
                  as String,
        authType: null == authType
            ? _value.authType
            : authType // ignore: cast_nullable_to_non_nullable
                  as String,
        authData: null == authData
            ? _value.authData
            : authData // ignore: cast_nullable_to_non_nullable
                  as String,
        resolvedUrl: freezed == resolvedUrl
            ? _value.resolvedUrl
            : resolvedUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        responseHeaders: null == responseHeaders
            ? _value.responseHeaders
            : responseHeaders // ignore: cast_nullable_to_non_nullable
                  as String,
        responseTruncated: null == responseTruncated
            ? _value.responseTruncated
            : responseTruncated // ignore: cast_nullable_to_non_nullable
                  as bool,
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
    this.requestName,
    this.collectionId,
    this.headers = '{}',
    this.collectionHeaders = '{}',
    this.body,
    this.bodyType,
    this.queryParams = '{}',
    this.authType = 'none',
    this.authData = '{}',
    this.resolvedUrl,
    this.responseHeaders = '{}',
    this.responseTruncated = false,
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
  final String? requestName;
  @override
  final String? collectionId;
  @override
  @JsonKey()
  final String headers;
  @override
  @JsonKey()
  final String collectionHeaders;
  @override
  final String? body;
  @override
  final String? bodyType;
  @override
  @JsonKey()
  final String queryParams;
  @override
  @JsonKey()
  final String authType;
  @override
  @JsonKey()
  final String authData;

  /// The URL actually sent (variables substituted). [url] keeps the raw
  /// `{{var}}` template so replaying an entry stays environment-agnostic.
  @override
  final String? resolvedUrl;

  /// Response headers as a JSON object string.
  @override
  @JsonKey()
  final String responseHeaders;

  /// True when [responseBody] was cut to the history size cap.
  @override
  @JsonKey()
  final bool responseTruncated;

  @override
  String toString() {
    return 'HistoryEntry(id: $id, requestId: $requestId, method: $method, url: $url, statusCode: $statusCode, responseTimeMs: $responseTimeMs, responseSize: $responseSize, responseBody: $responseBody, sentAt: $sentAt, requestName: $requestName, collectionId: $collectionId, headers: $headers, collectionHeaders: $collectionHeaders, body: $body, bodyType: $bodyType, queryParams: $queryParams, authType: $authType, authData: $authData, resolvedUrl: $resolvedUrl, responseHeaders: $responseHeaders, responseTruncated: $responseTruncated)';
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
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt) &&
            (identical(other.requestName, requestName) ||
                other.requestName == requestName) &&
            (identical(other.collectionId, collectionId) ||
                other.collectionId == collectionId) &&
            (identical(other.headers, headers) || other.headers == headers) &&
            (identical(other.collectionHeaders, collectionHeaders) ||
                other.collectionHeaders == collectionHeaders) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.bodyType, bodyType) ||
                other.bodyType == bodyType) &&
            (identical(other.queryParams, queryParams) ||
                other.queryParams == queryParams) &&
            (identical(other.authType, authType) ||
                other.authType == authType) &&
            (identical(other.authData, authData) ||
                other.authData == authData) &&
            (identical(other.resolvedUrl, resolvedUrl) ||
                other.resolvedUrl == resolvedUrl) &&
            (identical(other.responseHeaders, responseHeaders) ||
                other.responseHeaders == responseHeaders) &&
            (identical(other.responseTruncated, responseTruncated) ||
                other.responseTruncated == responseTruncated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
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
    requestName,
    collectionId,
    headers,
    collectionHeaders,
    body,
    bodyType,
    queryParams,
    authType,
    authData,
    resolvedUrl,
    responseHeaders,
    responseTruncated,
  ]);

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
    final String? requestName,
    final String? collectionId,
    final String headers,
    final String collectionHeaders,
    final String? body,
    final String? bodyType,
    final String queryParams,
    final String authType,
    final String authData,
    final String? resolvedUrl,
    final String responseHeaders,
    final bool responseTruncated,
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
  @override
  String? get requestName;
  @override
  String? get collectionId;
  @override
  String get headers;
  @override
  String get collectionHeaders;
  @override
  String? get body;
  @override
  String? get bodyType;
  @override
  String get queryParams;
  @override
  String get authType;
  @override
  String get authData;

  /// The URL actually sent (variables substituted). [url] keeps the raw
  /// `{{var}}` template so replaying an entry stays environment-agnostic.
  @override
  String? get resolvedUrl;

  /// Response headers as a JSON object string.
  @override
  String get responseHeaders;

  /// True when [responseBody] was cut to the history size cap.
  @override
  bool get responseTruncated;

  /// Create a copy of HistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HistoryEntryImplCopyWith<_$HistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
