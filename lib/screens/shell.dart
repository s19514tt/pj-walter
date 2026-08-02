import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'review_screen.dart';
import 'stats_screen.dart';
import 'training_menu_screen.dart';

/// BottomNavigationBar を持つアプリのシェル。
///
/// 4タブ: ホーム / 学習 / 復習 / 記録
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    TrainingMenuScreen(),
    ReviewScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: '学習',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.refresh), label: '復習'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: '記録',
          ),
        ],
      ),
    );
  }
}
