import 'package:flutter/widgets.dart';

class _Colors {
  final Color key;
  final Color string;
  final Color number;
  final Color boolValue;
  final Color nullValue;
  final Color tag;
  final Color attrName;
  final Color attrValue;
  final Color comment;
  final Color punctuation;
  final Color defaultText;

  const _Colors({
    required this.key,
    required this.string,
    required this.number,
    required this.boolValue,
    required this.nullValue,
    required this.tag,
    required this.attrName,
    required this.attrValue,
    required this.comment,
    required this.punctuation,
    required this.defaultText,
  });
}

const _darkColors = _Colors(
  key: Color(0xFF7DD3FC),
  string: Color(0xFF86EFAC),
  number: Color(0xFF93C5FD),
  boolValue: Color(0xFFFCA5A5),
  nullValue: Color(0xFFFCA5A5),
  tag: Color(0xFF7DD3FC),
  attrName: Color(0xFF93C5FD),
  attrValue: Color(0xFF86EFAC),
  comment: Color(0xFF71717A),
  punctuation: Color(0xFFA1A1AA),
  defaultText: Color(0xFFFAFAFA),
);

const _lightColors = _Colors(
  key: Color(0xFF2563EB),
  string: Color(0xFF16A34A),
  number: Color(0xFF7C3AED),
  boolValue: Color(0xFFDC2626),
  nullValue: Color(0xFFDC2626),
  tag: Color(0xFF2563EB),
  attrName: Color(0xFF7C3AED),
  attrValue: Color(0xFF16A34A),
  comment: Color(0xFF9CA3AF),
  punctuation: Color(0xFF6B7280),
  defaultText: Color(0xFF09090B),
);

class SyntaxHighlighter {
  SyntaxHighlighter._();

  static _Colors _getColors(Brightness brightness) {
    return brightness == Brightness.dark ? _darkColors : _lightColors;
  }

  static List<TextSpan> highlight(String body, String contentType, Brightness brightness) {
    final c = _getColors(brightness);
    if (contentType.contains('json') || _looksLikeJson(body)) {
      return _highlightJson(body, c);
    } else if (contentType.contains('xml') || _looksLikeXml(body)) {
      return _highlightXml(body, c);
    } else if (contentType.contains('yaml') || contentType.contains('yml') || _looksLikeYaml(body)) {
      return _highlightYaml(body, c);
    }
    return [TextSpan(text: body, style: TextStyle(color: c.defaultText, fontFamily: 'monospace', fontSize: 12))];
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

  static List<TextSpan> _highlightJson(String body, _Colors c) {
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
        spans.add(TextSpan(text: body.substring(lastEnd, match.start), style: TextStyle(color: c.defaultText, fontFamily: 'monospace', fontSize: 12)));
      }

      final token = match.group(0)!;
      Color color;
      FontWeight weight = FontWeight.normal;

      if (token.startsWith('"')) {
        if (expectKey) {
          color = c.key;
          weight = FontWeight.w600;
          expectKey = false;
        } else {
          color = c.string;
        }
        if (token == '"') {
          expectKey = true;
        }
      } else if (token == ':' || token == ',' || token == '{' || token == '}' || token == '[' || token == ']') {
        color = c.punctuation;
        if (token == ':' || token == ',') {
          expectKey = true;
        } else if (token == '{' || token == '[') {
          expectKey = true;
        }
      } else if (token == 'true' || token == 'false') {
        color = c.boolValue;
      } else if (token == 'null') {
        color = c.nullValue;
      } else if (RegExp(r'^[-+]?\d').hasMatch(token)) {
        color = c.number;
      } else {
        color = c.defaultText;
      }

      spans.add(TextSpan(
        text: token,
        style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12, fontWeight: weight),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < body.length) {
      spans.add(TextSpan(text: body.substring(lastEnd), style: TextStyle(color: c.defaultText, fontFamily: 'monospace', fontSize: 12)));
    }

    return spans;
  }

