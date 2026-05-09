import 'dart:async';
import 'package:health/health.dart';
import 'package:uuid/uuid.dart';

import '../models/weight_entry.dart';
import 'app_database.dart';
import 'health_connect_service.dart';

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

  /// Import weight entries from Health Connect for the last [days] days.
  /// Returns the number of new entries imported (skips duplicates).
  Future<int> syncFromHealthConnect(HealthConnectService hc, {int days = 30}) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days));
    final dataPoints = await hc.fetchWeights(from, now);

    // Fetch existing entries for deduplication
    final existing = await fetchRange(from, now);
    final existingKeys = <String>{};
    for (final e in existing) {
      // Key: weight rounded to 1 decimal + recordedAt rounded to minute
      final key = _dedupeKey(e.weight, e.recordedAt);
      existingKeys.add(key);
    }

    int imported = 0;
    for (final dp in dataPoints) {
      final weight = (dp.value as NumericHealthValue).numericValue.toDouble();
      final recordedAt = dp.dateFrom;
      final key = _dedupeKey(weight, recordedAt);

      if (existingKeys.contains(key)) continue;

      // Auto-detect period from hour
      final hour = recordedAt.hour;
      final WeightPeriod period;
      if (hour < 11) {
        period = WeightPeriod.morning;
      } else if (hour < 17) {
        period = WeightPeriod.midday;
      } else {
        period = WeightPeriod.night;
      }

      await add(period: period, weight: weight, recordedAt: recordedAt);
      existingKeys.add(key);
      imported++;
    }

    return imported;
  }

  static String _dedupeKey(double weight, DateTime dt) {
    final w = weight.toStringAsFixed(1);
    final t = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute)
        .toIso8601String();
    return '$w@$t';
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
