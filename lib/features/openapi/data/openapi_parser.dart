import 'dart:convert';
import 'package:yaml/yaml.dart';

import '../../../core/models/openapi_spec.dart';

class OpenApiParser {
  static ParsedSpec? parse(String content) {
    try {
      Map<String, dynamic> json;
      if (content.trimLeft().startsWith('{') || content.trimLeft().startsWith('[')) {
        json = jsonDecode(content) as Map<String, dynamic>;
      } else {
        final yaml = loadYaml(content);
        json = _yamlToMap(yaml);
      }

      final openapi = json['openapi']?.toString() ?? '';
      if (!openapi.startsWith('3.')) {
        return null;
      }

      return _parseSpec(json, content);
    } catch (e) {
      return null;
    }
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

  static ParsedSpec _parseSpec(Map<String, dynamic> json, String rawContent) {
    final info = json['info'] as Map<String, dynamic>? ?? {};
    final servers = (json['servers'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    final baseUrl = servers.isNotEmpty ? servers.first['url']?.toString() : null;

    final paths = json['paths'] as Map<String, dynamic>? ?? {};
    final endpoints = <OpenApiEndpoint>[];

    paths.forEach((path, pathItem) {
      if (pathItem is! Map) return;
      final item = pathItem as Map<String, dynamic>;

      for (final method in ['get', 'post', 'put', 'patch', 'delete', 'head', 'options', 'trace']) {
        final operation = item[method] as Map<String, dynamic>?;
        if (operation == null) continue;

        final parameters = _parseParameters(
          json,
          operation['parameters'] as List? ?? [],
          item['parameters'] as List? ?? [],
        );

        final requestBody = operation['requestBody'] as Map<String, dynamic>?;
        final requestBodySchema = _extractSchema(json, requestBody);

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
          tags: (operation['tags'] as List?)?.cast<String>() ?? [],
        ));
      }
    });

    return ParsedSpec(
      title: info['title']?.toString(),
      version: info['version']?.toString(),
      baseUrl: baseUrl,
      endpoints: endpoints,
      rawContent: rawContent,
    );
  }

  static List<OpenApiParameter> _parseParameters(
    Map<String, dynamic> root,
    List operationParams,
    List pathParams,
  ) {
    final allParams = [...pathParams, ...operationParams];
    return allParams.whereType<Map>().map((p) {
      final schema = p['schema'] is Map
          ? _parseSchema(root, p['schema'] as Map<String, dynamic>)
          : null;
      return OpenApiParameter(
        name: p['name']?.toString() ?? '',
        location: p['in']?.toString() ?? 'query',
        description: p['description']?.toString(),
        required: p['required'] == true,
        type: schema?.type,
        schemaType: schema?.type,
      );
    }).toList();
  }

  static OpenApiSchema? _extractSchema(Map<String, dynamic> root, Map<String, dynamic>? container) {
    if (container == null) return null;
    final content = container['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final jsonContent = content['application/json'] ?? content['*/*'];
    if (jsonContent is! Map) return null;

    final schema = jsonContent['schema'] as Map<String, dynamic>?;
    if (schema == null) return null;

    return _parseSchema(root, schema);
  }

  static OpenApiSchema _parseSchema(Map<String, dynamic> root, Map<String, dynamic> schema) {
    final ref = schema['\$ref']?.toString();

    if (ref != null) {
      final resolved = _resolveRef(root, ref);
      if (resolved != null) {
        return _parseSchema(root, resolved);
      }
      final refName = ref.split('/').last;
      final componentSchemas = root['components'] is Map ? (root['components'] as Map)['schemas'] : null;
      if (componentSchemas is Map && componentSchemas.containsKey(refName)) {
        final fallback = componentSchemas[refName];
        if (fallback is Map<String, dynamic>) {
          return _parseSchema(root, fallback);
        }
      }
      return OpenApiSchema(type: 'object', ref: ref);
    }

    final properties = <String, OpenApiSchema>{};
    if (schema['properties'] is Map) {
      (schema['properties'] as Map).forEach((key, value) {
        if (value is Map) {
          properties[key.toString()] = _parseSchema(root, value as Map<String, dynamic>);
        }
      });
    }

    final requiredFields = (schema['required'] as List?)?.cast<String>() ?? [];

    return OpenApiSchema(
      type: schema['type']?.toString(),
      format: schema['format']?.toString(),
      ref: ref,
      description: schema['description']?.toString(),
      properties: properties,
      requiredFields: requiredFields,
      items: schema['items'] is Map
          ? _parseSchema(root, schema['items'] as Map<String, dynamic>)
          : null,
      enumValues: (schema['enum'] as List?)?.cast<String>() ?? [],
    );
  }
}

class ParsedSpec {
  final String? title;
  final String? version;
  final String? baseUrl;
  final List<OpenApiEndpoint> endpoints;
  final String rawContent;

  const ParsedSpec({
    this.title,
    this.version,
    this.baseUrl,
    required this.endpoints,
    required this.rawContent,
  });
}
