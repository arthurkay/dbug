// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Collection _$CollectionFromJson(Map<String, dynamic> json) {
  return _Collection.fromJson(json);
}

/// @nodoc
mixin _$Collection {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get sourceType => throw _privateConstructorUsedError;
  String? get sourceSpecId => throw _privateConstructorUsedError;
  Map<String, String> get globalHeaders => throw _privateConstructorUsedError;
  String get authType => throw _privateConstructorUsedError;
  String get authData => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Collection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Collection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CollectionCopyWith<Collection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollectionCopyWith<$Res> {
  factory $CollectionCopyWith(
    Collection value,
    $Res Function(Collection) then,
  ) = _$CollectionCopyWithImpl<$Res, Collection>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String sourceType,
    String? sourceSpecId,
    Map<String, String> globalHeaders,
    String authType,
    String authData,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$CollectionCopyWithImpl<$Res, $Val extends Collection>
    implements $CollectionCopyWith<$Res> {
  _$CollectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Collection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? sourceType = null,
    Object? sourceSpecId = freezed,
    Object? globalHeaders = null,
    Object? authType = null,
    Object? authData = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            sourceType: null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceSpecId: freezed == sourceSpecId
                ? _value.sourceSpecId
                : sourceSpecId // ignore: cast_nullable_to_non_nullable
                      as String?,
            globalHeaders: null == globalHeaders
                ? _value.globalHeaders
                : globalHeaders // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            authType: null == authType
                ? _value.authType
                : authType // ignore: cast_nullable_to_non_nullable
                      as String,
            authData: null == authData
                ? _value.authData
                : authData // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CollectionImplCopyWith<$Res>
    implements $CollectionCopyWith<$Res> {
  factory _$$CollectionImplCopyWith(
    _$CollectionImpl value,
    $Res Function(_$CollectionImpl) then,
  ) = __$$CollectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String sourceType,
    String? sourceSpecId,
    Map<String, String> globalHeaders,
    String authType,
    String authData,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$CollectionImplCopyWithImpl<$Res>
    extends _$CollectionCopyWithImpl<$Res, _$CollectionImpl>
    implements _$$CollectionImplCopyWith<$Res> {
  __$$CollectionImplCopyWithImpl(
    _$CollectionImpl _value,
    $Res Function(_$CollectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Collection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? sourceType = null,
    Object? sourceSpecId = freezed,
    Object? globalHeaders = null,
    Object? authType = null,
    Object? authData = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$CollectionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        sourceType: null == sourceType
            ? _value.sourceType
            : sourceType // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceSpecId: freezed == sourceSpecId
            ? _value.sourceSpecId
            : sourceSpecId // ignore: cast_nullable_to_non_nullable
                  as String?,
        globalHeaders: null == globalHeaders
            ? _value._globalHeaders
            : globalHeaders // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        authType: null == authType
            ? _value.authType
            : authType // ignore: cast_nullable_to_non_nullable
                  as String,
        authData: null == authData
            ? _value.authData
            : authData // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CollectionImpl implements _Collection {
  const _$CollectionImpl({
    required this.id,
    required this.name,
    this.description,
    this.sourceType = 'manual',
    this.sourceSpecId,
    final Map<String, String> globalHeaders = const {},
    this.authType = 'none',
    this.authData = '{}',
    required this.createdAt,
    required this.updatedAt,
  }) : _globalHeaders = globalHeaders;

  factory _$CollectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CollectionImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey()
  final String sourceType;
  @override
  final String? sourceSpecId;
  final Map<String, String> _globalHeaders;
  @override
  @JsonKey()
  Map<String, String> get globalHeaders {
    if (_globalHeaders is EqualUnmodifiableMapView) return _globalHeaders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_globalHeaders);
  }

  @override
  @JsonKey()
  final String authType;
  @override
  @JsonKey()
  final String authData;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Collection(id: $id, name: $name, description: $description, sourceType: $sourceType, sourceSpecId: $sourceSpecId, globalHeaders: $globalHeaders, authType: $authType, authData: $authData, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.sourceSpecId, sourceSpecId) ||
                other.sourceSpecId == sourceSpecId) &&
            const DeepCollectionEquality().equals(
              other._globalHeaders,
              _globalHeaders,
            ) &&
            (identical(other.authType, authType) ||
                other.authType == authType) &&
            (identical(other.authData, authData) ||
                other.authData == authData) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    sourceType,
    sourceSpecId,
    const DeepCollectionEquality().hash(_globalHeaders),
    authType,
    authData,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Collection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollectionImplCopyWith<_$CollectionImpl> get copyWith =>
      __$$CollectionImplCopyWithImpl<_$CollectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CollectionImplToJson(this);
  }
}

abstract class _Collection implements Collection {
  const factory _Collection({
    required final String id,
    required final String name,
    final String? description,
    final String sourceType,
    final String? sourceSpecId,
    final Map<String, String> globalHeaders,
    final String authType,
    final String authData,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$CollectionImpl;

  factory _Collection.fromJson(Map<String, dynamic> json) =
      _$CollectionImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get sourceType;
  @override
  String? get sourceSpecId;
  @override
  Map<String, String> get globalHeaders;
  @override
  String get authType;
  @override
  String get authData;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Collection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollectionImplCopyWith<_$CollectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
