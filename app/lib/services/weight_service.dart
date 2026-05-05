import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/weight_entry.dart';
import 'app_database.dart';

/// SQLite-backed CRUD for weight tracking.
class WeightService {
  WeightService(this._uid);

  final String _uid;
  final _controller = StreamController<List<WeightEntry>>.broadcast();

  Future<void> _emitDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'weight_entries',
      where: 'recordedAt >= ? AND recordedAt < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
    );
    final entries = rows
        .map((r) => WeightEntry.fromMap(r['id'] as String, {
              'period': r['period'],
              'weight': r['weight'],
              'recordedAt': r['recordedAt'],
            }))
        .toList()
      ..sort((a, b) => a.period.index.compareTo(b.period.index));
    _controller.add(entries);
  }

  Stream<List<WeightEntry>> watchDay(DateTime day) {
    Future.microtask(() => _emitDay(day));
    return _controller.stream;
  }

  Future<List<WeightEntry>> fetchRange(DateTime from, DateTime to) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'weight_entries',
      where: 'recordedAt >= ? AND recordedAt < ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'recordedAt ASC',
    );
    return rows
        .map((r) => WeightEntry.fromMap(r['id'] as String, {
              'period': r['period'],
              'weight': r['weight'],
              'recordedAt': r['recordedAt'],
            }))
        .toList();
  }

  Future<WeightEntry> add({
    required WeightPeriod period,
    required double weight,
    DateTime? recordedAt,
  }) async {
    final id = const Uuid().v4();
    final entry = WeightEntry(
      id: id,
      period: period,
      weight: weight,
      recordedAt: recordedAt ?? DateTime.now(),
    );
    final db = await AppDatabase.instance.database;
    await db.insert('weight_entries', {
      'id': entry.id,
      ...entry.toMap(),
    });
    await _emitDay(entry.recordedAt);
    return entry;
  }

  Future<void> remove(String id) async {
    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('weight_entries', where: 'id = ?', whereArgs: [id]);
    await db.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final recordedAt =
          DateTime.tryParse(rows.first['recordedAt'] as String? ?? '');
      if (recordedAt != null) await _emitDay(recordedAt);
    }
  }
}