  static List<TextSpan> _highlightXml(String body, _Colors c) {
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
        spans.add(TextSpan(text: body.substring(lastEnd, match.start), style: TextStyle(color: c.defaultText, fontFamily: 'monospace', fontSize: 12)));
      }

      final token = match.group(0)!;
      Color color;

      if (token.startsWith('<!--')) {
        color = c.comment;
      } else if (token.startsWith('<?')) {
        color = c.comment;
      } else if (token.startsWith('</')) {
        color = c.tag;
      } else if (token.startsWith('<')) {
        color = c.tag;
      } else if (token == '/>' || token == '>') {
        color = c.punctuation;
      } else if (token.startsWith(' ') && token.endsWith('=')) {
        color = c.attrName;
      } else if (token.startsWith('"') || token.startsWith("'")) {
        color = c.attrValue;
      } else {
        color = c.defaultText;
      }

      spans.add(TextSpan(text: token, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12)));
      lastEnd = match.end;
    }

    if (lastEnd < body.length) {
      spans.add(TextSpan(text: body.substring(lastEnd), style: TextStyle(color: c.defaultText, fontFamily: 'monospace', fontSize: 12)));
    }

    return spans;
  }

  static List<TextSpan> _highlightYaml(String body, _Colors c) {
    final spans = <TextSpan>[];
    final lines = body.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (i > 0) spans.add(TextSpan(text: '\n', style: TextStyle(color: c.defaultText, fontFamily: 'monospace', fontSize: 12)));

      if (line.trimLeft().startsWith('#')) {
        spans.add(TextSpan(text: line, style: TextStyle(color: c.comment, fontFamily: 'monospace', fontSize: 12)));
        continue;
      }

      final colonIndex = line.indexOf(': ');
      if (colonIndex >= 0) {
        final key = line.substring(0, colonIndex + 1);
        final value = line.substring(colonIndex + 1);

        spans.add(TextSpan(text: key, style: TextStyle(color: c.key, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600)));

        if (value.isNotEmpty) {
          final trimmedValue = value.trimLeft();
          Color valueColor;

          if (trimmedValue == 'true' || trimmedValue == 'false') {
            valueColor = c.boolValue;
          } else if (trimmedValue == 'null' || trimmedValue == '~') {
            valueColor = c.nullValue;
          } else if (RegExp(r'^[-+]?\d').hasMatch(trimmedValue)) {
            valueColor = c.number;
          } else if (trimmedValue.startsWith('"') || trimmedValue.startsWith("'")) {
            valueColor = c.string;
          } else {
            valueColor = c.defaultText;
          }

          spans.add(TextSpan(text: value, style: TextStyle(color: valueColor, fontFamily: 'monospace', fontSize: 12)));
        }
      } else if (line.trimLeft().startsWith('- ')) {
        final dashEnd = line.indexOf('- ') + 2;
        final indent = line.substring(0, dashEnd);
        final rest = line.substring(dashEnd);

        spans.add(TextSpan(text: indent, style: TextStyle(color: c.punctuation, fontFamily: 'monospace', fontSize: 12)));

        if (rest.isNotEmpty) {
          final trimmedRest = rest.trimLeft();
          Color valueColor;

          if (trimmedRest == 'true' || trimmedRest == 'false') {
            valueColor = c.boolValue;
          } else if (trimmedRest == 'null' || trimmedRest == '~') {
            valueColor = c.nullValue;
          } else if (RegExp(r'^[-+]?\d').hasMatch(trimmedRest)) {
            valueColor = c.number;
          } else {
            valueColor = c.string;
          }

          spans.add(TextSpan(text: rest, style: TextStyle(color: valueColor, fontFamily: 'monospace', fontSize: 12)));
        }
      } else {
        spans.add(TextSpan(text: line, style: TextStyle(color: c.defaultText, fontFamily: 'monospace', fontSize: 12)));
      }
    }

    return spans;
  }
}
