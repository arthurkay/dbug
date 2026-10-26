import 'dart:convert';

import 'package:dbug/core/http/http_client.dart';
import 'package:dbug/shared/widgets/response_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A pretty-printable JSON array of roughly [targetBytes].
String _jsonOfSize(int targetBytes) {
  final items = <Map<String, Object?>>[];
  var size = 2;
  var i = 0;
  while (size < targetBytes) {
    final item = {'id': i, 'name': 'item $i', 'active': i.isEven, 'tags': ['a', 'b'], 'note': null};
    size += jsonEncode(item).length + 1;
    items.add(item);
    i++;
  }
  return jsonEncode(items);
}

Future<StateSetter> _pumpView(WidgetTester tester, HttpResponse response) async {
  late StateSetter setOuter;
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          setOuter = setState;
          return SizedBox(height: 600, width: 900, child: ResponseView(response: response));
        }),
      ),
    ),
  ));
  return setOuter;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ResponseView.debugRenderCount = 0;
    ResponseView.debugPendingRender = null;
  });

  for (final (label, bytes, highlighted) in [
    ('2 MB (plain)', 2 * 1024 * 1024, false),
    // Pretty-printing roughly doubles the size; the highlight limit applies after.
    ('150 KB (highlighted)', 150 * 1024, true),
  ]) {
    testWidgets('$label JSON renders off the UI thread; parent rebuilds reuse it', (tester) async {
      final body = _jsonOfSize(bytes);
      final response = HttpResponse(
        statusCode: 200,
        headers: const {'content-type': 'application/json'},
        body: body,
        timeMs: 1,
        sizeBytes: body.length,
      );

      final setOuter = await _pumpView(tester, response);
      // Large bodies show a placeholder while the isolate works.
      expect(find.textContaining('Preparing'), findsOneWidget);
      expect(ResponseView.debugPendingRender, isNotNull);

      // The isolate runs in real time, but its result is delivered through
      // the test's fake-async zone: let real time pass, then pump.
      final sw = Stopwatch()..start();
      while (find.textContaining('Preparing').evaluate().isNotEmpty) {
        if (sw.elapsed > const Duration(seconds: 60)) fail('render did not finish');
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
      }

      expect(find.textContaining('Preparing'), findsNothing);
      expect(find.text('1'), findsOneWidget, reason: 'first line number is visible');
      expect(
        find.textContaining('Syntax highlighting disabled'),
        highlighted ? findsNothing : findsOneWidget,
      );
      expect(ResponseView.debugRenderCount, 1);

      // Unrelated parent rebuilds (keystrokes, split drags) must not redo it.
      for (var i = 0; i < 5; i++) {
        setOuter(() {});
        await tester.pump();
      }
      expect(ResponseView.debugRenderCount, 1);

      // Only a visible window of rows is built, not every line.
      expect(find.byType(Text).evaluate().length, lessThan(400));
    });
  }

  testWidgets('toggling Pretty/Raw re-renders once per change', (tester) async {
    const body = '{"a":1,"b":2}';
    await _pumpView(
      tester,
      const HttpResponse(
        statusCode: 200,
        headers: {'content-type': 'application/json'},
        body: body,
        timeMs: 1,
        sizeBytes: 13,
      ),
    );
    expect(ResponseView.debugRenderCount, 1);
    expect(find.textContaining('"a": 1'), findsOneWidget);

    await tester.tap(find.text('Raw'));
    await tester.pump();
    expect(ResponseView.debugRenderCount, 2);
    expect(find.text(body), findsOneWidget);
  });

  testWidgets('binary and truncated notices', (tester) async {
    await _pumpView(
      tester,
      const HttpResponse(
        statusCode: 200,
        headers: {'content-type': 'image/png'},
        body: '<binary content: 10 bytes, image/png>',
        timeMs: 1,
        sizeBytes: 10,
        isBinary: true,
        isTruncated: true,
      ),
    );
    expect(find.textContaining('Binary response'), findsOneWidget);
    expect(find.textContaining('truncated'), findsOneWidget);
    expect(ResponseView.debugRenderCount, 0);
  });
}
