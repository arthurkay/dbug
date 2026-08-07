import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSyntaxThemeKey = 'syntax_theme';

final syntaxThemeNameProvider = StateNotifierProvider<SyntaxThemeNotifier, String>((ref) {
  return SyntaxThemeNotifier();
});

class SyntaxThemeNotifier extends StateNotifier<String> {
  SyntaxThemeNotifier() : super('Default') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kSyntaxThemeKey) ?? 'Default';
  }

  Future<void> setTheme(String name) async {
    state = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSyntaxThemeKey, name);
  }
}
