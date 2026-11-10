import 'dart:convert';
import 'package:yaml/yaml.dart';

import '../../../core/models/openapi_spec.dart';

class OpenApiParser {
  /// Parses an OpenAPI 3.x or Swagger 2.0 document (JSON or YAML), returning
  /// null on any failure. Use [parseOrThrow] to learn why parsing failed.
  static ParsedSpec? parse(String content) {
    try {
      return parseOrThrow(content);
    } catch (_) {
      return null;
    }
  }

  /// Like [parse], but throws a [FormatException] whose message explains the
  /// failure ("Invalid JSON: ...", "Not an OpenAPI 3.x or Swagger 2.0
  /// document", ...), suitable for showing to the user.
  static ParsedSpec parseOrThrow(String content) {
    final trimmed = content.trimLeft();
    if (trimmed.isEmpty) throw const FormatException('The document is empty');

    final dynamic decoded;
    final isJson = trimmed.startsWith('{') || trimmed.startsWith('[');
    try {
      decoded = isJson ? jsonDecode(content) : _yamlToMap(loadYaml(content));
    } catch (e) {
      final detail = e is FormatException ? e.message : e.toString();
      throw FormatException('Invalid ${isJson ? 'JSON' : 'YAML'}: $detail');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not an OpenAPI 3.x or Swagger 2.0 document');
    }

    final openapi = decoded['openapi']?.toString() ?? '';
    final swagger = decoded['swagger']?.toString() ?? '';
    if (openapi.startsWith('3.')) return _parseSpec(decoded, content, isSwagger2: false);
    if (swagger.startsWith('2.')) return _parseSpec(decoded, content, isSwagger2: true);
    throw FormatException(
      openapi.isNotEmpty || swagger.isNotEmpty
          ? 'Unsupported spec version ${openapi.isNotEmpty ? 'OpenAPI $openapi' : 'Swagger $swagger'}'
          : 'Not an OpenAPI 3.x or Swagger 2.0 document',
    );
  }

  static dynamic _yamlToMap(dynamic yaml) {
    if (yaml is Map) {
      return yaml.map((key, value) => MapEntry(key.toString(), _yamlToMap(value)));
    } else if (yaml is List) {
      return yaml.map((e) => _yamlToMap(e)).toList();
    }
    return yaml;
  }

  static Map<String, dynamic>? _resolveRef(Map<String, dynamic> root, String ref) {
    if (!ref.startsWith('#/')) return null;
    final parts = ref.substring(2).split('/');
    dynamic current = root;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current is Map<String, dynamic> ? current : null;
  }

  /// OpenAPI 3: the first server, with `{variables}` replaced by their
  /// defaults. Swagger 2: `scheme://host` + `basePath`. Relative URLs are kept
  /// as-is.
  static String? _baseUrl(Map<String, dynamic> json, bool isSwagger2) {
    if (isSwagger2) {
      final host = json['host']?.toString();
      final basePath = json['basePath']?.toString() ?? '';
      if (host == null || host.isEmpty) return basePath.isEmpty ? null : basePath;
      final schemes = _stringList(json['schemes']);
      final scheme = schemes.contains('https') ? 'https' : (schemes.isNotEmpty ? schemes.first : 'https');
      return '$scheme://$host$basePath';
    }

    final server = _firstServer(json);
    if (server == null) return null;
    final variables = server.variables;
    return server.url.replaceAllMapped(_serverVariable, (m) {
      final value = variables[m.group(1)];
      return value == null || value.isEmpty ? m.group(0)! : value;
    });
  }

  static final _serverVariable = RegExp(r'\{([^{}]+)\}');

