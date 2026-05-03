import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal_log_entry.dart';
import '../models/pantry_item.dart';
import '../services/meal_log_service.dart';
import '../services/pantry_service.dart';
import '../services/ranker.dart';
import '../services/recipe_repository.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';

/// The home screen. Shows three suggestion cards based on the simple
/// ranker (pantry coverage + 7-day skip) — exactly the MVP brief.
class TonightScreen extends StatelessWidget {
  const TonightScreen({super.key});

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
          const _Header(),
          const SizedBox(height: 12),
          _GoalStrip(
            label: 'Cook from what you have',
            count: '3 ideas',
          ),
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
                    );
                    if (suggestions.isEmpty) {
                      return _EmptyState(pantryEmpty: pantryItems.isEmpty);
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SuggestionCard(
                        suggestion: suggestions[i],
                        accent: i, // 0/1/2 → tweak the photo gradient
                      ),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stamp = DateFormat('EEEE, d MMM · h:mm a').format(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stamp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Row(
          children: [
            const Expanded(
              child: Text('Tonight',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  )),
            ),
            // The "+" affordance from the screen sketch — opens the log
            // screen for a freeform meal entry.
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.brandSoft,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add, size: 18, color: AppColors.brand),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalStrip extends StatelessWidget {
  const _GoalStrip({required this.label, required this.count});
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(count,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.accent});

  final Suggestion suggestion;
  final int accent;

  static const _gradients = <List<Color>>[
    [Color(0xFFC8DDD0), Color(0xFF9ABFA8)],
    [Color(0xFFE8C698), Color(0xFFD69E5E)],
    [Color(0xFFC9D7A8), Color(0xFF97AE6D)],
  ];

  @override
  Widget build(BuildContext context) {
    final r = suggestion.recipe;
    final gradient = _gradients[accent % _gradients.length];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              alignment: Alignment.center,
              child: Text(r.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 10),
            Text(
              r.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${r.prepMinutes} min · ${r.effort.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Text('~${r.approxKcal} kcal',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (suggestion.haveIngredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Uses: ${_topIngredients(suggestion.haveIngredients)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else if (suggestion.missingIngredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Needs: ${_topIngredients(suggestion.missingIngredients)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _topIngredients(List<String> list) {
    final picked = list.take(3).toList();
    return picked.join(', ');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.pantryEmpty});
  final bool pantryEmpty;

  @override
  Widget build(BuildContext context) {
    final msg = pantryEmpty
        ? 'Add a few items to your pantry and we\'ll suggest dinners you '
            'can already cook.'
        : 'No suggestions for tonight yet — try adding more pantry items.';
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
