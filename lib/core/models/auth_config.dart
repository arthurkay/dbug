import 'dart:convert';

enum AuthType {
  none('none', 'None'),
  bearer('bearer', 'Bearer'),
  basic('basic', 'Basic'),
  apiKey('apikey', 'API Key');

  const AuthType(this.storedName, this.label);

  /// Name persisted in the `auth_type` columns.
  final String storedName;
  final String label;

  static AuthType fromStored(String? name) => AuthType.values.firstWhere(
        (t) => t.storedName == name,
        orElse: () => AuthType.none,
      );
}

enum ApiKeyLocation { header, query }

/// Auth settings for a request or a collection. Persisted as a type name plus
/// a JSON object (`authType` / `authData` columns):
/// bearer `{token}`, basic `{username, password}`,
/// apikey `{name, value, location: header|query}`.
class AuthConfig {
  final AuthType type;
  final String token;
  final String username;
  final String password;
  final String apiKeyName;
  final String apiKeyValue;
  final ApiKeyLocation apiKeyLocation;

  const AuthConfig({
    this.type = AuthType.none,
    this.token = '',
    this.username = '',
    this.password = '',
    this.apiKeyName = '',
    this.apiKeyValue = '',
    this.apiKeyLocation = ApiKeyLocation.header,
  });

  static const none = AuthConfig();

  /// Parses stored auth. Fields of the other types are kept too, so switching
  /// type in an editor and back doesn't lose what was typed.
  factory AuthConfig.fromStored(String? type, String? dataJson) {
    Map<String, dynamic> data = const {};
    try {
      final decoded = jsonDecode(dataJson ?? '{}');
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    String str(String key) => data[key]?.toString() ?? '';
    return AuthConfig(
      type: AuthType.fromStored(type),
      token: str('token'),
      username: str('username'),
      password: str('password'),
      apiKeyName: str('name'),
      apiKeyValue: str('value'),
      apiKeyLocation:
          data['location'] == 'query' ? ApiKeyLocation.query : ApiKeyLocation.header,
    );
  }

  String get storedType => type.storedName;

  /// JSON for the `auth_data` column; only the active type's fields.
  String get storedData => switch (type) {
        AuthType.none => '{}',
        AuthType.bearer => jsonEncode({'token': token}),
        AuthType.basic => jsonEncode({'username': username, 'password': password}),
        AuthType.apiKey => jsonEncode({
            'name': apiKeyName,
            'value': apiKeyValue,
            'location': apiKeyLocation.name,
          }),
      };

  /// True when this config would actually send credentials — a chosen type
  /// with blank fields sends nothing.
  bool get producesCredentials => switch (type) {
        AuthType.none => false,
        AuthType.bearer => token.trim().isNotEmpty,
        AuthType.basic => username.trim().isNotEmpty,
        AuthType.apiKey =>
          apiKeyName.trim().isNotEmpty && apiKeyValue.trim().isNotEmpty,
      };

  Map<String, String> headers() {
    if (!producesCredentials) return {};
    switch (type) {
      case AuthType.bearer:
        return {'Authorization': 'Bearer ${token.trim()}'};
      case AuthType.basic:
        final encoded = base64Encode(utf8.encode('${username.trim()}:$password'));
        return {'Authorization': 'Basic $encoded'};
      case AuthType.apiKey:
        if (apiKeyLocation != ApiKeyLocation.header) return {};
        return {apiKeyName.trim(): apiKeyValue.trim()};
      case AuthType.none:
        return {};
    }
  }

  Map<String, String> queryParams() {
    if (!producesCredentials ||
        type != AuthType.apiKey ||
        apiKeyLocation != ApiKeyLocation.query) {
      return {};
    }
    return {apiKeyName.trim(): apiKeyValue.trim()};
  }

  AuthConfig copyWith({
    AuthType? type,
    String? token,
    String? username,
    String? password,
    String? apiKeyName,
    String? apiKeyValue,
    ApiKeyLocation? apiKeyLocation,
  }) {
    return AuthConfig(
      type: type ?? this.type,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      apiKeyName: apiKeyName ?? this.apiKeyName,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
    );
  }

  /// Equality over what gets persisted (the active type's fields only).
  @override
  bool operator ==(Object other) =>
      other is AuthConfig &&
      other.storedType == storedType &&
      other.storedData == storedData;

  @override
  int get hashCode => Object.hash(storedType, storedData);
}
