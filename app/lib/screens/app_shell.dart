import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_translations.dart';
import '../l10n/locale_provider.dart';
import '../theme/app_theme.dart';
import 'log_screen.dart';
import 'pantry_screen.dart';
import 'profile_screen.dart';
import 'today_meal_screen.dart';
import 'weight_screen.dart';

/// Bottom-tab shell: Today · Pantry · Log · Weight · Profile.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _todayKey = GlobalKey<TonightScreenState>();

  late final List<Widget> _screens = [
    TonightScreen(key: _todayKey),
    const PantryScreen(),
    const LogScreen(),
    const WeightScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch so tabs rebuild when language changes.
    context.watch<LocaleProvider>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          if (i == 0) _todayKey.currentState?.reloadProfile();
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_outlined),
            activeIcon: const Icon(Icons.restaurant),
            label: t(context, 'tab_today'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            activeIcon: const Icon(Icons.inventory_2),
            label: t(context, 'tab_pantry'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: const Icon(Icons.menu_book),
            label: t(context, 'tab_meal_track'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monitor_weight_outlined),
            activeIcon: const Icon(Icons.monitor_weight),
            label: t(context, 'tab_weight'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: const Icon(Icons.person),
            label: t(context, 'tab_profile'),
          ),
        ],
      ),
    );
  }
}
