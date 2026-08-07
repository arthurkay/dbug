import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'app/app.dart';

const _defaultWidth = 1200.0;
const _defaultHeight = 800.0;
const _minWidth = 900.0;
const _minHeight = 600.0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManager.instance.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedWidth = prefs.getDouble('window_width') ?? _defaultWidth;
  final savedHeight = prefs.getDouble('window_height') ?? _defaultHeight;
  final savedX = prefs.getInt('window_x');
  final savedY = prefs.getInt('window_y');
  final isMaximized = prefs.getBool('window_maximized') ?? false;

  await windowManager.setSize(Size(savedWidth, savedHeight));
  await windowManager.setMinimumSize(const Size(_minWidth, _minHeight));
  if (savedX != null && savedY != null) {
    await windowManager.setPosition(Offset(savedX.toDouble(), savedY.toDouble()));
  }

  windowManager.addListener(_WindowPersistenceListener(prefs));

  if (isMaximized) {
    await windowManager.maximize();
  }

  runApp(
    const ProviderScope(
      child: DbugApp(),
    ),
  );
}

class _WindowPersistenceListener extends WindowListener {
  final SharedPreferences _prefs;
  bool _debouncing = false;

  _WindowPersistenceListener(this._prefs);

  @override
  void onWindowResize() => _debouncedSave();

  @override
  void onWindowMove() => _debouncedSave();

  @override
  void onWindowMaximize() => _saveMaximized(true);

  @override
  void onWindowUnmaximize() => _saveMaximized(false);

  void _debouncedSave() {
    if (_debouncing) return;
    _debouncing = true;
    Future.delayed(const Duration(milliseconds: 500), () async {
      _debouncing = false;
      await _saveBounds();
    });
  }

  Future<void> _saveBounds() async {
    final size = await windowManager.getSize();
    final position = await windowManager.getPosition();
    await _prefs.setDouble('window_width', size.width);
    await _prefs.setDouble('window_height', size.height);
    await _prefs.setInt('window_x', position.dx.toInt());
    await _prefs.setInt('window_y', position.dy.toInt());
  }

  Future<void> _saveMaximized(bool value) async {
    await _prefs.setBool('window_maximized', value);
  }
}
