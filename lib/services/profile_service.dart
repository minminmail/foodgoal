import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';
import 'app_database.dart';

/// SQLite-backed CRUD for the single user profile.
class ProfileService {
  ProfileService(this._uid);

  final String _uid;

  /// Fetch the stored profile, or null if none saved yet.
  Future<UserProfile?> get() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserProfile.fromMap(row['id'] as String, row);
  }

  /// Insert or replace the single profile row.
  Future<void> save(UserProfile profile) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'user_profile',
      {'id': profile.id, ...profile.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Helper: creates a new profile with a fresh id if none exists yet.
  String newId() => const Uuid().v4();
}
