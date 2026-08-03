// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'openapi_spec.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OpenApiSpec _$OpenApiSpecFromJson(Map<String, dynamic> json) {
  return _OpenApiSpec.fromJson(json);
}

/// @nodoc
mixin _$OpenApiSpec {
  String get id => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get version => throw _privateConstructorUsedError;
  String? get baseUrl => throw _privateConstructorUsedError;
  String get rawContent => throw _privateConstructorUsedError;
  List<OpenApiEndpoint> get endpoints => throw _privateConstructorUsedError;
  String get sourceType => throw _privateConstructorUsedError;
  String? get sourceUrl => throw _privateConstructorUsedError;
  DateTime get importedAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OpenApiSpec to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpenApiSpec
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpenApiSpecCopyWith<OpenApiSpec> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpenApiSpecCopyWith<$Res> {
  factory $OpenApiSpecCopyWith(
    OpenApiSpec value,
    $Res Function(OpenApiSpec) then,
  ) = _$OpenApiSpecCopyWithImpl<$Res, OpenApiSpec>;
  @useResult
  $Res call({
    String id,
    String? title,
    String? version,
    String? baseUrl,
    String rawContent,
    List<OpenApiEndpoint> endpoints,
    String sourceType,
    String? sourceUrl,
    DateTime importedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$OpenApiSpecCopyWithImpl<$Res, $Val extends OpenApiSpec>
    implements $OpenApiSpecCopyWith<$Res> {
  _$OpenApiSpecCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpenApiSpec
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? version = freezed,
    Object? baseUrl = freezed,
    Object? rawContent = null,
    Object? endpoints = null,
    Object? sourceType = null,
    Object? sourceUrl = freezed,
    Object? importedAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            version: freezed == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as String?,
            baseUrl: freezed == baseUrl
                ? _value.baseUrl
                : baseUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            rawContent: null == rawContent
                ? _value.rawContent
                : rawContent // ignore: cast_nullable_to_non_nullable
                      as String,
            endpoints: null == endpoints
                ? _value.endpoints
                : endpoints // ignore: cast_nullable_to_non_nullable
                      as List<OpenApiEndpoint>,
            sourceType: null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                      as String,
            sourceUrl: freezed == sourceUrl
                ? _value.sourceUrl
                : sourceUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            importedAt: null == importedAt
                ? _value.importedAt
                : importedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OpenApiSpecImplCopyWith<$Res>
    implements $OpenApiSpecCopyWith<$Res> {
  factory _$$OpenApiSpecImplCopyWith(
    _$OpenApiSpecImpl value,
    $Res Function(_$OpenApiSpecImpl) then,
  ) = __$$OpenApiSpecImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? title,
    String? version,
    String? baseUrl,
    String rawContent,
    List<OpenApiEndpoint> endpoints,
    String sourceType,
    String? sourceUrl,
    DateTime importedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$OpenApiSpecImplCopyWithImpl<$Res>
    extends _$OpenApiSpecCopyWithImpl<$Res, _$OpenApiSpecImpl>
    implements _$$OpenApiSpecImplCopyWith<$Res> {
  __$$OpenApiSpecImplCopyWithImpl(
    _$OpenApiSpecImpl _value,
    $Res Function(_$OpenApiSpecImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpenApiSpec
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? version = freezed,
    Object? baseUrl = freezed,
    Object? rawContent = null,
    Object? endpoints = null,
    Object? sourceType = null,
    Object? sourceUrl = freezed,
    Object? importedAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$OpenApiSpecImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        version: freezed == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String?,
        baseUrl: freezed == baseUrl
            ? _value.baseUrl
            : baseUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        rawContent: null == rawContent
            ? _value.rawContent
            : rawContent // ignore: cast_nullable_to_non_nullable
                  as String,
        endpoints: null == endpoints
            ? _value._endpoints
            : endpoints // ignore: cast_nullable_to_non_nullable
                  as List<OpenApiEndpoint>,
        sourceType: null == sourceType
            ? _value.sourceType
            : sourceType // ignore: cast_nullable_to_non_nullable
                  as String,
        sourceUrl: freezed == sourceUrl
            ? _value.sourceUrl
            : sourceUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        importedAt: null == importedAt
            ? _value.importedAt
            : importedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpenApiSpecImpl implements _OpenApiSpec {
  const _$OpenApiSpecImpl({
    required this.id,
    this.title,
    this.version,
    this.baseUrl,
    required this.rawContent,
    final List<OpenApiEndpoint> endpoints = const [],
    required this.sourceType,
    this.sourceUrl,
    required this.importedAt,
    this.updatedAt,
  }) : _endpoints = endpoints;

  factory _$OpenApiSpecImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpenApiSpecImplFromJson(json);

  @override
  final String id;
  @override
  final String? title;
  @override
  final String? version;
  @override
  final String? baseUrl;
  @override
  final String rawContent;
  final List<OpenApiEndpoint> _endpoints;
  @override
  @JsonKey()
  List<OpenApiEndpoint> get endpoints {
    if (_endpoints is EqualUnmodifiableListView) return _endpoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_endpoints);
  }

  @override
  final String sourceType;
  @override
  final String? sourceUrl;
  @override
  final DateTime importedAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'OpenApiSpec(id: $id, title: $title, version: $version, baseUrl: $baseUrl, rawContent: $rawContent, endpoints: $endpoints, sourceType: $sourceType, sourceUrl: $sourceUrl, importedAt: $importedAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpenApiSpecImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.rawContent, rawContent) ||
                other.rawContent == rawContent) &&
            const DeepCollectionEquality().equals(
              other._endpoints,
              _endpoints,
            ) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.sourceUrl, sourceUrl) ||
                other.sourceUrl == sourceUrl) &&
            (identical(other.importedAt, importedAt) ||
                other.importedAt == importedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    version,
    baseUrl,
    rawContent,
    const DeepCollectionEquality().hash(_endpoints),
    sourceType,
    sourceUrl,
    importedAt,
    updatedAt,
  );

  /// Create a copy of OpenApiSpec
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpenApiSpecImplCopyWith<_$OpenApiSpecImpl> get copyWith =>
      __$$OpenApiSpecImplCopyWithImpl<_$OpenApiSpecImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OpenApiSpecImplToJson(this);
  }
}

abstract class _OpenApiSpec implements OpenApiSpec {
  const factory _OpenApiSpec({
    required final String id,
    final String? title,
    final String? version,
    final String? baseUrl,
    required final String rawContent,
    final List<OpenApiEndpoint> endpoints,
    required final String sourceType,
    final String? sourceUrl,
    required final DateTime importedAt,
    final DateTime? updatedAt,
  }) = _$OpenApiSpecImpl;

  factory _OpenApiSpec.fromJson(Map<String, dynamic> json) =
      _$OpenApiSpecImpl.fromJson;

  @override
  String get id;
  @override
  String? get title;
  @override
  String? get version;
  @override
  String? get baseUrl;
  @override
  String get rawContent;
  @override
  List<OpenApiEndpoint> get endpoints;
  @override
  String get sourceType;
  @override
  String? get sourceUrl;
  @override
  DateTime get importedAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of OpenApiSpec
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpenApiSpecImplCopyWith<_$OpenApiSpecImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OpenApiEndpoint _$OpenApiEndpointFromJson(Map<String, dynamic> json) {
  return _OpenApiEndpoint.fromJson(json);
}

/// @nodoc
mixin _$OpenApiEndpoint {
  String get path => throw _privateConstructorUsedError;
  String get method => throw _privateConstructorUsedError;
  String? get summary => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get operationId => throw _privateConstructorUsedError;
  List<OpenApiParameter> get parameters => throw _privateConstructorUsedError;
  OpenApiSchema? get requestBodySchema => throw _privateConstructorUsedError;
  Map<String, OpenApiSchema>? get responseSchemas =>
      throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this OpenApiEndpoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpenApiEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpenApiEndpointCopyWith<OpenApiEndpoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpenApiEndpointCopyWith<$Res> {
  factory $OpenApiEndpointCopyWith(
    OpenApiEndpoint value,
    $Res Function(OpenApiEndpoint) then,
  ) = _$OpenApiEndpointCopyWithImpl<$Res, OpenApiEndpoint>;
  @useResult
  $Res call({
    String path,
    String method,
    String? summary,
    String? description,
    String? operationId,
    List<OpenApiParameter> parameters,
    OpenApiSchema? requestBodySchema,
    Map<String, OpenApiSchema>? responseSchemas,
    List<String> tags,
  });

  $OpenApiSchemaCopyWith<$Res>? get requestBodySchema;
}

/// @nodoc
class _$OpenApiEndpointCopyWithImpl<$Res, $Val extends OpenApiEndpoint>
    implements $OpenApiEndpointCopyWith<$Res> {
  _$OpenApiEndpointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpenApiEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? method = null,
    Object? summary = freezed,
    Object? description = freezed,
    Object? operationId = freezed,
    Object? parameters = null,
    Object? requestBodySchema = freezed,
    Object? responseSchemas = freezed,
    Object? tags = null,
  }) {
    return _then(
      _value.copyWith(
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
            summary: freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            operationId: freezed == operationId
                ? _value.operationId
                : operationId // ignore: cast_nullable_to_non_nullable
                      as String?,
            parameters: null == parameters
                ? _value.parameters
                : parameters // ignore: cast_nullable_to_non_nullable
                      as List<OpenApiParameter>,
            requestBodySchema: freezed == requestBodySchema
                ? _value.requestBodySchema
                : requestBodySchema // ignore: cast_nullable_to_non_nullable
                      as OpenApiSchema?,
            responseSchemas: freezed == responseSchemas
                ? _value.responseSchemas
                : responseSchemas // ignore: cast_nullable_to_non_nullable
                      as Map<String, OpenApiSchema>?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }

  /// Create a copy of OpenApiEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OpenApiSchemaCopyWith<$Res>? get requestBodySchema {
    if (_value.requestBodySchema == null) {
      return null;
    }

    return $OpenApiSchemaCopyWith<$Res>(_value.requestBodySchema!, (value) {
      return _then(_value.copyWith(requestBodySchema: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OpenApiEndpointImplCopyWith<$Res>
    implements $OpenApiEndpointCopyWith<$Res> {
  factory _$$OpenApiEndpointImplCopyWith(
    _$OpenApiEndpointImpl value,
    $Res Function(_$OpenApiEndpointImpl) then,
  ) = __$$OpenApiEndpointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String path,
    String method,
    String? summary,
    String? description,
    String? operationId,
    List<OpenApiParameter> parameters,
    OpenApiSchema? requestBodySchema,
    Map<String, OpenApiSchema>? responseSchemas,
    List<String> tags,
  });

  @override
  $OpenApiSchemaCopyWith<$Res>? get requestBodySchema;
}

/// @nodoc
class __$$OpenApiEndpointImplCopyWithImpl<$Res>
    extends _$OpenApiEndpointCopyWithImpl<$Res, _$OpenApiEndpointImpl>
    implements _$$OpenApiEndpointImplCopyWith<$Res> {
  __$$OpenApiEndpointImplCopyWithImpl(
    _$OpenApiEndpointImpl _value,
    $Res Function(_$OpenApiEndpointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpenApiEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? method = null,
    Object? summary = freezed,
    Object? description = freezed,
    Object? operationId = freezed,
    Object? parameters = null,
    Object? requestBodySchema = freezed,
    Object? responseSchemas = freezed,
    Object? tags = null,
  }) {
    return _then(
      _$OpenApiEndpointImpl(
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
        summary: freezed == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        operationId: freezed == operationId
            ? _value.operationId
            : operationId // ignore: cast_nullable_to_non_nullable
                  as String?,
        parameters: null == parameters
            ? _value._parameters
            : parameters // ignore: cast_nullable_to_non_nullable
                  as List<OpenApiParameter>,
        requestBodySchema: freezed == requestBodySchema
            ? _value.requestBodySchema
            : requestBodySchema // ignore: cast_nullable_to_non_nullable
                  as OpenApiSchema?,
        responseSchemas: freezed == responseSchemas
            ? _value._responseSchemas
            : responseSchemas // ignore: cast_nullable_to_non_nullable
                  as Map<String, OpenApiSchema>?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpenApiEndpointImpl implements _OpenApiEndpoint {
  const _$OpenApiEndpointImpl({
    required this.path,
    required this.method,
    this.summary,
    this.description,
    this.operationId,
    final List<OpenApiParameter> parameters = const [],
    this.requestBodySchema,
    final Map<String, OpenApiSchema>? responseSchemas,
    final List<String> tags = const [],
  }) : _parameters = parameters,
       _responseSchemas = responseSchemas,
       _tags = tags;

  factory _$OpenApiEndpointImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpenApiEndpointImplFromJson(json);

  @override
  final String path;
  @override
  final String method;
  @override
  final String? summary;
  @override
  final String? description;
  @override
  final String? operationId;
  final List<OpenApiParameter> _parameters;
  @override
  @JsonKey()
  List<OpenApiParameter> get parameters {
    if (_parameters is EqualUnmodifiableListView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parameters);
  }

  @override
  final OpenApiSchema? requestBodySchema;
  final Map<String, OpenApiSchema>? _responseSchemas;
  @override
  Map<String, OpenApiSchema>? get responseSchemas {
    final value = _responseSchemas;
    if (value == null) return null;
    if (_responseSchemas is EqualUnmodifiableMapView) return _responseSchemas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'OpenApiEndpoint(path: $path, method: $method, summary: $summary, description: $description, operationId: $operationId, parameters: $parameters, requestBodySchema: $requestBodySchema, responseSchemas: $responseSchemas, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpenApiEndpointImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.operationId, operationId) ||
                other.operationId == operationId) &&
            const DeepCollectionEquality().equals(
              other._parameters,
              _parameters,
            ) &&
            (identical(other.requestBodySchema, requestBodySchema) ||
                other.requestBodySchema == requestBodySchema) &&
            const DeepCollectionEquality().equals(
              other._responseSchemas,
              _responseSchemas,
            ) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    path,
    method,
    summary,
    description,
    operationId,
    const DeepCollectionEquality().hash(_parameters),
    requestBodySchema,
    const DeepCollectionEquality().hash(_responseSchemas),
    const DeepCollectionEquality().hash(_tags),
  );

  /// Create a copy of OpenApiEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpenApiEndpointImplCopyWith<_$OpenApiEndpointImpl> get copyWith =>
      __$$OpenApiEndpointImplCopyWithImpl<_$OpenApiEndpointImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OpenApiEndpointImplToJson(this);
  }
}

abstract class _OpenApiEndpoint implements OpenApiEndpoint {
  const factory _OpenApiEndpoint({
    required final String path,
    required final String method,
    final String? summary,
    final String? description,
    final String? operationId,
    final List<OpenApiParameter> parameters,
    final OpenApiSchema? requestBodySchema,
    final Map<String, OpenApiSchema>? responseSchemas,
    final List<String> tags,
  }) = _$OpenApiEndpointImpl;

  factory _OpenApiEndpoint.fromJson(Map<String, dynamic> json) =
      _$OpenApiEndpointImpl.fromJson;

  @override
  String get path;
  @override
  String get method;
  @override
  String? get summary;
  @override
  String? get description;
  @override
  String? get operationId;
  @override
  List<OpenApiParameter> get parameters;
  @override
  OpenApiSchema? get requestBodySchema;
  @override
  Map<String, OpenApiSchema>? get responseSchemas;
  @override
  List<String> get tags;

  /// Create a copy of OpenApiEndpoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpenApiEndpointImplCopyWith<_$OpenApiEndpointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OpenApiParameter _$OpenApiParameterFromJson(Map<String, dynamic> json) {
  return _OpenApiParameter.fromJson(json);
}

/// @nodoc
mixin _$OpenApiParameter {
  String get name => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool get required => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  String? get schemaType => throw _privateConstructorUsedError;

  /// Serializes this OpenApiParameter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpenApiParameter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpenApiParameterCopyWith<OpenApiParameter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpenApiParameterCopyWith<$Res> {
  factory $OpenApiParameterCopyWith(
    OpenApiParameter value,
    $Res Function(OpenApiParameter) then,
  ) = _$OpenApiParameterCopyWithImpl<$Res, OpenApiParameter>;
  @useResult
  $Res call({
    String name,
    String location,
    String? description,
    bool required,
    String? type,
    String? schemaType,
  });
}

/// @nodoc
class _$OpenApiParameterCopyWithImpl<$Res, $Val extends OpenApiParameter>
    implements $OpenApiParameterCopyWith<$Res> {
  _$OpenApiParameterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpenApiParameter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? location = null,
    Object? description = freezed,
    Object? required = null,
    Object? type = freezed,
    Object? schemaType = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            location: null == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            required: null == required
                ? _value.required
                : required // ignore: cast_nullable_to_non_nullable
                      as bool,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            schemaType: freezed == schemaType
                ? _value.schemaType
                : schemaType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OpenApiParameterImplCopyWith<$Res>
    implements $OpenApiParameterCopyWith<$Res> {
  factory _$$OpenApiParameterImplCopyWith(
    _$OpenApiParameterImpl value,
    $Res Function(_$OpenApiParameterImpl) then,
  ) = __$$OpenApiParameterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String location,
    String? description,
    bool required,
    String? type,
    String? schemaType,
  });
}

/// @nodoc
class __$$OpenApiParameterImplCopyWithImpl<$Res>
    extends _$OpenApiParameterCopyWithImpl<$Res, _$OpenApiParameterImpl>
    implements _$$OpenApiParameterImplCopyWith<$Res> {
  __$$OpenApiParameterImplCopyWithImpl(
    _$OpenApiParameterImpl _value,
    $Res Function(_$OpenApiParameterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpenApiParameter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? location = null,
    Object? description = freezed,
    Object? required = null,
    Object? type = freezed,
    Object? schemaType = freezed,
  }) {
    return _then(
      _$OpenApiParameterImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        location: null == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        required: null == required
            ? _value.required
            : required // ignore: cast_nullable_to_non_nullable
                  as bool,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        schemaType: freezed == schemaType
            ? _value.schemaType
            : schemaType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpenApiParameterImpl implements _OpenApiParameter {
  const _$OpenApiParameterImpl({
    required this.name,
    required this.location,
    this.description,
    this.required = false,
    this.type,
    this.schemaType,
  });

  factory _$OpenApiParameterImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpenApiParameterImplFromJson(json);

  @override
  final String name;
  @override
  final String location;
  @override
  final String? description;
  @override
  @JsonKey()
  final bool required;
  @override
  final String? type;
  @override
  final String? schemaType;

  @override
  String toString() {
    return 'OpenApiParameter(name: $name, location: $location, description: $description, required: $required, type: $type, schemaType: $schemaType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpenApiParameterImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.required, required) ||
                other.required == required) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.schemaType, schemaType) ||
                other.schemaType == schemaType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    location,
    description,
    required,
    type,
    schemaType,
  );

  /// Create a copy of OpenApiParameter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpenApiParameterImplCopyWith<_$OpenApiParameterImpl> get copyWith =>
      __$$OpenApiParameterImplCopyWithImpl<_$OpenApiParameterImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OpenApiParameterImplToJson(this);
  }
}

abstract class _OpenApiParameter implements OpenApiParameter {
  const factory _OpenApiParameter({
    required final String name,
    required final String location,
    final String? description,
    final bool required,
    final String? type,
    final String? schemaType,
  }) = _$OpenApiParameterImpl;

  factory _OpenApiParameter.fromJson(Map<String, dynamic> json) =
      _$OpenApiParameterImpl.fromJson;

  @override
  String get name;
  @override
  String get location;
  @override
  String? get description;
  @override
  bool get required;
  @override
  String? get type;
  @override
  String? get schemaType;

  /// Create a copy of OpenApiParameter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpenApiParameterImplCopyWith<_$OpenApiParameterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OpenApiSchema _$OpenApiSchemaFromJson(Map<String, dynamic> json) {
  return _OpenApiSchema.fromJson(json);
}

/// @nodoc
mixin _$OpenApiSchema {
  String? get type => throw _privateConstructorUsedError;
  String? get format => throw _privateConstructorUsedError;
  String? get ref => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  Map<String, OpenApiSchema> get properties =>
      throw _privateConstructorUsedError;
  List<String> get requiredFields => throw _privateConstructorUsedError;
  OpenApiSchema? get items => throw _privateConstructorUsedError;
  List<String> get enumValues => throw _privateConstructorUsedError;

  /// Serializes this OpenApiSchema to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OpenApiSchema
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OpenApiSchemaCopyWith<OpenApiSchema> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpenApiSchemaCopyWith<$Res> {
  factory $OpenApiSchemaCopyWith(
    OpenApiSchema value,
    $Res Function(OpenApiSchema) then,
  ) = _$OpenApiSchemaCopyWithImpl<$Res, OpenApiSchema>;
  @useResult
  $Res call({
    String? type,
    String? format,
    String? ref,
    String? description,
    Map<String, OpenApiSchema> properties,
    List<String> requiredFields,
    OpenApiSchema? items,
    List<String> enumValues,
  });

  $OpenApiSchemaCopyWith<$Res>? get items;
}

/// @nodoc
class _$OpenApiSchemaCopyWithImpl<$Res, $Val extends OpenApiSchema>
    implements $OpenApiSchemaCopyWith<$Res> {
  _$OpenApiSchemaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OpenApiSchema
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = freezed,
    Object? format = freezed,
    Object? ref = freezed,
    Object? description = freezed,
    Object? properties = null,
    Object? requiredFields = null,
    Object? items = freezed,
    Object? enumValues = null,
  }) {
    return _then(
      _value.copyWith(
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            format: freezed == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String?,
            ref: freezed == ref
                ? _value.ref
                : ref // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            properties: null == properties
                ? _value.properties
                : properties // ignore: cast_nullable_to_non_nullable
                      as Map<String, OpenApiSchema>,
            requiredFields: null == requiredFields
                ? _value.requiredFields
                : requiredFields // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            items: freezed == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as OpenApiSchema?,
            enumValues: null == enumValues
                ? _value.enumValues
                : enumValues // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }

  /// Create a copy of OpenApiSchema
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OpenApiSchemaCopyWith<$Res>? get items {
    if (_value.items == null) {
      return null;
    }

    return $OpenApiSchemaCopyWith<$Res>(_value.items!, (value) {
      return _then(_value.copyWith(items: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OpenApiSchemaImplCopyWith<$Res>
    implements $OpenApiSchemaCopyWith<$Res> {
  factory _$$OpenApiSchemaImplCopyWith(
    _$OpenApiSchemaImpl value,
    $Res Function(_$OpenApiSchemaImpl) then,
  ) = __$$OpenApiSchemaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? type,
    String? format,
    String? ref,
    String? description,
    Map<String, OpenApiSchema> properties,
    List<String> requiredFields,
    OpenApiSchema? items,
    List<String> enumValues,
  });

  @override
  $OpenApiSchemaCopyWith<$Res>? get items;
}

/// @nodoc
class __$$OpenApiSchemaImplCopyWithImpl<$Res>
    extends _$OpenApiSchemaCopyWithImpl<$Res, _$OpenApiSchemaImpl>
    implements _$$OpenApiSchemaImplCopyWith<$Res> {
  __$$OpenApiSchemaImplCopyWithImpl(
    _$OpenApiSchemaImpl _value,
    $Res Function(_$OpenApiSchemaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OpenApiSchema
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = freezed,
    Object? format = freezed,
    Object? ref = freezed,
    Object? description = freezed,
    Object? properties = null,
    Object? requiredFields = null,
    Object? items = freezed,
    Object? enumValues = null,
  }) {
    return _then(
      _$OpenApiSchemaImpl(
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        format: freezed == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String?,
        ref: freezed == ref
            ? _value.ref
            : ref // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        properties: null == properties
            ? _value._properties
            : properties // ignore: cast_nullable_to_non_nullable
                  as Map<String, OpenApiSchema>,
        requiredFields: null == requiredFields
            ? _value._requiredFields
            : requiredFields // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        items: freezed == items
            ? _value.items
            : items // ignore: cast_nullable_to_non_nullable
                  as OpenApiSchema?,
        enumValues: null == enumValues
            ? _value._enumValues
            : enumValues // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpenApiSchemaImpl implements _OpenApiSchema {
  const _$OpenApiSchemaImpl({
    this.type,
    this.format,
    this.ref,
    this.description,
    final Map<String, OpenApiSchema> properties = const {},
    final List<String> requiredFields = const [],
    this.items,
    final List<String> enumValues = const [],
  }) : _properties = properties,
       _requiredFields = requiredFields,
       _enumValues = enumValues;

  factory _$OpenApiSchemaImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpenApiSchemaImplFromJson(json);

  @override
  final String? type;
  @override
  final String? format;
  @override
  final String? ref;
  @override
  final String? description;
  final Map<String, OpenApiSchema> _properties;
  @override
  @JsonKey()
  Map<String, OpenApiSchema> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  final List<String> _requiredFields;
  @override
  @JsonKey()
  List<String> get requiredFields {
    if (_requiredFields is EqualUnmodifiableListView) return _requiredFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredFields);
  }

  @override
  final OpenApiSchema? items;
  final List<String> _enumValues;
  @override
  @JsonKey()
  List<String> get enumValues {
    if (_enumValues is EqualUnmodifiableListView) return _enumValues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_enumValues);
  }

  @override
  String toString() {
    return 'OpenApiSchema(type: $type, format: $format, ref: $ref, description: $description, properties: $properties, requiredFields: $requiredFields, items: $items, enumValues: $enumValues)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpenApiSchemaImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.ref, ref) || other.ref == ref) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(
              other._properties,
              _properties,
            ) &&
            const DeepCollectionEquality().equals(
              other._requiredFields,
              _requiredFields,
            ) &&
            (identical(other.items, items) || other.items == items) &&
            const DeepCollectionEquality().equals(
              other._enumValues,
              _enumValues,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    format,
    ref,
    description,
    const DeepCollectionEquality().hash(_properties),
    const DeepCollectionEquality().hash(_requiredFields),
    items,
    const DeepCollectionEquality().hash(_enumValues),
  );

  /// Create a copy of OpenApiSchema
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpenApiSchemaImplCopyWith<_$OpenApiSchemaImpl> get copyWith =>
      __$$OpenApiSchemaImplCopyWithImpl<_$OpenApiSchemaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OpenApiSchemaImplToJson(this);
  }
}

abstract class _OpenApiSchema implements OpenApiSchema {
  const factory _OpenApiSchema({
    final String? type,
    final String? format,
    final String? ref,
    final String? description,
    final Map<String, OpenApiSchema> properties,
    final List<String> requiredFields,
    final OpenApiSchema? items,
    final List<String> enumValues,
  }) = _$OpenApiSchemaImpl;

  factory _OpenApiSchema.fromJson(Map<String, dynamic> json) =
      _$OpenApiSchemaImpl.fromJson;

  @override
  String? get type;
  @override
  String? get format;
  @override
  String? get ref;
  @override
  String? get description;
  @override
  Map<String, OpenApiSchema> get properties;
  @override
  List<String> get requiredFields;
  @override
  OpenApiSchema? get items;
  @override
  List<String> get enumValues;

  /// Create a copy of OpenApiSchema
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpenApiSchemaImplCopyWith<_$OpenApiSchemaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
