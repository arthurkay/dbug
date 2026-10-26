import '../../../core/models/openapi_spec.dart';

/// Builds an example JSON value for [schema] to prefill a request body:
/// enums use their first value, strings `""`, numbers `0`, booleans `false`,
/// arrays a single item skeleton, objects every property. Recursion stops at
/// [maxDepth] (cyclic `$ref`s are already cut by the parser, but deeply nested
/// schemas would otherwise produce enormous bodies).
Object? schemaSkeleton(OpenApiSchema? schema, {int maxDepth = 6}) {
  return _skeleton(schema, 0, maxDepth);
}

Object? _skeleton(OpenApiSchema? schema, int depth, int maxDepth) {
  if (schema == null) return null;
  if (schema.enumValues.isNotEmpty) {
    final first = schema.enumValues.first;
    return switch (schema.type) {
      'integer' => int.tryParse(first) ?? first,
      'number' => num.tryParse(first) ?? first,
      'boolean' => first == 'true',
      _ => first,
    };
  }

  final type = schema.type ??
      (schema.properties.isNotEmpty ? 'object' : (schema.items != null ? 'array' : null));
  switch (type) {
    case 'string':
      return '';
    case 'integer':
    case 'number':
      return 0;
    case 'boolean':
      return false;
    case 'array':
      if (depth >= maxDepth) return [];
      final item = _skeleton(schema.items, depth + 1, maxDepth);
      return item == null ? [] : [item];
    case 'object':
      if (depth >= maxDepth) return <String, Object?>{};
      return {
        for (final e in schema.properties.entries) e.key: _skeleton(e.value, depth + 1, maxDepth),
      };
    default:
      return null;
  }
}
