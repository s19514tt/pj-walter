import 'package:flutter/material.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_route.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/section_header.dart';
import '../features/composition/presentation/deck_select_screen.dart';
import '../features/monologue/presentation/topic_select_screen.dart';
import 'package:provider/provider.dart';
import '../core/language/learning_language.dart';
import '../services/settings_service.dart';

/// 学習タブ。口頭作文・独り言の2つのトレーニングメニューを表示する。
///
/// トレーニングの呼び名と説明文は学習言語（[LanguageProfile]）で変わる。
class TrainingMenuScreen extends StatelessWidget {
  const TrainingMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SettingsService>().languageProfile;
    final l10n = context.l10n;
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
            child: _MenuItem(
              icon: Icons.edit_note,
              title: l10n.compositionTitle(profile.code),
              description:
                  '日本語文を見て制限時間内に${l10n.languageName(profile.code)}で発話し、AIが添削します。',
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () {
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const TopicSelectScreen()));
            },
            child: _MenuItem(
              icon: Icons.mic_none,
              title: l10n.monologueTitle(profile.code),
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