  static ({String url, Map<String, String> variables})? _firstServer(Map<String, dynamic> json) {
    final servers = (json['servers'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    if (servers.isEmpty) return null;
    final server = servers.first;
    final url = server['url']?.toString();
    if (url == null) return null;
    final declared = server['variables'];
    final variables = <String, String>{
      for (final m in _serverVariable.allMatches(url)) m.group(1)!: '',
      if (declared is Map)
        for (final e in declared.entries)
          e.key.toString(): (e.value is Map ? e.value['default'] : null)?.toString() ?? '',
    };
    return (url: url, variables: variables);
  }

  /// OpenAPI 3 server variables (`https://{host}:{port}`) become `{{host}}`
  /// placeholders, so environments can override them; their defaults are
  /// returned in [ParsedSpec.serverVariables]. Swagger 2 has none.
  static String? _baseUrlTemplate(Map<String, dynamic> json, bool isSwagger2) {
    if (isSwagger2) return _baseUrl(json, true);
    final server = _firstServer(json);
    if (server == null) return null;
    return server.url.replaceAllMapped(_serverVariable, (m) => '{{${m.group(1)}}}');
  }

  static ParsedSpec _parseSpec(Map<String, dynamic> json, String rawContent, {required bool isSwagger2}) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    final baseUrl = _baseUrl(json, isSwagger2);
    final baseUrlTemplate = _baseUrlTemplate(json, isSwagger2);
    final serverVariables = isSwagger2 ? const <String, String>{} : (_firstServer(json)?.variables ?? const <String, String>{});

    final paths = json['paths'] as Map<String, dynamic>? ?? {};
    final endpoints = <OpenApiEndpoint>[];

    paths.forEach((path, pathItem) {
      if (pathItem is! Map) return;
      final item = pathItem as Map<String, dynamic>;

      for (final method in ['get', 'post', 'put', 'patch', 'delete', 'head', 'options', 'trace']) {
        final operation = item[method] as Map<String, dynamic>?;
        if (operation == null) continue;

        final rawParams = [
          ...(item['parameters'] as List? ?? []),
          ...(operation['parameters'] as List? ?? []),
        ].map((p) => _resolveParam(json, p)).whereType<Map<String, dynamic>>().toList();

        final parameters = _parseParameters(
          json,
          rawParams.where((p) => p['in'] != 'body' && p['in'] != 'formData').toList(),
        );

        OpenApiSchema? requestBodySchema;
        if (isSwagger2) {
          final bodyParam = rawParams.where((p) => p['in'] == 'body').firstOrNull;
          if (bodyParam != null && bodyParam['schema'] is Map) {
            requestBodySchema = _parseSchema(json, bodyParam['schema'] as Map<String, dynamic>);
          }
        } else {
          final requestBody = operation['requestBody'];
          final resolvedBody = requestBody is Map<String, dynamic> && requestBody['\$ref'] != null
              ? _resolveRef(json, requestBody['\$ref'].toString())
              : requestBody as Map<String, dynamic>?;
          requestBodySchema = _extractSchema(json, resolvedBody);
        }

        final responses = operation['responses'] as Map<String, dynamic>? ?? {};
        final responseSchemas = <String, OpenApiSchema>{};
        responses.forEach((code, response) {
          if (response is Map) {
            final schema = _extractSchema(json, response as Map<String, dynamic>);
            if (schema != null) {
              responseSchemas[code] = schema;
            }
          }
        });

        endpoints.add(OpenApiEndpoint(
          path: path,
          method: method.toUpperCase(),
          summary: operation['summary']?.toString(),
          description: operation['description']?.toString(),
          operationId: operation['operationId']?.toString(),
          parameters: parameters,
          requestBodySchema: requestBodySchema,
          responseSchemas: responseSchemas.isNotEmpty ? responseSchemas : null,
          tags: _stringList(operation['tags']),
        ));
      }
    });

    return ParsedSpec(
      title: info['title']?.toString(),
      version: info['version']?.toString(),
      baseUrl: baseUrl,
      baseUrlTemplate: baseUrlTemplate,
      serverVariables: serverVariables,
      endpoints: endpoints,
      rawContent: rawContent,
    );
  }

  /// Resolves a `$ref` parameter (e.g. `#/components/parameters/Limit`).
  static Map<String, dynamic>? _resolveParam(Map<String, dynamic> root, dynamic param) {
    if (param is! Map<String, dynamic>) return null;
    final ref = param['\$ref']?.toString();
    if (ref == null) return param;
    return _resolveRef(root, ref);
  }

  static List<OpenApiParameter> _parseParameters(
    Map<String, dynamic> root,
    List<Map<String, dynamic>> params,
  ) {
    return params.map((p) {
      final schema = p['schema'] is Map
          ? _parseSchema(root, p['schema'] as Map<String, dynamic>)
          : null;
      // Swagger 2 puts type/default on the parameter itself.
      final type = schema?.type ?? p['type']?.toString();
      final rawSchema = p['schema'] is Map ? p['schema'] as Map : const {};
      final example = p['example'] ?? rawSchema['example'] ?? rawSchema['default'] ?? p['default'];
      return OpenApiParameter(
        name: p['name']?.toString() ?? '',
        location: p['in']?.toString() ?? 'query',
        description: p['description']?.toString(),
        required: p['required'] == true,
        type: type,
        schemaType: type,
        example: example?.toString(),
      );
    }).toList();
  }

  static OpenApiSchema? _extractSchema(Map<String, dynamic> root, Map<String, dynamic>? container) {
    if (container == null) return null;

    final ref = container['\$ref']?.toString();
    if (ref != null) {
      return _extractSchema(root, _resolveRef(root, ref));
    }

    // Swagger 2 responses carry the schema directly.
    if (container['schema'] is Map<String, dynamic>) {
      return _parseSchema(root, container['schema'] as Map<String, dynamic>);
    }

    final content = container['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final jsonContent = content['application/json'] ??
        content.entries.where((e) => e.key.contains('json')).map((e) => e.value).firstOrNull ??
        content['*/*'];
    if (jsonContent is! Map) return null;

    final schema = jsonContent['schema'] as Map<String, dynamic>?;
    if (schema == null) return null;

    return _parseSchema(root, schema);
  }

  static OpenApiSchema _parseSchema(
    Map<String, dynamic> root,
    Map<String, dynamic> schema, [
    Set<String> visitedRefs = const {},
  ]) {
    final ref = schema['\$ref']?.toString();

    if (ref != null) {
      // A $ref already on the current resolution path means the schema is
      // cyclic (e.g. Category.parent -> Category); stop at the reference
      // instead of recursing forever.
      if (visitedRefs.contains(ref)) {
        return OpenApiSchema(type: 'object', ref: ref);
      }
      final seen = {...visitedRefs, ref};
      final resolved = _resolveRef(root, ref);
      if (resolved != null) {
        return _parseSchema(root, resolved, seen);
      }
      final refName = ref.split('/').last;
      final componentSchemas = root['components'] is Map ? (root['components'] as Map)['schemas'] : null;
      if (componentSchemas is Map && componentSchemas.containsKey(refName)) {
        final fallback = componentSchemas[refName];
        if (fallback is Map<String, dynamic>) {
          return _parseSchema(root, fallback, seen);
        }
      }
      return OpenApiSchema(type: 'object', ref: ref);
    }

    final properties = <String, OpenApiSchema>{};
    if (schema['properties'] is Map) {
      (schema['properties'] as Map).forEach((key, value) {
        if (value is Map) {
          properties[key.toString()] = _parseSchema(root, value as Map<String, dynamic>, visitedRefs);
        }
      });
    }

    final requiredFields = _stringList(schema['required']);

    return OpenApiSchema(
      type: schema['type']?.toString(),
      format: schema['format']?.toString(),
      ref: ref,
      description: schema['description']?.toString(),
      properties: properties,
      requiredFields: requiredFields,
      items: schema['items'] is Map
          ? _parseSchema(root, schema['items'] as Map<String, dynamic>, visitedRefs)
          : null,
      enumValues: _stringList(schema['enum']),
    );
  }

  /// Eagerly converts a JSON list to strings. Unlike a lazy `.cast<String>()`,
  /// this neither defers type errors to first iteration nor rejects valid
  /// non-string values (e.g. integer enums).
  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }
}

class ParsedSpec {
  final String? title;
  final String? version;
  /// The first server URL with variables replaced by their defaults (those
  /// without a default stay as `{name}`), for display.
  final String? baseUrl;

  /// The first server URL with variables as `{{name}}` placeholders; what
  /// the spec environment's `baseUrl` is set to.
  final String? baseUrlTemplate;

  /// Server variables and their defaults (blank when the spec has none).
  final Map<String, String> serverVariables;
  final List<OpenApiEndpoint> endpoints;
  final String rawContent;

  const ParsedSpec({
    this.title,
    this.version,
    this.baseUrl,
    this.baseUrlTemplate,
    this.serverVariables = const {},
    required this.endpoints,
    required this.rawContent,
  });
}
