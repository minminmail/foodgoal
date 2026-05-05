import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/meal_log_entry.dart';
import '../services/meal_log_service.dart';
import '../services/pantry_service.dart';
import '../services/ranker.dart';
import '../services/shopping_service.dart';
import '../theme/app_theme.dart';

/// Tap a Tonight card → land here. The "I'll cook this" button is the
/// pivot of the whole loop: it deducts pantry items, adds a log entry,
/// and pushes any missing ingredients to the shopping list.
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final r = suggestion.recipe;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Recipe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC8DDD0), Color(0xFF9ABFA8)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(r.emoji, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 14),
          Text(r.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            '${r.cuisine} · ${r.prepMinutes} min · ${r.effort.label} · ~${r.approxKcal} kcal',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'Ingredients',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: r.ingredients.map((ing) {
                final have =
                    suggestion.haveIngredients.contains(ing);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        have ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: have ? AppColors.brand : AppColors.muted,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ing,
                          style: TextStyle(
                            color: have ? AppColors.text : AppColors.muted,
                          ),
                        ),
                      ),
                      if (!have)
                        const Text('needs',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.warning)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Steps',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < r.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}.',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r.steps[i])),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.local_fire_department, size: 18),
              label: const Text("I'll cook this"),
              onPressed: () => _cookThis(context),
            ),
          ),
          const SizedBox(height: 12),
          if (suggestion.missingIngredients.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () => _addMissingToShopping(context),
                child: Text(
                    'Add ${suggestion.missingIngredients.length} missing item(s) to shopping list'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cookThis(BuildContext context) async {
    final pantry = context.read<PantryService>();
    final mealLog = context.read<MealLogService>();
    final shop = context.read<ShoppingService>();

    // 1. Log the meal as dinner — the most common slot for the Tonight loop.
    await mealLog.log(
      slot: MealSlot.dinner,
      name: suggestion.recipe.title,
      recipeId: suggestion.recipe.id,
    );

    // 2. Deduct pantry items the recipe used.
    await pantry.consumeIngredients(suggestion.haveIngredients);

    // 3. Anything missing goes to shopping (so they're prompted to buy
    // it next time and can cook the recipe again later).
    if (suggestion.missingIngredients.isNotEmpty) {
      await shop.addMany(
        names: suggestion.missingIngredients,
        forRecipeTitle: suggestion.recipe.title,
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Logged ${suggestion.recipe.title}. Enjoy.'),
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _addMissingToShopping(BuildContext context) async {
    final shop = context.read<ShoppingService>();
    await shop.addMany(
      names: suggestion.missingIngredients,
      forRecipeTitle: suggestion.recipe.title,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Added to shopping list.'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
