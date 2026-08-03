import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/app_route.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import 'composition/deck_select_screen.dart';
import 'monologue/topic_select_screen.dart';

/// 学習タブ。「口頭英作文」「独り言英会話」の2つのトレーニングメニューを表示する。
class TrainingMenuScreen extends StatelessWidget {
  const TrainingMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学習')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'トレーニングを選ぶ'),
          const SizedBox(height: 12),
          AppCard(
            onTap: () {
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const DeckSelectScreen()));
            },
            child: const _MenuItem(
              icon: Icons.edit_note,
              title: '口頭英作文',
              description: '日本語文を見て制限時間内に英語で発話し、AIが添削します。',
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () {
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const TopicSelectScreen()));
            },
            child: const _MenuItem(
              icon: Icons.mic_none,
              title: '独り言英会話',
              description: 'お題について自由に話し、AIがフィードバックします。',
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
  }
}
