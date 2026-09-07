import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../review/presentation/review_screen.dart';
import '../../stats/presentation/stats_screen.dart';
import 'home_screen.dart';
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
  // タブの選択は描画都合のローカル状態（業務状態ではない）
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    TrainingMenuScreen(),
    ReviewScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_note_outlined),
            activeIcon: const Icon(Icons.edit_note),
            label: l10n.tabTraining,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.refresh),
            label: l10n.review,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights_outlined),
            activeIcon: const Icon(Icons.insights),
            label: l10n.tabStats,
          ),
        ],
      ),
    );
  }
}
