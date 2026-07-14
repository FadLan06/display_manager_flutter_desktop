import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService instance =
      DatabaseService._internal();

  DatabaseService._internal();

  Database? db;

  Future<Database> database() async {
    if (db != null) return db!;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();

    db = await databaseFactory.openDatabase(
      join(dbPath, 'display.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE display_config(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            display_id TEXT,
            fullscreen INTEGER
          )
          ''');
        },
      ),
    );

    return db!;
  }

  Future<void> saveConfig(
      String displayId,
      bool fullscreen,
      ) async {
    final d = await database();

    await d.delete('display_config');

    await d.insert('display_config', {
      'display_id': displayId,
      'fullscreen': fullscreen ? 1 : 0,
    });
  }

  Future<Map<String, dynamic>?> loadConfig() async {
    final d = await database();

    var result = await d.query('display_config');

    if (result.isEmpty) return null;

    return result.first;
  }
}