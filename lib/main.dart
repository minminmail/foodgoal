import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/meal_log_service.dart';
import 'services/pantry_service.dart';
import 'services/recipe_repository.dart';
import 'services/profile_service.dart';
import 'services/shopping_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FoodGoalApp());
}

class FoodGoalApp extends StatefulWidget {
  const FoodGoalApp({super.key});

  @override
  State<FoodGoalApp> createState() => _FoodGoalAppState();
}

class _FoodGoalAppState extends State<FoodGoalApp> {
  late final Future<_BootstrapResult> _ready;

  @override
  void initState() {
    super.initState();
    _ready = _prepare();
  }

  Future<_BootstrapResult> _prepare() async {
    final auth = AuthService();
    final uid = await auth.ensureSignedIn();
    final recipes = await RecipeRepository.load();
    return _BootstrapResult(uid: uid, recipes: recipes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _ready,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'FoodGoal',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snap.hasError) {
          return MaterialApp(
            title: 'FoodGoal',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "Couldn't start FoodGoal.\n\n${snap.error}",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        final result = snap.data!;
        return MultiProvider(
          providers: [
            Provider<RecipeRepository>.value(value: result.recipes),
            Provider<PantryService>(
              create: (_) => PantryService(result.uid),
            ),
            Provider<MealLogService>(
              create: (_) => MealLogService(result.uid),
            ),
            Provider<ShoppingService>(
              create: (_) => ShoppingService(result.uid),
            ),
            Provider<ProfileService>(
              create: (_) => ProfileService(result.uid),
            ),
          ],
          child: MaterialApp(
            title: 'FoodGoal',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            home: const AppShell(),
          ),
        );
      },
    );
  }
}

class _BootstrapResult {
  _BootstrapResult({required this.uid, required this.recipes});
  final String uid;
  final RecipeRepository recipes;
}
