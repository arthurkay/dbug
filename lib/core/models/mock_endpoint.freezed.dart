// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mock_endpoint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MockEndpoint _$MockEndpointFromJson(Map<String, dynamic> json) {
  return _MockEndpoint.fromJson(json);
}

/// @nodoc
mixin _$MockEndpoint {
  String get id => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  int get statusCode => throw _privateConstructorUsedError;
  Map<String, String> get headers => throw _privateConstructorUsedError;
  String? get body => throw _privateConstructorUsedError;
  int get delayMs => throw _privateConstructorUsedError;

  /// Serializes this MockEndpoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MockEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MockEndpointCopyWith<MockEndpoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MockEndpointCopyWith<$Res> {
  factory $MockEndpointCopyWith(
    MockEndpoint value,
    $Res Function(MockEndpoint) then,
  ) = _$MockEndpointCopyWithImpl<$Res, MockEndpoint>;
  @useResult
  $Res call({
    String id,
    String method,
    String path,
    int statusCode,
    Map<String, String> headers,
    String? body,
    int delayMs,
  });
}

/// @nodoc
class _$MockEndpointCopyWithImpl<$Res, $Val extends MockEndpoint>
    implements $MockEndpointCopyWith<$Res> {
  _$MockEndpointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MockEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? method = null,
    Object? path = null,
    Object? statusCode = null,
    Object? headers = null,
    Object? body = freezed,
    Object? delayMs = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
            statusCode: null == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int,
            headers: null == headers
                ? _value.headers
                : headers // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            body: freezed == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String?,
            delayMs: null == delayMs
                ? _value.delayMs
                : delayMs // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MockEndpointImplCopyWith<$Res>
    implements $MockEndpointCopyWith<$Res> {
  factory _$$MockEndpointImplCopyWith(
    _$MockEndpointImpl value,
    $Res Function(_$MockEndpointImpl) then,
  ) = __$$MockEndpointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String method,
    String path,
    int statusCode,
    Map<String, String> headers,
    String? body,
    int delayMs,
  });
}

/// @nodoc
class __$$MockEndpointImplCopyWithImpl<$Res>
    extends _$MockEndpointCopyWithImpl<$Res, _$MockEndpointImpl>
    implements _$$MockEndpointImplCopyWith<$Res> {
  __$$MockEndpointImplCopyWithImpl(
    _$MockEndpointImpl _value,
    $Res Function(_$MockEndpointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MockEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? method = null,
    Object? path = null,
    Object? statusCode = null,
    Object? headers = null,
    Object? body = freezed,
    Object? delayMs = null,
  }) {
    return _then(
      _$MockEndpointImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: null == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int,
        headers: null == headers
            ? _value._headers
            : headers // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        body: freezed == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String?,
        delayMs: null == delayMs
            ? _value.delayMs
            : delayMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MockEndpointImpl implements _MockEndpoint {
  const _$MockEndpointImpl({
    required this.id,
    required this.method,
    required this.path,
    this.statusCode = 200,
    final Map<String, String> headers = const {},
    this.body,
    this.delayMs = 0,
  }) : _headers = headers;

  factory _$MockEndpointImpl.fromJson(Map<String, dynamic> json) =>
      _$$MockEndpointImplFromJson(json);

  @override
  final String id;
  @override
  final String method;
  @override
  final String path;
  @override
  @JsonKey()
  final int statusCode;
  final Map<String, String> _headers;
  @override
  @JsonKey()
  Map<String, String> get headers {
    if (_headers is EqualUnmodifiableMapView) return _headers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_headers);
  }

  @override
  final String? body;
  @override
  @JsonKey()
  final int delayMs;

  @override
  String toString() {
    return 'MockEndpoint(id: $id, method: $method, path: $path, statusCode: $statusCode, headers: $headers, body: $body, delayMs: $delayMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MockEndpointImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            const DeepCollectionEquality().equals(other._headers, _headers) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.delayMs, delayMs) || other.delayMs == delayMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    method,
    path,
    statusCode,
    const DeepCollectionEquality().hash(_headers),
    body,
    delayMs,
  );

  /// Create a copy of MockEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MockEndpointImplCopyWith<_$MockEndpointImpl> get copyWith =>
      __$$MockEndpointImplCopyWithImpl<_$MockEndpointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MockEndpointImplToJson(this);
  }
}

abstract class _MockEndpoint implements MockEndpoint {
  const factory _MockEndpoint({
    required final String id,
    required final String method,
    required final String path,
    final int statusCode,
    final Map<String, String> headers,
    final String? body,
    final int delayMs,
  }) = _$MockEndpointImpl;

  factory _MockEndpoint.fromJson(Map<String, dynamic> json) =
      _$MockEndpointImpl.fromJson;

  @override
  String get id;
  @override
  String get method;
  @override
  String get path;
  @override
  int get statusCode;
  @override
  Map<String, String> get headers;
  @override
  String? get body;
  @override
  int get delayMs;

  /// Create a copy of MockEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MockEndpointImplCopyWith<_$MockEndpointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
