import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/meal_log_entry.dart';
import 'app_database.dart';

/// SQLite-backed CRUD for the meal log.
class MealLogService {
  MealLogService(this._uid);

  final String _uid;
  final _controller = StreamController<List<MealLogEntry>>.broadcast();

  Future<void> _emitDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'meal_log',
      where: 'eatenAt >= ? AND eatenAt < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    final entries = rows
        .map((r) => MealLogEntry.fromMap(r['id'] as String, Map<String, dynamic>.from(r)))
        .toList()
      ..sort((a, b) => a.slot.index.compareTo(b.slot.index));
    _controller.add(entries);
  }

  Stream<List<MealLogEntry>> watchDay(DateTime day) {
    Future.microtask(() => _emitDay(day));
    return _controller.stream;
  }

  Future<List<MealLogEntry>> fetchSince(DateTime since) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'meal_log',
      where: 'eatenAt >= ?',
      whereArgs: [since.toIso8601String()],
    );
    return rows
        .map((r) => MealLogEntry.fromMap(r['id'] as String, Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<MealLogEntry> log({
    required MealSlot slot,
    required String name,
    String? recipeId,
    DateTime? eatenAt,
    double? grams,
    double? calories,
  }) async {
    final id = const Uuid().v4();
    final entry = MealLogEntry(
      id: id,
      slot: slot,
      name: name.trim(),
      recipeId: recipeId,
      eatenAt: eatenAt ?? DateTime.now(),
      grams: grams,
      calories: calories,
    );
    final db = await AppDatabase.instance.database;
    await db.insert('meal_log', {
      'id': entry.id,
      ...entry.toMap(),
    });
    await _emitDay(entry.eatenAt);
    return entry;
  }

  Future<void> remove(String id) async {
    final db = await AppDatabase.instance.database;
    // Get the entry first so we know which day to re-emit
    final rows = await db.query('meal_log', where: 'id = ?', whereArgs: [id]);
    await db.delete('meal_log', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final eatenAt = DateTime.tryParse(rows.first['eatenAt'] as String? ?? '');
      if (eatenAt != null) await _emitDay(eatenAt);
    }
  }
}
