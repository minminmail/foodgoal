/// A curated recipe, tagged with the things the v1 ranker needs:
/// ingredient list (used for pantry matching), prep time, cuisine, and
/// effort. No nutrition calculations in this build.
class Recipe {
  final String id;
  final String title;
  final String emoji; // stand-in for a hero image in v1
  final String cuisine; // 'Mediterranean', 'Spanish', 'Japanese', ...
  final int prepMinutes;
  final RecipeEffort effort;
  final int approxKcal;
  final List<String> ingredients; // canonical lowercase keys
  final List<String> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.emoji,
    required this.cuisine,
    required this.prepMinutes,
    required this.effort,
    required this.approxKcal,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String? ?? '🍽',
      cuisine: json['cuisine'] as String? ?? 'Generic',
      prepMinutes: (json['prepMinutes'] as num?)?.toInt() ?? 30,
      effort: RecipeEffort.values.firstWhere(
        (e) => e.name == (json['effort'] as String? ?? 'easy'),
        orElse: () => RecipeEffort.easy,
      ),
      approxKcal: (json['approxKcal'] as num?)?.toInt() ?? 500,
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((e) => e.toString().toLowerCase().trim())
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

enum RecipeEffort {
  easy, // ~5–15 min
  medium, // ~15–30 min
  project; // 30+ min / weekend project

  String get label {
    switch (this) {
      case RecipeEffort.easy:
        return 'easy';
      case RecipeEffort.medium:
        return 'medium';
      case RecipeEffort.project:
        return 'project';
    }
  }
}
