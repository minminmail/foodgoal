/// A single logged meal. The MVP brief explicitly says "no portion sizes
/// or calorie input" — we just record which meal slot, what was eaten, and
/// when. The ranker uses [recipeId] (when set) to apply the 7-day skip.
class MealLogEntry {
  final String id;
  final MealSlot slot;
  final String name; // free text; if cooked from a recipe, copies the title
  final String? recipeId; // null when the user typed a freeform meal
  final DateTime eatenAt;
  final double? grams;
  final double? calories;

  MealLogEntry({
    required this.id,
    required this.slot,
    required this.name,
    required this.recipeId,
    required this.eatenAt,
    this.grams,
    this.calories,
  });

  Map<String, dynamic> toMap() => {
        'slot': slot.name,
        'name': name,
        'recipeId': recipeId,
        'eatenAt': eatenAt.toIso8601String(),
        'grams': grams,
        'calories': calories,
      };

  factory MealLogEntry.fromMap(String id, Map<String, dynamic> map) {
    return MealLogEntry(
      id: id,
      slot: MealSlot.values.firstWhere(
        (s) => s.name == map['slot'],
        orElse: () => MealSlot.dinner,
      ),
      name: map['name'] as String? ?? '',
      recipeId: map['recipeId'] as String?,
      eatenAt: DateTime.tryParse(map['eatenAt'] as String? ?? '') ??
          DateTime.now(),
      grams: (map['grams'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),
    );
  }
}

enum MealSlot {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label {
    switch (this) {
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.dinner:
        return 'Dinner';
      case MealSlot.snack:
        return 'Snack';
    }
  }
}
