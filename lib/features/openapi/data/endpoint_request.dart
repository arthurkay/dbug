import 'dart:convert';

import '../../../core/models/openapi_spec.dart';
import '../../../core/models/request_model.dart';
import 'schema_skeleton.dart';
import 'spec_paths.dart';

/// An unsaved request (empty id) for [endpoint], prefilled the same way spec
/// import prefills its collection: `{{baseUrl}}` + converted path params,
/// query/header parameters (example or empty), and a JSON body skeleton.
RequestModel endpointToRequestDraft(
  OpenApiEndpoint endpoint, {
  required bool hasBaseUrl,
  String? collectionId,
}) {
  final skeleton = schemaSkeleton(endpoint.requestBodySchema);
  final now = DateTime.now();
  return RequestModel(
    id: '',
    collectionId: collectionId,
    name: endpoint.summary ?? '${endpoint.method} ${endpoint.path}',
    method: endpoint.method,
    url: specRequestUrl(endpoint.path, hasBaseUrl: hasBaseUrl),
    queryParams: {
      for (final p in endpoint.parameters.where((p) => p.location == 'query')) p.name: p.example ?? '',
    },
    headers: {
      for (final p in endpoint.parameters.where((p) => p.location == 'header')) p.name: p.example ?? '',
    },
    bodyType: skeleton != null ? 'json' : null,
    body: skeleton != null ? const JsonEncoder.withIndent('  ').convert(skeleton) : null,
    createdAt: now,
    updatedAt: now,
  );
}
