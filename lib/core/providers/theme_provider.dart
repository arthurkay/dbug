import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

final themeModeProvider = StateProvider<shad.ThemeMode>((ref) {
  return shad.ThemeMode.system;
});
