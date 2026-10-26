import 'dart:convert';

import 'package:dbug/core/models/openapi_spec.dart';
import 'package:dbug/features/openapi/data/endpoint_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('endpointToRequestDraft (spec browser Send/Save)', () {
    const endpoint = OpenApiEndpoint(
      path: '/users/{user-id}/posts',
      method: 'POST',
      summary: 'Create post',
      parameters: [
        OpenApiParameter(name: 'user-id', location: 'path', required: true),
        OpenApiParameter(name: 'draft', location: 'query', example: 'true'),
        OpenApiParameter(name: 'X-Trace', location: 'header'),
      ],
      requestBodySchema: OpenApiSchema(
        type: 'object',
        properties: {
          'title': OpenApiSchema(type: 'string'),
          'views': OpenApiSchema(type: 'integer'),
        },
      ),
    );

    test('uses variable syntax for base URL and path params', () {
      final draft = endpointToRequestDraft(endpoint, hasBaseUrl: true);
      expect(draft.url, '{{baseUrl}}/users/{{user-id}}/posts');
      expect(endpointToRequestDraft(endpoint, hasBaseUrl: false).url, '/users/{{user-id}}/posts');
    });

    test('is an unsaved draft carrying the collection id', () {
      final draft = endpointToRequestDraft(endpoint, hasBaseUrl: true, collectionId: 'c1');
      expect(draft.id, isEmpty);
      expect(draft.collectionId, 'c1');
      expect(draft.name, 'Create post');
    });

    test('prefills query, header params and a JSON body skeleton', () {
      final draft = endpointToRequestDraft(endpoint, hasBaseUrl: true);
      expect(draft.queryParams, {'draft': 'true'});
      expect(draft.headers, {'X-Trace': ''});
      expect(draft.bodyType, 'json');
      expect(jsonDecode(draft.body!), {'title': '', 'views': 0});
    });

    test('has no body when the endpoint has no request schema', () {
      const get = OpenApiEndpoint(path: '/ping', method: 'GET');
      final draft = endpointToRequestDraft(get, hasBaseUrl: false);
      expect(draft.bodyType, isNull);
      expect(draft.body, isNull);
      expect(draft.name, 'GET /ping');
    });
  });
}
