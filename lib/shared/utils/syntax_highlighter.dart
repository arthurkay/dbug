import 'package:flutter/widgets.dart';

class SyntaxColors {
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

  const SyntaxColors({
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

const syntaxThemeNames = ['Default', 'GitHub', 'Monokai', 'Dracula', 'OneDark', 'Solarized'];

const _defaultDark = SyntaxColors(
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

const _defaultLight = SyntaxColors(
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

const _githubDark = SyntaxColors(
  key: Color(0xFF79C0FF),
  string: Color(0xFFA5D6FF),
  number: Color(0xFF79C0FF),
  boolValue: Color(0xFFFF7B72),
  nullValue: Color(0xFFFF7B72),
  tag: Color(0xFF7EE787),
  attrName: Color(0xFF79C0FF),
  attrValue: Color(0xFFA5D6FF),
  comment: Color(0xFF8B949E),
  punctuation: Color(0xFFC9D1D9),
  defaultText: Color(0xFFC9D1D9),
);

const _githubLight = SyntaxColors(
  key: Color(0xFF0550AE),
  string: Color(0xFF0A3069),
  number: Color(0xFF0550AE),
  boolValue: Color(0xFFCF222E),
  nullValue: Color(0xFFCF222E),
  tag: Color(0xFF116329),
  attrName: Color(0xFF0550AE),
  attrValue: Color(0xFF0A3069),
  comment: Color(0xFF6E7781),
  punctuation: Color(0xFF24292F),
  defaultText: Color(0xFF24292F),
);

const _monokaiDark = SyntaxColors(
  key: Color(0xFFF92672),
  string: Color(0xFFE6DB74),
  number: Color(0xFFAE81FF),
  boolValue: Color(0xFFA6E22E),
  nullValue: Color(0xFFA6E22E),
  tag: Color(0xFFF92672),
  attrName: Color(0xFFA6E22E),
  attrValue: Color(0xFFE6DB74),
  comment: Color(0xFF75715E),
  punctuation: Color(0xFFF8F8F2),
  defaultText: Color(0xFFF8F8F2),
);

const _monokaiLight = SyntaxColors(
  key: Color(0xFFC41A16),
  string: Color(0xFF1B8937),
  number: Color(0xFF6C36A7),
  boolValue: Color(0xFFC41A16),
  nullValue: Color(0xFFC41A16),
  tag: Color(0xFFC41A16),
  attrName: Color(0xFF1B8937),
  attrValue: Color(0xFF1B8937),
  comment: Color(0xFF8C8C8C),
  punctuation: Color(0xFF333333),
  defaultText: Color(0xFF333333),
);

const _draculaDark = SyntaxColors(
  key: Color(0xFFFF79C6),
  string: Color(0xFFF1FA8C),
  number: Color(0xFFBD93F9),
  boolValue: Color(0xFF50FA7B),
  nullValue: Color(0xFF50FA7B),
  tag: Color(0xFFFF79C6),
  attrName: Color(0xFF50FA7B),
  attrValue: Color(0xFFF1FA8C),
  comment: Color(0xFF6272A4),
  punctuation: Color(0xFFF8F8F2),
  defaultText: Color(0xFFF8F8F2),
);

const _draculaLight = SyntaxColors(
  key: Color(0xFFA626A4),
  string: Color(0xFF50A14F),
  number: Color(0xFFA626A4),
  boolValue: Color(0xFFE45649),
  nullValue: Color(0xFFE45649),
  tag: Color(0xFFA626A4),
  attrName: Color(0xFF50A14F),
  attrValue: Color(0xFF50A14F),
  comment: Color(0xFFA0A1A7),
  punctuation: Color(0xFF383A42),
  defaultText: Color(0xFF383A42),
);

const _oneDarkDark = SyntaxColors(
  key: Color(0xFFE06C75),
  string: Color(0xFF98C379),
  number: Color(0xFFD19A66),
  boolValue: Color(0xFF56B6C2),
  nullValue: Color(0xFF56B6C2),
  tag: Color(0xFFE06C75),
  attrName: Color(0xFFD19A66),
  attrValue: Color(0xFF98C379),
  comment: Color(0xFF5C6370),
  punctuation: Color(0xFFABB2BF),
  defaultText: Color(0xFFABB2BF),
);

const _oneDarkLight = SyntaxColors(
  key: Color(0xFFE45649),
  string: Color(0xFF50A14F),
  number: Color(0xFF986801),
  boolValue: Color(0xFF0184BC),
  nullValue: Color(0xFF0184BC),
  tag: Color(0xFFE45649),
  attrName: Color(0xFF986801),
  attrValue: Color(0xFF50A14F),
  comment: Color(0xFFA0A1A7),
  punctuation: Color(0xFF383A42),
  defaultText: Color(0xFF383A42),
);

const _solarizedDark = SyntaxColors(
  key: Color(0xFF268BD2),
  string: Color(0xFF2AA198),
  number: Color(0xFFD33682),
  boolValue: Color(0xFF859900),
  nullValue: Color(0xFF859900),
  tag: Color(0xFF268BD2),
  attrName: Color(0xFF859900),
  attrValue: Color(0xFF2AA198),
  comment: Color(0xFF586E75),
  punctuation: Color(0xFF93A1A1),
  defaultText: Color(0xFF839496),
);

const _solarizedLight = SyntaxColors(
  key: Color(0xFF268BD2),
  string: Color(0xFF2AA198),
  number: Color(0xFFD33682),
  boolValue: Color(0xFF859900),
  nullValue: Color(0xFF859900),
  tag: Color(0xFF268BD2),
  attrName: Color(0xFF859900),
  attrValue: Color(0xFF2AA198),
  comment: Color(0xFF93A1A1),
  punctuation: Color(0xFF586E75),
  defaultText: Color(0xFF657B83),
);

class SyntaxHighlighter {
  SyntaxHighlighter._();

  static SyntaxColors getColors(String themeName, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (themeName) {
      case 'GitHub':
        return isDark ? _githubDark : _githubLight;
      case 'Monokai':
        return isDark ? _monokaiDark : _monokaiLight;
      case 'Dracula':
        return isDark ? _draculaDark : _draculaLight;
      case 'OneDark':
        return isDark ? _oneDarkDark : _oneDarkLight;
      case 'Solarized':
        return isDark ? _solarizedDark : _solarizedLight;
      default:
        return isDark ? _defaultDark : _defaultLight;
    }
  }

  static List<TextSpan> highlight(String body, String contentType, Brightness brightness, {String themeName = 'Default'}) {
    final c = getColors(themeName, brightness);
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

  static List<TextSpan> _highlightJson(String body, SyntaxColors c) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'"([^"\\]|\\.)*"'
      r'|[-+]?\d*\.?\d+([eE][-+]?\d+)?'
      r'|true|false'
      r'|null'
      r'|[{}\[\]:,]'
      r'|[ \t]+'
      r'|\n'
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

  static List<TextSpan> _highlightXml(String body, SyntaxColors c) {
    final spans = <TextSpan>[];
    final regex = RegExp(
      r'<!--[\s\S]*?-->'
      r'|<\?[\s\S]*?\?>'
      r'|</?[a-zA-Z][\w.-]*'
      r'|/>|>'
      r'|\s+[a-zA-Z][\w.-]*='
      r'|"[^"]*"'
      r"|'[^']*'"
      r'|[^<]+'
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

  static List<TextSpan> _highlightYaml(String body, SyntaxColors c) {
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
