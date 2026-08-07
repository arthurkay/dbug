import 'package:flutter/widgets.dart';

class SyntaxHighlighter {
  SyntaxHighlighter._();

  static Color _keyColor = const Color(0xFF7DD3FC);
  static Color _stringColor = const Color(0xFF86EFAC);
  static Color _numberColor = const Color(0xFF93C5FD);
  static Color _boolColor = const Color(0xFFFCA5A5);
  static Color _nullColor = const Color(0xFFFCA5A5);
  static Color _tagColor = const Color(0xFF7DD3FC);
  static Color _attrNameColor = const Color(0xFF93C5FD);
  static Color _attrValueColor = const Color(0xFF86EFAC);
  static Color _commentColor = const Color(0xFF71717A);
  static Color _punctuationColor = const Color(0xFFA1A1AA);
  static Color _defaultColor = const Color(0xFFFAFAFA);

  static List<TextSpan> highlight(String body, String contentType) {
    if (contentType.contains('json') || _looksLikeJson(body)) {
      return _highlightJson(body);
    } else if (contentType.contains('xml') || _looksLikeXml(body)) {
      return _highlightXml(body);
    } else if (contentType.contains('yaml') || contentType.contains('yml') || _looksLikeYaml(body)) {
      return _highlightYaml(body);
    }
    return [TextSpan(text: body, style: TextStyle(color: _defaultColor, fontFamily: 'monospace', fontSize: 12))];
  }

  static bool _looksLikeJson(String body) {
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }

  static bool _looksLikeXml(String body) {
    final trimmed = body.trimLeft();
    return trimmed.startsWith('<');
  }

  static bool _looksLikeYaml(String body) {
    final trimmed = body.trimLeft();
    return trimmed.contains(': ') && !trimmed.startsWith('{') && !trimmed.startsWith('<');
  }

