import 'package:flutter/material.dart';

/// FoodGoal palette — taken directly from the MVP screen sketches.
/// Green is the brand colour; everything else stays calm and low-contrast
/// so the suggestion cards do the talking.
class AppColors {
  static const brand = Color(0xFF1F6F4A);
  static const brandSoft = Color(0xFFE8F2EC);
  static const bg = Color(0xFFF4F6F4);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1A2A22);
  static const muted = Color(0xFF7A8A82);
  static const line = Color(0xFFE1E6E2);
  static const warning = Color(0xFFC97A3D);
  static const warningSoft = Color(0xFFFBEFE3);
}

ThemeData buildAppTheme() {
  const base = TextStyle(color: AppColors.text);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      surface: AppColors.card,
      onSurface: AppColors.text,
    ),
    fontFamily: '.SF Pro Text',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    textTheme: TextTheme(
      titleLarge: base.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
      titleMedium: base.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodyMedium: base.copyWith(fontSize: 14),
      bodySmall: base.copyWith(fontSize: 12, color: AppColors.muted),
      labelSmall: base.copyWith(
        fontSize: 11,
        color: AppColors.muted,
        letterSpacing: 0.5,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.brand,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
