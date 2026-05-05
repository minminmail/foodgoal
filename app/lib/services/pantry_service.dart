import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/pantry_item.dart';
import 'app_database.dart';

/// SQLite-backed CRUD for the pantry.
class PantryService {
  PantryService(this._uid);

  final String _uid;
  final _controller = StreamController<List<PantryItem>>.broadcast();

  Future<void> _emit() async {
    final items = await fetchOnce();
    _controller.add(items);
  }

  Stream<List<PantryItem>> watch() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  Future<List<PantryItem>> fetchOnce() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('pantry', orderBy: 'addedAt DESC');
    return rows.map((r) => PantryItem.fromMap(r['id'] as String, {
      'name': r['name'],
      'quantity': r['quantity'],
      'section': r['section'],
      'addedAt': r['addedAt'],
    })).toList();
  }

  Future<PantryItem> add({
    required String name,
    required String quantity,
    required PantrySection section,
  }) async {
    final id = const Uuid().v4();
    final item = PantryItem(
      id: id,
      name: name.trim(),
      quantity: quantity.trim(),
      section: section,
      addedAt: DateTime.now(),
    );
    final db = await AppDatabase.instance.database;
    await db.insert('pantry', {
      'id': item.id,
      ...item.toMap(),
    });
    await _emit();
    return item;
  }

  Future<void> update(PantryItem item) async {
    final db = await AppDatabase.instance.database;
    await db.update('pantry', {
      ...item.toMap(),
    }, where: 'id = ?', whereArgs: [item.id]);
    await _emit();
  }

  Future<void> remove(String itemId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('pantry', where: 'id = ?', whereArgs: [itemId]);
    await _emit();
  }

  Future<void> consumeIngredients(List<String> matchKeys) async {
    if (matchKeys.isEmpty) return;
    final items = await fetchOnce();
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final item in items) {
      if (matchKeys.contains(item.matchKey)) {
        batch.delete('pantry', where: 'id = ?', whereArgs: [item.id]);
      }
    }
    await batch.commit(noResult: true);
    await _emit();
  }
}
