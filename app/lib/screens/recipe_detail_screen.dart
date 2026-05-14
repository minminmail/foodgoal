import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_translations.dart';
import '../l10n/locale_provider.dart';
import '../models/meal_log_entry.dart';
import '../services/meal_log_service.dart';
import '../services/pantry_service.dart';
import '../services/ranker.dart';
import '../services/shopping_service.dart';
import '../theme/app_theme.dart';

/// Tap a Tonight card -> land here.
class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key, required this.suggestion, required this.slot});

  final Suggestion suggestion;
  final MealSlot slot;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final r = suggestion.recipe;
    final lang = context.read<LocaleProvider>().language;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(t(context, 'recipe_title'))),
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
          Text(r.localizedTitle(lang),
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
            title: t(context, 'recipe_ingredients'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < r.ingredients.length; i++)
                  () {
                    final have =
                        suggestion.haveIngredients.contains(r.ingredients[i]);
                    final displayName = r.localizedIngredients(lang);
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
                              i < displayName.length ? displayName[i] : r.ingredients[i],
                              style: TextStyle(
                                color: have ? AppColors.text : AppColors.muted,
                              ),
                            ),
                          ),
                          if (!have)
                            Text(t(context, 'recipe_needs'),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.warning)),
                        ],
                      ),
                    );
                  }(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: t(context, 'recipe_steps'),
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
                        Expanded(child: Text(
                          i < r.localizedSteps(lang).length
                              ? r.localizedSteps(lang)[i]
                              : r.steps[i],
                        )),
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
              label: Text(t(context, 'recipe_cook_btn')),
              onPressed: () => _cookThis(context),
            ),
          ),
          const SizedBox(height: 12),
          if (suggestion.missingIngredients.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () => _addMissingToShopping(context),
                child: Text(
                    tr(context, 'recipe_add_missing', {
                      'n': '${suggestion.missingIngredients.length}',
                    })),
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
    final lang = context.read<LocaleProvider>().language;
    final localTitle = suggestion.recipe.localizedTitle(lang);

    await mealLog.log(
      slot: slot,
      name: localTitle,
      recipeId: suggestion.recipe.id,
      calories: suggestion.recipe.approxKcal.toDouble(),
    );

    await pantry.consumeIngredients(suggestion.haveIngredients);

    if (suggestion.missingIngredients.isNotEmpty) {
      await shop.addMany(
        names: suggestion.missingIngredients,
        forRecipeTitle: localTitle,
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(tr(context, 'recipe_logged', {'title': localTitle})),
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _addMissingToShopping(BuildContext context) async {
    final shop = context.read<ShoppingService>();
    final lang = context.read<LocaleProvider>().language;
    await shop.addMany(
      names: suggestion.missingIngredients,
      forRecipeTitle: suggestion.recipe.localizedTitle(lang),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t(context, 'recipe_added_shopping')),
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
