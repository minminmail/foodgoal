import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton database helper for FoodGoal.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'foodgoal.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pantry (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            quantity TEXT NOT NULL,
            section TEXT NOT NULL,
            addedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE meal_log (
            id TEXT PRIMARY KEY,
            slot TEXT NOT NULL,
            name TEXT NOT NULL,
            recipeId TEXT,
            eatenAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE shopping (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            forRecipeTitle TEXT,
            checked INTEGER NOT NULL DEFAULT 0,
            addedAt TEXT NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_meal_log_eatenAt ON meal_log(eatenAt)',
        );
        await db.execute(
          'CREATE INDEX idx_pantry_addedAt ON pantry(addedAt)',
        );
        await db.execute(
          'CREATE INDEX idx_shopping_addedAt ON shopping(addedAt)',
        );
      },
    );
  }
}
