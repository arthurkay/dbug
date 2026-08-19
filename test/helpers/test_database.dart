import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dbug/core/database/database_service.dart';

Future<Database> setupTestDatabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactoryFfi.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
      version: 6,
      // Use the real schema so tests can never drift from production.
      onCreate: (db, version) => DatabaseService.createSchema(db),
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );

  await DatabaseService.setTestDatabase(db);
  return db;
}

Future<void> tearDownTestDatabase() async {
  await DatabaseService.resetState();
}
