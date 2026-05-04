import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal_log_entry.dart';
import '../models/pantry_item.dart';
import '../models/user_profile.dart';
import '../services/meal_log_service.dart';
import '../services/pantry_service.dart';
import '../services/profile_service.dart';
import '../services/ranker.dart';
import '../services/recipe_repository.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

/// Home screen — shows today's three meals (breakfast, lunch, dinner),
/// each with a suggested recipe and calorie target from the user profile. and consider the food registered
class TonightScreen extends StatefulWidget {
  const TonightScreen({super.key});

  @override
  State<TonightScreen> createState() => _TonightScreenState();
}

class _TonightScreenState extends State<TonightScreen> {
  UserProfile? _profile;

  // Per-slot rotation offset — cycles through all suggestions.
  final _slotOffset = <MealSlot, int>{
    MealSlot.breakfast: 0,
    MealSlot.lunch: 1,
    MealSlot.dinner: 2,
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    final profile = await context.read<ProfileService>().get();
    if (mounted) setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final pantry = context.read<PantryService>();
    final mealLog = context.read<MealLogService>();
    final recipes = context.read<RecipeRepository>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(profile: _profile),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<PantryItem>>(
              stream: pantry.watch(),
              builder: (context, pantrySnap) {
                final pantryItems = pantrySnap.data ?? const <PantryItem>[];
                return FutureBuilder<List<MealLogEntry>>(
                  future: mealLog.fetchSince(
                    DateTime.now().subtract(const Duration(days: 7)),
                  ),
                  builder: (context, recentSnap) {
                    if (pantrySnap.connectionState != ConnectionState.active &&
                        !pantrySnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final recent = recentSnap.data ?? const <MealLogEntry>[];
                    final suggestions = Ranker.suggest(
                      recipes: recipes.all(),
                      pantry: pantryItems,
                      recentMeals: recent,
                      limit: 9, // enough to pick from for 3 meals
                    );

                    if (suggestions.isEmpty) {
                      return _EmptyState(pantryEmpty: pantryItems.isEmpty);
                    }

                    Suggestion? pick(MealSlot slot) {
                      if (suggestions.isEmpty) return null;
                      final idx = _slotOffset[slot]! % suggestions.length;
                      return suggestions[idx];
                    }

                    void swap(MealSlot slot) {
                      setState(() {
                        _slotOffset[slot] =
                            (_slotOffset[slot]! + 1) % suggestions.length;
                      });
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        for (final slot in const [
                          MealSlot.breakfast,
                          MealSlot.lunch,
                          MealSlot.dinner,
                        ]) ...[
                          if (slot != MealSlot.breakfast)
                            const SizedBox(height: 16),
                          _MealSection(
                            slot: slot,
                            suggestion: pick(slot),
                            mealCalories: _profile?.mealCalories,
                            onSwap: suggestions.length > 1
                                ? () => swap(slot)
                                : null,
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({this.profile});
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stamp = DateFormat('EEEE, d MMM').format(now);
    final greeting = profile != null && profile!.name.isNotEmpty
        ? 'Hi, ${profile!.name}'
        : 'Today';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stamp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                greeting,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            if (profile != null && profile!.dailyCalories > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${profile!.dailyCalories} kcal/day',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Meal section (one per slot)
// ---------------------------------------------------------------------------

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.slot,
    required this.suggestion,
    this.mealCalories,
    this.onSwap,
  });

  final MealSlot slot;
  final Suggestion? suggestion;
  final int? mealCalories;
  final VoidCallback? onSwap;

  static const _slotIcons = <MealSlot, IconData>{
    MealSlot.breakfast: Icons.wb_sunny_outlined,
    MealSlot.lunch: Icons.wb_cloudy_outlined,
    MealSlot.dinner: Icons.nights_stay_outlined,
  };

  static const _gradients = <MealSlot, List<Color>>{
    MealSlot.breakfast: [Color(0xFFFDE8C8), Color(0xFFF5C77E)],
    MealSlot.lunch: [Color(0xFFC8DDD0), Color(0xFF9ABFA8)],
    MealSlot.dinner: [Color(0xFFCBC5E0), Color(0xFF9B8EC4)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[slot] ?? _gradients[MealSlot.lunch]!;
    final icon = _slotIcons[slot] ?? Icons.restaurant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slot header row
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(
              slot.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (mealCalories != null && mealCalories! > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '~$mealCalories kcal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (onSwap != null)
              GestureDetector(
                onTap: onSwap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 16, color: AppColors.brand),
                      SizedBox(width: 4),
                      Text(
                        'Swap',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Suggestion card or empty placeholder
        if (suggestion != null)
          _SuggestionCard(suggestion: suggestion!, gradient: colors)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Center(
              child: Text(
                'Add items to your pantry for suggestions',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Suggestion card (reused per meal)
// ---------------------------------------------------------------------------

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.gradient});

  final Suggestion suggestion;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final r = suggestion.recipe;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(suggestion: suggestion),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            // Emoji thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              alignment: Alignment.center,
              child: Text(r.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${r.prepMinutes} min · ${r.effort.label} · ~${r.approxKcal} kcal',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (suggestion.haveIngredients.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Uses: ${suggestion.haveIngredients.take(3).join(', ')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.pantryEmpty});
  final bool pantryEmpty;

  @override
  Widget build(BuildContext context) {
    final msg = pantryEmpty
        ? 'Add a few items to your pantry and we\'ll suggest meals you '
            'can cook today.'
        : 'No suggestions yet — try adding more pantry items.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
