import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/srs_item.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/review_launcher.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import 'composition/deck_select_screen.dart';
import 'monologue/topic_select_screen.dart';
import 'settings_screen.dart';

/// ホームタブ（ダッシュボード）。
///
/// ストリーク・今日の学習量・今日の復習・トレーニングへのショートカットを
/// 表示する。APIキー未設定時は設定を促すバナーも表示する。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _launcher = const ReviewSessionLauncher();
  bool _startingReview = false;

  Future<void> _startReview(List<SrsItem> dueItems) async {
    if (_startingReview) return;
    setState(() => _startingReview = true);
    await _launcher.start(context, dueItems);
    if (!mounted) return;
    setState(() => _startingReview = false);
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();
    final settings = context.watch<SettingsService>();
    final dueItems = history.dueSrsItems;
    final todayStats = history.statsForDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('pj-walter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!settings.hasApiKey) ...[
            _ApiKeyBanner(onTap: _openSettings),
            const SizedBox(height: 16),
          ],
          _StreakCard(streak: history.currentStreak, todayStats: todayStats),
          const SizedBox(height: 24),
          const SectionHeader(title: '今日の復習'),
          const SizedBox(height: 12),
          _TodayReviewCard(
            dueItems: dueItems,
            loading: _startingReview,
            onStart: () => _startReview(dueItems),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: '今日のトレーニング'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrainingShortcutCard(
                  icon: Icons.edit_note,
                  title: '口頭英作文',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeckSelectScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TrainingShortcutCard(
                  icon: Icons.mic_none,
                  title: '独り言英会話',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TopicSelectScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.todayStats});

  final int streak;
  final Map<String, int> todayStats;

  @override
  Widget build(BuildContext context) {
    final todayCount =
        (todayStats['drillCount'] ?? 0) + (todayStats['monologueCount'] ?? 0);
    return AppCard(
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak日連続',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '今日の学習: $todayCount件',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayReviewCard extends StatelessWidget {
  const _TodayReviewCard({
    required this.dueItems,
    required this.loading,
    required this.onStart,
  });

  final List<SrsItem> dueItems;
  final bool loading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (dueItems.isEmpty) {
      return const AppCard(
        child: Text(
          '今日の復習はありません🎉',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dueItems.length}件の復習があります',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: '復習を始める', loading: loading, onPressed: onStart),
        ],
      ),
    );
  }
}

class _TrainingShortcutCard extends StatelessWidget {
  const _TrainingShortcutCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Text(
                '始める',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Spacer(),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApiKeyBanner extends StatelessWidget {
  const _ApiKeyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'APIキーが未設定です',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gemini APIキーを設定すると添削機能が使えます',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
