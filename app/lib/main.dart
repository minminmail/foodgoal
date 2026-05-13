import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/locale_provider.dart';
import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/meal_log_service.dart';
import 'services/pantry_service.dart';
import 'services/recipe_repository.dart';
import 'services/profile_service.dart';
import 'services/shopping_service.dart';
import 'services/health_connect_service.dart';
import 'services/weight_service.dart';
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
    // Load saved language from profile
    final profileService = ProfileService(uid);
    final profile = await profileService.get();
    final lang = profile?.appLanguage ?? 'en';
    return _BootstrapResult(uid: uid, recipes: recipes, language: lang);
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
            Provider<WeightService>(
              create: (_) => WeightService(result.uid),
            ),
            Provider<HealthConnectService>(
              create: (_) => HealthConnectService(),
            ),
            ChangeNotifierProvider<LocaleProvider>(
              create: (_) => LocaleProvider(result.language),
            ),
          ],
          child: Consumer<LocaleProvider>(
            builder: (context, locale, _) => MaterialApp(
              title: 'FoodGoal',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              locale: locale.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('es'),
                Locale('zh'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AppShell(),
            ),
          ),
        );
      },
    );
  }
}

class _BootstrapResult {
  _BootstrapResult({
    required this.uid,
    required this.recipes,
    required this.language,
  });
  final String uid;
  final RecipeRepository recipes;
  final String language;
}
