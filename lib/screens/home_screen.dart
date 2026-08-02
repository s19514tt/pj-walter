import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import 'settings_screen.dart';

/// ホームタブ（ダッシュボード）。
///
/// 将来的にストリークや今日の復習件数、開始ボタンなどを表示する。
/// PR1時点ではプレースホルダー。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('pj-walter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: '今日の学習'),
          const SizedBox(height: 12),
          const AppCard(
            child: Text(
              'ここに今日のストリークや復習件数が表示される予定です。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
