import '../models/meal_log_entry.dart';
import '../models/pantry_item.dart';
import '../models/recipe.dart';

/// The MVP brief: two rules only.
///   1. Prefer recipes the user has ingredients for.
///   2. Skip anything cooked in the last 7 days.
///
/// Score = number of pantry-matched ingredients on each candidate
/// (with ties broken by total ingredient count, so a 3/3 match beats a
/// 3/8 match). Recipes cooked in the last 7 days are removed entirely
/// before scoring.
class Suggestion {
  final Recipe recipe;
  final List<String> haveIngredients; // pantry hits (lowercase keys)
  final List<String> missingIngredients;

  const Suggestion({
    required this.recipe,
    required this.haveIngredients,
    required this.missingIngredients,
  });

  /// 0.0–1.0: how much of the recipe is covered by current pantry.
  double get coverage {
    final total = recipe.ingredients.length;
    if (total == 0) return 0;
    return haveIngredients.length / total;
  }
}

class Ranker {
  /// Returns up to [limit] suggestions, ordered best-first.
  static List<Suggestion> suggest({
    required List<Recipe> recipes,
    required List<PantryItem> pantry,
    required List<MealLogEntry> recentMeals,
    int limit = 3,
    int recencyDays = 7,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: recencyDays));
    final blockedRecipeIds = recentMeals
        .where((m) => m.recipeId != null && m.eatenAt.isAfter(cutoff))
        .map((m) => m.recipeId!)
        .toSet();

    final pantryKeys = pantry.map((p) => p.matchKey).toSet();

    final scored = <Suggestion>[];
    for (final r in recipes) {
      if (blockedRecipeIds.contains(r.id)) continue;
      final have = <String>[];
      final missing = <String>[];
      for (final ing in r.ingredients) {
        // Loose match: pantry contains the ingredient string OR the
        // ingredient string contains a pantry key (handles "soy sauce"
        // matching pantry "soy sauce" but also "rice" matching "brown rice").
        final hit = pantryKeys.any((k) => k == ing || ing.contains(k) || k.contains(ing));
        (hit ? have : missing).add(ing);
      }
      scored.add(Suggestion(
        recipe: r,
        haveIngredients: have,
        missingIngredients: missing,
      ));
    }

    // Rule 1: prefer more pantry coverage.
    scored.sort((a, b) {
      final byHave = b.haveIngredients.length.compareTo(a.haveIngredients.length);
      if (byHave != 0) return byHave;
      // Tie-break: recipes that need fewer total ingredients first
      // (a 3-of-3 match should beat a 3-of-8 match).
      return a.recipe.ingredients.length.compareTo(b.recipe.ingredients.length);
    });

    // If the pantry is empty, the user has nothing to cook with; surface
    // the easiest curated recipes as a starting point.
    if (pantryKeys.isEmpty) {
      scored.sort((a, b) =>
          a.recipe.prepMinutes.compareTo(b.recipe.prepMinutes));
    }

    return scored.take(limit).toList();
  }
}