  static List<TextSpan> _highlightJson(String body) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'"([^"\\]|\\.)*"'   // strings (including keys)
      r'|[-+]?\d*\.?\d+([eE][-+]?\d+)?'  // numbers
      r'|true|false'        // bools
      r'|null'              // null
      r'|[{}\[\]:,]'       // punctuation
      r'|[ \t]+'            // whitespace
      r'|\n'                // newlines
    );

    int lastEnd = 0;
    bool expectKey = true;

    for (final match in regex.allMatches(body)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: body.substring(lastEnd, match.start), style: TextStyle(color: _defaultColor, fontFamily: 'monospace', fontSize: 12)));
      }

      final token = match.group(0)!;
      Color color;
      FontWeight weight = FontWeight.normal;

      if (token.startsWith('"')) {
        if (expectKey) {
          color = _keyColor;
          weight = FontWeight.w600;
          expectKey = false;
        } else {
          color = _stringColor;
        }
        if (token == '"') {
          expectKey = true;
        }
      } else if (token == ':' || token == ',' || token == '{' || token == '}' || token == '[' || token == ']') {
        color = _punctuationColor;
        if (token == ':' || token == ',') {
          expectKey = true;
        } else if (token == '{' || token == '[') {
          expectKey = true;
        }
      } else if (token == 'true' || token == 'false') {
        color = _boolColor;
      } else if (token == 'null') {
        color = _nullColor;
      } else if (RegExp(r'^[-+]?\d').hasMatch(token)) {
        color = _numberColor;
      } else {
        color = _defaultColor;
      }

      spans.add(TextSpan(
        text: token,
        style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12, fontWeight: weight),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < body.length) {
      spans.add(TextSpan(text: body.substring(lastEnd), style: TextStyle(color: _defaultColor, fontFamily: 'monospace', fontSize: 12)));
    }

    return spans;
  }

  static List<TextSpan> _highlightXml(String body) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'<!--[\s\S]*?-->'           // comments
      r'|<\?[\s\S]*?\?>'           // processing instructions
      r'|</?[a-zA-Z][\w.-]*'      // opening/closing tags
      r'|/>|>'                     // tag end
      r'|\s+[a-zA-Z][\w.-]*='     // attribute names
      r'|"[^"]*"'                  // double-quoted attribute values
      r"|'[^']*'"                  // single-quoted attribute values
      r'|[^<]+'                    // text content
    );

    int lastEnd = 0;

    for (final match in regex.allMatches(body)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: body.substring(lastEnd, match.start), style: TextStyle(color: _defaultColor, fontFamily: 'monospace', fontSize: 12)));
      }

      final token = match.group(0)!;
      Color color;

      if (token.startsWith('<!--')) {
        color = _commentColor;
      } else if (token.startsWith('<?')) {
        color = _commentColor;
      } else if (token.startsWith('</')) {
        color = _tagColor;
      } else if (token.startsWith('<')) {
        color = _tagColor;
      } else if (token == '/>' || token == '>') {
        color = _punctuationColor;
      } else if (token.startsWith(' ') && token.endsWith('=')) {
        color = _attrNameColor;
      } else if (token.startsWith('"') || token.startsWith("'")) {
        color = _attrValueColor;
      } else {
        color = _defaultColor;
      }

      spans.add(TextSpan(text: token, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12)));
      lastEnd = match.end;
    }

    if (lastEnd < body.length) {
      spans.add(TextSpan(text: body.substring(lastEnd), style: TextStyle(color: _defaultColor, fontFamily: 'monospace', fontSize: 12)));
    }

    return spans;
  }

  static List<TextSpan> _highlightYaml(String body) {
    final spans = <TextSpan>[];
    final lines = body.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) spans.add(TextSpan(text: '\n', style: TextStyle(color: _defaultColor, fontFamily: 'monospace', fontSize: 12)));

      if (line.trimLeft().startsWith('#')) {
        spans.add(TextSpan(text: line, style: TextStyle(color: _commentColor, fontFamily: 'monospace', fontSize: 12)));
        continue;
      }

      final colonIndex = line.indexOf(': ');
      if (colonIndex >= 0) {
        final key = line.substring(0, colonIndex + 1);
        final value = line.substring(colonIndex + 1);

        spans.add(TextSpan(text: key, style: TextStyle(color: _keyColor, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)));

        if (value.isNotEmpty) {
          final trimmedValue = value.trimLeft();
          Color valueColor;

          if (trimmedValue == 'true' || trimmedValue == 'false') {
            valueColor = _boolColor;
          } else if (trimmedValue == 'null' || trimmedValue == '~') {
            valueColor = _nullColor;
          } else if (RegExp(r'^[-+]?\d').hasMatch(trimmedValue)) {
            valueColor = _numberColor;
          } else if (trimmedValue.startsWith('"') || trimmedValue.startsWith("'")) {
            valueColor = _stringColor;
          } else {
            valueColor = _defaultColor;
          }

          spans.add(TextSpan(text: value, style: TextStyle(color: valueColor, fontFamily: 'monospace', fontSize: 12)));
        }
      } else if (line.trimLeft().startsWith('- ')) {
        final dashEnd = line.indexOf('- ') + 2;
        final indent = line.substring(0, dashEnd);
        final rest = line.substring(dashEnd);

        spans.add(TextSpan(text: indent, style: TextStyle(color: _punctuationColor, fontFamily: 'monospace', fontSize: 12)));

        if (rest.isNotEmpty) {
          final trimmedRest = rest.trimLeft();
          Color valueColor;

          if (trimmedRest == 'true' || trimmedRest == 'false') {
            valueColor = _boolColor;
          } else if (trimmedRest == 'null' || trimmedRest == '~') {
            valueColor = _nullColor;
          } else if (RegExp(r'^[-+]?\d').hasMatch(trimmedRest)) {
            valueColor = _numberColor;
          } else {
            valueColor = _stringColor;
          }

          spans.add(TextSpan(text: rest, style: TextStyle(color: valueColor, fontFamily: 'monospace', fontSize: 12)));
        }
      } else {
        spans.add(TextSpan(text: line, style: TextStyle(color: _defaultColor, fontFamily: 'monospace', fontSize: 12)));
      }
    }

    return spans;
  }
}
