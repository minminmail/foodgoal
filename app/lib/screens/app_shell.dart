import 'package:flutter/material.dart';

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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight_outlined),
            activeIcon: Icon(Icons.monitor_weight),
            label: 'Weight',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
