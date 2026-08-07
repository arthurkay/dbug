import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

class DbugTheme {
  DbugTheme._();

  static ThemeData get light => createYaruTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: YaruColors.blue,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => createYaruTheme(
        colorScheme: ColorScheme.fromSeed(
          seedColor: YaruColors.blue,
          brightness: Brightness.dark,
        ),
      );
}
