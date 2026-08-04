import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, shad.ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<shad.ThemeMode> {
  ThemeModeNotifier() : super(shad.ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kThemeKey);
    if (value == 'dark') {
      state = shad.ThemeMode.dark;
    } else if (value == 'light') {
      state = shad.ThemeMode.light;
    } else {
      state = shad.ThemeMode.system;
    }
  }

  Future<void> setMode(shad.ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }
}
