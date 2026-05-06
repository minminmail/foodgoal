# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

All commands run from `app/` directory. Flutter is at `/c/flutter/bin/flutter`.

```bash
cd app
/c/flutter/bin/flutter pub get          # Install dependencies
/c/flutter/bin/flutter run -d emulator-5554  # Run on Android emulator
/c/flutter/bin/flutter analyze          # Lint check
/c/flutter/bin/flutter test             # Run tests
/c/flutter/bin/flutter test test/widget_test.dart  # Single test
```

Note: `flutter` is not on PATH in bash; use the full path above or `cmd.exe /c "flutter ..."`.

## Architecture

**Stack:** Flutter 3.19+ / Dart 3.3+ / Material 3 / SQLite (sqflite) / Provider / fl_chart

**Layered structure (all under `app/lib/`):**

- **`models/`** — Immutable data classes with `toMap()`/`fromMap()` serialization. Enums live alongside their model (e.g., `MealSlot` in `meal_log_entry.dart`, `WeightPeriod` in `weight_entry.dart`).
- **`services/`** — CRUD services injected via Provider. Most use a `StreamController.broadcast()` pattern: mutations write to SQLite then call `_emit*()` to push fresh data to listeners. `AppDatabase` is a singleton managing schema migrations.
- **`screens/`** — StatefulWidgets consuming services via `context.read<T>()`. Data binding uses `StreamBuilder`/`FutureBuilder`. Navigation is a 5-tab `IndexedStack` in `app_shell.dart`.
- **`theme/`** — `AppColors` constants and `buildAppTheme()`. Brand green is `#1F6F4A`.

**Data flow:** Screen → `context.read<Service>()` → SQLite via `AppDatabase.instance.database` → StreamController emits updated list → StreamBuilder rebuilds UI.

## Key Patterns

- **Service constructor** takes a `uid` string (from `AuthService`), registered in `main.dart`'s `MultiProvider`.
- **Database migrations** in `app_database.dart`: bump `version`, add table in both `onCreate` (fresh install) and `onUpgrade` (existing users). Current schema is **v4**.
- **Ranker** (`services/ranker.dart`): suggestion algorithm ranks recipes by pantry ingredient overlap, skips recipes cooked in last 7 days, falls back to prep-time sort when pantry is empty.
- **Recipes** are bundled in `assets/recipes.json` (29 entries), loaded once at startup by `RecipeRepository`.
- **`TonightScreenState`** is public (not underscore-prefixed) so `AppShell` can call `reloadProfile()` via GlobalKey when switching tabs.

## Database Tables

`pantry`, `meal_log`, `shopping`, `user_profile`, `weight_entries` — all use TEXT primary keys (UUIDs) and TEXT dates (ISO 8601). Indexed on date columns.

## Linting

`analysis_options.yaml` extends `flutter_lints/flutter.yaml` with `avoid_print: false`. The analyzer enforces `prefer_const_constructors`. Pre-existing errors in `firebase_options.dart` and `test/widget_test.dart` are known and can be ignored.
