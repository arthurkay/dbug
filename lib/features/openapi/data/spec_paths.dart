/// Matches an OpenAPI path template parameter such as `{id}` or `{user-id}`.
final _pathParam = RegExp(r'\{([^{}/]+)\}');

/// Converts an OpenAPI path template (`/users/{user-id}`) into dbug's
/// variable syntax (`/users/{{user-id}}`).
String convertSpecPath(String path) =>
    path.replaceAllMapped(_pathParam, (m) => '{{${m.group(1)}}}');

/// The parameter names used in an OpenAPI path template, in order.
List<String> specPathParams(String path) =>
    _pathParam.allMatches(path).map((m) => m.group(1)!).toList();

/// The request URL for an endpoint of an imported spec: the converted path,
/// prefixed with `{{baseUrl}}` when the spec defines a base URL.
String specRequestUrl(String path, {required bool hasBaseUrl}) {
  final converted = convertSpecPath(path);
  return hasBaseUrl ? '{{baseUrl}}$converted' : converted;
}
