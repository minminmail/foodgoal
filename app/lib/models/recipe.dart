/// A curated recipe, tagged with the things the v1 ranker needs:
/// ingredient list (used for pantry matching), prep time, cuisine, and
/// effort. No nutrition calculations in this build.
class Recipe {
  final String id;
  final String title;
  final String? titleEs;
  final String? titleZh;
  final String emoji; // stand-in for a hero image in v1
  final String cuisine; // 'Mediterranean', 'Spanish', 'Japanese', ...
  final int prepMinutes;
  final RecipeEffort effort;
  final int approxKcal;
  final List<String> ingredients; // canonical lowercase keys
  final List<String> steps;
  final List<String>? ingredientsEs;
  final List<String>? ingredientsZh;
  final List<String>? stepsEs;
  final List<String>? stepsZh;

  const Recipe({
    required this.id,
    required this.title,
    this.titleEs,
    this.titleZh,
    required this.emoji,
    required this.cuisine,
    required this.prepMinutes,
    required this.effort,
    required this.approxKcal,
    required this.ingredients,
    required this.steps,
    this.ingredientsEs,
    this.ingredientsZh,
    this.stepsEs,
    this.stepsZh,
  });

  /// Returns localized ingredients for the given language code.
  List<String> localizedIngredients(String lang) {
    switch (lang) {
      case 'es':
        return ingredientsEs ?? ingredients;
      case 'zh':
        return ingredientsZh ?? ingredients;
      default:
        return ingredients;
    }
  }

  /// Returns localized steps for the given language code.
  List<String> localizedSteps(String lang) {
    switch (lang) {
      case 'es':
        return stepsEs ?? steps;
      case 'zh':
        return stepsZh ?? steps;
      default:
        return steps;
    }
  }

  /// Returns the recipe title for the given language code.
  String localizedTitle(String lang) {
    switch (lang) {
      case 'es':
        return titleEs ?? title;
      case 'zh':
        return titleZh ?? title;
      default:
        return title;
    }
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      titleEs: json['title_es'] as String?,
      titleZh: json['title_zh'] as String?,
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
      ingredientsEs: (json['ingredients_es'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      ingredientsZh: (json['ingredients_zh'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      stepsEs: (json['steps_es'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      stepsZh: (json['steps_zh'] as List<dynamic>?)
          ?.map((e) => e.toString())
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
