import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/recipe.dart';

/// In v1 we ship the curated recipe set as a bundled JSON asset.
/// Once volume justifies it, this can be swapped for a Firestore
/// collection or an external recipe API without changing callers.
class RecipeRepository {
  RecipeRepository._(this._recipes);

  final List<Recipe> _recipes;
  static RecipeRepository? _instance;

  static Future<RecipeRepository> load() async {
    if (_instance != null) return _instance!;
    final raw = await rootBundle.loadString('assets/recipes.json');
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    _instance = RecipeRepository._(list);
    return _instance!;
  }

  List<Recipe> all() => List.unmodifiable(_recipes);

  Recipe? byId(String id) {
    for (final r in _recipes) {
      if (r.id == id) return r;
    }
    return null;
  }
}
