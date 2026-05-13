/// Personal profile data for the single device user.
class UserProfile {
  final String id;
  final String name;
  final String gender; // male, female, other
  final double currentWeight; // kg
  final double targetWeight; // kg
  final int plannedWeightLossMonths;
  final bool isVegetarian;
  final int age;
  final double height; // cm
  final String country;
  final int dailyCalories; // kcal
  final int mealCalories; // kcal per meal (3 meals/day)
  final String appLanguage; // 'en', 'es', 'zh'
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.currentWeight,
    required this.targetWeight,
    required this.plannedWeightLossMonths,
    required this.isVegetarian,
    required this.age,
    required this.height,
    required this.country,
    this.dailyCalories = 0,
    this.mealCalories = 0,
    this.appLanguage = 'en',
    required this.updatedAt,
  });

  /// Mifflin-St Jeor BMR × sedentary multiplier, minus weight-loss deficit.
  /// Returns (dailyCalories, mealCalories) with a 1200 kcal floor.
  static (int, int) calculateCalories({
    required String gender,
    required int age,
    required double height,
    required double currentWeight,
    required double targetWeight,
    required int plannedMonths,
  }) {
    // Mifflin-St Jeor: BMR
    final double bmr;
    if (gender == 'female') {
      bmr = 10 * currentWeight + 6.25 * height - 5 * age - 161;
    } else {
      bmr = 10 * currentWeight + 6.25 * height - 5 * age + 5;
    }

    // TDEE with sedentary activity factor
    final tdee = bmr * 1.2;

    // Daily deficit: 1 kg fat ≈ 7700 kcal
    final weightToLose = currentWeight - targetWeight;
    final days = plannedMonths * 30;
    final dailyDeficit = days > 0 ? (weightToLose * 7700) / days : 0.0;

    // Floor at 1200 kcal for safety
    final daily = (tdee - dailyDeficit).round().clamp(1200, 9999);
    final meal = (daily / 3).round();

    return (daily, meal);
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'gender': gender,
        'currentWeight': currentWeight,
        'targetWeight': targetWeight,
        'plannedWeightLossMonths': plannedWeightLossMonths,
        'isVegetarian': isVegetarian ? 1 : 0,
        'age': age,
        'height': height,
        'country': country,
        'dailyCalories': dailyCalories,
        'mealCalories': mealCalories,
        'appLanguage': appLanguage,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'] as String? ?? '',
      gender: map['gender'] as String? ?? 'other',
      currentWeight: (map['currentWeight'] as num? ?? 0).toDouble(),
      targetWeight: (map['targetWeight'] as num? ?? 0).toDouble(),
      plannedWeightLossMonths: map['plannedWeightLossMonths'] as int? ?? 6,
      isVegetarian: (map['isVegetarian'] as int? ?? 0) == 1,
      age: map['age'] as int? ?? 25,
      height: (map['height'] as num? ?? 170).toDouble(),
      country: map['country'] as String? ?? '',
      dailyCalories: map['dailyCalories'] as int? ?? 0,
      mealCalories: map['mealCalories'] as int? ?? 0,
      appLanguage: map['appLanguage'] as String? ?? 'en',
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  UserProfile copyWith({
    String? name,
    String? gender,
    double? currentWeight,
    double? targetWeight,
    int? plannedWeightLossMonths,
    bool? isVegetarian,
    int? age,
    double? height,
    String? country,
    int? dailyCalories,
    int? mealCalories,
    String? appLanguage,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      plannedWeightLossMonths:
          plannedWeightLossMonths ?? this.plannedWeightLossMonths,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      age: age ?? this.age,
      height: height ?? this.height,
      country: country ?? this.country,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      mealCalories: mealCalories ?? this.mealCalories,
      appLanguage: appLanguage ?? this.appLanguage,
      updatedAt: DateTime.now(),
    );
  }
}
