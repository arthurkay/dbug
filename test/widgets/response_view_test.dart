import 'package:dbug/shared/widgets/response_view.dart';
import 'package:flutter/painting.dart';
import 'dart:ui' show Brightness;
import 'package:flutter_test/flutter_test.dart';

String _rowText(List<TextSpan> row) => row.map((s) => s.text).join();

void main() {
  group('splitSpansIntoLines', () {
    const red = TextStyle(color: Color(0xFFFF0000));
    const blue = TextStyle(color: Color(0xFF0000FF));

    test('splits at newlines inside and between spans, keeping styles', () {
      final out = splitSpansIntoLines(const [
        TextSpan(text: '{\n  ', style: red),
        TextSpan(text: '"a"', style: blue),
        TextSpan(text: ': 1\n}', style: red),
      ]);
      expect(out.lines.map(_rowText).toList(), ['{', '  "a": 1', '}']);
      expect(out.lineNumbers, [1, 2, 3]);
      expect(out.lines[1][1].style, blue);
      expect(out.lines[1][2].style, red);
      expect(out.maxLineChars, 8);
    });

    test('keeps empty lines, including a trailing one', () {
      final out = splitSpansIntoLines(const [TextSpan(text: 'a\n\nb\n')]);
      expect(out.lines.map(_rowText).toList(), ['a', '', 'b', '']);
      expect(out.lineNumbers, [1, 2, 3, 4]);
    });

    test('long lines continue on rows numbered 0', () {
      final out = splitSpansIntoLines(
        const [TextSpan(text: 'abcdefghij', style: red), TextSpan(text: '\nxy')],
        maxLineChars: 4,
      );
      expect(out.lines.map(_rowText).toList(), ['abcd', 'efgh', 'ij', 'xy']);
      expect(out.lineNumbers, [1, 0, 0, 2]);
      expect(out.lines[1].single.style, red);
      expect(out.maxLineChars, 4);
    });
  });

  group('renderBody', () {
    RenderedBody render(String body, {bool pretty = true}) => renderBody(
          body: body,
          prettyJson: pretty,
          contentType: 'application/json',
          themeName: 'Default',
          brightness: Brightness.dark,
        );

    test('pretty-prints JSON and highlights it', () {
      final r = render('{"a":1,"b":[true,null]}');
      expect(r.highlighted, isTrue);
      expect(r.text, contains('\n  "a": 1'));
      expect(r.rowCount, r.text.split('\n').length);
    });

    test('raw view keeps the body as-is', () {
      const body = '{"a":1}';
      expect(render(body, pretty: false).text, body);
    });

    test('invalid JSON is shown unchanged', () {
      expect(render('{nope', pretty: true).text, '{nope');
    });

    test('large bodies skip highlighting and split long lines', () {
      final body = 'x' * (highlightLimit + 10);
      final r = render(body, pretty: false);
      expect(r.highlighted, isFalse);
      expect(r.plainLines, isNotNull);
      expect(r.maxLineChars, maxDisplayLineChars);
      expect(r.lineNumbers.first, 1);
      expect(r.lineNumbers.skip(1).every((n) => n == 0), isTrue);
      expect(r.plainLines!.join().length, body.length);
    });
  });
}
