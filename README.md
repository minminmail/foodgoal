# FoodGoal — v0.1 (MVP)

> *"Open the app at 6 pm, see three meals you can cook with what you already have, pick one, cook it, log it."*

This is the first build of FoodGoal. It implements the six MVP features from the brief and nothing else:

1. **Pantry inventory** — typed list with quantity and section (Fresh / Cupboard / Frozen)
2. **Meal log** — one-tap logging across breakfast, lunch, dinner, snack
3. **Tonight screen** — three suggestion cards based on the ranker
4. **Curated recipes** — 29 hand-picked Mediterranean and Asian recipes shipped as a JSON asset (target: grow to 100–150)
5. **Simple ranker** — two rules: prefer recipes the user has ingredients for, skip anything cooked in the last 7 days
6. **Shopping list** — missing ingredients from picked meals; tap to tick off

Explicitly **not** in this build: weight tracking, calorie counting, barcode scanning, photo-of-the-fridge, variety score, plateau detective, family mode, weekly reviews, leftover tracking, eating-out mode, cravings handling.

---

## Stack

- **Flutter** (Material 3) — single codebase for iOS + Android
- **Firebase Authentication** — anonymous sign-in (no login screens in v1)
- **Cloud Firestore** — pantry, meal log, and shopping list per user
- **Provider** — lightweight state management
- **Recipes** — bundled `assets/recipes.json`

## Project layout

```
app/
├── pubspec.yaml
├── analysis_options.yaml
├── assets/
│   └── recipes.json              # 29 seeded recipes
└── lib/
    ├── main.dart                 # Firebase init, anonymous auth, providers
    ├── firebase_options.dart     # PLACEHOLDER — overwrite via flutterfire configure
    ├── theme/app_theme.dart      # Palette + Material 3 theme
    ├── models/                   # PantryItem, Recipe, MealLogEntry, ShoppingItem
    ├── services/
    │   ├── auth_service.dart
    │   ├── pantry_service.dart
    │   ├── meal_log_service.dart
    │   ├── shopping_service.dart
    │   ├── recipe_repository.dart
    │   └── ranker.dart           # The two-rule v1 ranker
    └── screens/
        ├── app_shell.dart        # Bottom-tab nav
        ├── tonight_screen.dart
        ├── pantry_screen.dart
        ├── log_screen.dart
        ├── shopping_screen.dart
        └── recipe_detail_screen.dart
```

## Firestore schema

```
users/
└── {uid}/
    ├── pantry/{itemId}     { name, quantity, section, addedAt }
    ├── meal_log/{entryId}  { slot, name, recipeId?, eatenAt }
    └── shopping/{itemId}   { name, forRecipeTitle?, checked, addedAt }
```

Suggested security rules (drop into Firebase Console → Firestore → Rules):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{collection}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Setup

1. **Install Flutter** ≥ 3.19 and run `flutter doctor` until everything is green.
2. **Create a Firebase project** in the [Firebase Console](https://console.firebase.google.com/).
   - Enable **Authentication → Sign-in method → Anonymous**.
   - Create a **Firestore** database in production mode and paste the rules above.
3. **Wire Firebase into the app** with the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   cd app
   flutterfire configure
   ```
   This overwrites `lib/firebase_options.dart` with real values for your project.
4. **Install Dart deps**:
   ```bash
   flutter pub get
   ```
5. **Run it**:
   ```bash
   flutter run                 # default device
   flutter run -d chrome       # web
   flutter run -d ios          # iOS simulator
   flutter run -d android      # Android emulator
   ```

## How to test the loop

1. Open the app — it signs in anonymously and lands on Tonight.
2. Go to **Pantry** and add a handful of items (e.g. *lentils*, *onion*, *garlic*, *carrot*, *olive oil*).
3. Return to **Tonight** — *Lentejas con verduras* should rank near the top because the pantry covers most of its ingredients.
4. Tap a card → **I'll cook this**. The pantry items get consumed, the meal lands in the **Log**, and any missing ingredients show up on the **Shopping** tab.
5. Refresh **Tonight** and you'll notice the recipe you just cooked is hidden for the next 7 days (ranker rule #2).

## Where to take this next

The brief lays out the test plan: 20–30 friendly users, 4 weeks, three numbers to track:

- **Cook-through rate** > 25 %
- **Daily opens** > 4 / week per user
- **Suggestion satisfaction** > 3.5 / 5

If those land, the next build adds weight tracking, expiry-based ranking weights, and the variety score. If they don't, the recipe set or the ranker are the place to iterate before adding anything else.

## Open follow-ups (not addressed in this build)

- Grow the recipe set to 100–150 (target from the brief).
- Add a proper image per recipe instead of an emoji placeholder.
- Surface a satisfaction rating prompt after a meal is logged via "I'll cook this".
- Friendly empty-state illustration instead of a plain text block on Tonight.
- Tests for the `Ranker` (golden cases for empty pantry, full pantry, recently cooked recipe).
