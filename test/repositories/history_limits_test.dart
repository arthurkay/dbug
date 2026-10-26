import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dbug/core/repositories/history_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late HistoryRepository repo;
  late int savedMaxBytes;
  late int savedMaxEntries;

  setUp(() async {
    await setupTestDatabase();
    repo = HistoryRepository();
    savedMaxBytes = HistoryRepository.maxBodyBytes;
    savedMaxEntries = HistoryRepository.maxEntries;
  });

  tearDown(() async {
    HistoryRepository.maxBodyBytes = savedMaxBytes;
    HistoryRepository.maxEntries = savedMaxEntries;
    await tearDownTestDatabase();
  });

  group('truncateUtf8', () {
    test('leaves short text alone', () {
      expect(truncateUtf8('abc', 10), ('abc', false));
      expect(truncateUtf8(null, 10), (null, false));
    });

    test('never splits a multi-byte character', () {
      // 'é' is 2 bytes, '😀' is 4 bytes.
      final (text, cut) = truncateUtf8('aé😀b', 4);
      expect(cut, isTrue);
      expect(text, 'aé');
      expect(utf8.encode(text!).length, lessThanOrEqualTo(4));
    });
  });

  test('response bodies over the cap are truncated and flagged', () async {
    HistoryRepository.maxBodyBytes = 10;
    final entry = await repo.addEntry(method: 'GET', url: 'u', responseBody: 'x' * 50);
    expect(entry.responseBody, 'x' * 10);
    expect(entry.responseTruncated, isTrue);

    final stored = await repo.getEntry(entry.id);
    expect(stored!.responseBody, 'x' * 10);
    expect(stored.responseTruncated, isTrue);
  });

  test('prunes to the newest maxEntries after each insert', () async {
    HistoryRepository.maxEntries = 3;
    for (var i = 0; i < 5; i++) {
      await repo.addEntry(method: 'GET', url: 'u$i');
    }
    expect(await repo.count(), 3);
    final urls = (await repo.getAllHistory()).map((e) => e.url).toList();
    expect(urls, ['u4', 'u3', 'u2']);
  });

  test('list rows omit body and headers; getEntry returns the full row', () async {
    final added = await repo.addEntry(
      method: 'GET',
      url: '{{baseUrl}}/users',
      resolvedUrl: 'https://api.test/users',
      responseBody: '{"ok":true}',
      responseHeaders: {'content-type': 'application/json'},
    );

    final listed = (await repo.getAllHistory()).single;
    expect(listed.responseBody, isNull);
    expect(listed.responseHeaders, '{}');
    expect(listed.url, '{{baseUrl}}/users');
    expect(listed.resolvedUrl, 'https://api.test/users');

    final full = await repo.getEntry(added.id);
    expect(full!.responseBody, '{"ok":true}');
    expect(jsonDecode(full.responseHeaders), {'content-type': 'application/json'});
  });

  test('getEntry returns null for an unknown id', () async {
    expect(await repo.getEntry('missing'), isNull);
  });

  test('getLatestByRequestId returns the newest full entry for that request', () async {
    await repo.addEntry(requestId: 'r1', method: 'GET', url: 'old', responseBody: 'a');
    await repo.addEntry(requestId: 'r2', method: 'GET', url: 'other', responseBody: 'b');
    await repo.addEntry(requestId: 'r1', method: 'POST', url: 'new', responseBody: 'c');

    final latest = await repo.getLatestByRequestId('r1');
    expect(latest!.url, 'new');
    expect(latest.method, 'POST');
    expect(latest.responseBody, 'c');
    expect(await repo.getLatestByRequestId('none'), isNull);
  });
}
