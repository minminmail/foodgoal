import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/shopping_item.dart';
import 'app_database.dart';

/// SQLite-backed CRUD for the shopping list.
class ShoppingService {
  ShoppingService(this._uid);

  final String _uid;
  final _controller = StreamController<List<ShoppingItem>>.broadcast();

  Future<void> _emit() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('shopping', orderBy: 'addedAt DESC');
    final items = rows
        .map((r) => ShoppingItem.fromMap(r['id'] as String, {
              'name': r['name'],
              'forRecipeTitle': r['forRecipeTitle'],
              'checked': (r['checked'] as int) == 1,
              'addedAt': r['addedAt'],
            }))
        .toList();
    _controller.add(items);
  }

  Stream<List<ShoppingItem>> watch() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  Future<void> addMany({
    required List<String> names,
    required String forRecipeTitle,
  }) async {
    if (names.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    final now = DateTime.now();
    for (final name in names) {
      final id = const Uuid().v4();
      batch.insert('shopping', {
        'id': id,
        'name': name,
        'forRecipeTitle': forRecipeTitle,
        'checked': 0,
        'addedAt': now.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
    await _emit();
  }

  Future<void> setChecked(ShoppingItem item, bool checked) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'shopping',
      {'checked': checked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [item.id],
    );
    await _emit();
  }

  Future<void> remove(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('shopping', where: 'id = ?', whereArgs: [id]);
    await _emit();
  }

  Future<void> clearChecked() async {
    final db = await AppDatabase.instance.database;
    await db.delete('shopping', where: 'checked = ?', whereArgs: [1]);
    await _emit();
  }
}
