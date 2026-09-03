import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/srs_item.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_route.dart';
import '../utils/review_launcher.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import 'composition/deck_select_screen.dart';
import 'monologue/topic_select_screen.dart';
import 'settings_screen.dart';

/// ホームタブ（ダッシュボード）。
///
/// あいさつ・ストリーク・今日の学習量・今日の復習・トレーニングへの
/// ショートカットを表示する。APIキー未設定時は設定を促すバナーも表示する。
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
    ).push(appRoute(builder: (_) => const SettingsScreen()));
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'こんばんは';
    if (hour < 11) return 'おはよう';
    if (hour < 18) return 'こんにちは';
    return 'こんばんは';
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();
    final settings = context.watch<SettingsService>();
    final profile = settings.languageProfile;
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
          _GreetingHeader(greeting: _greeting),
          const SizedBox(height: 16),
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
          _TrainingShortcutCard(
            icon: Icons.edit_note,
            title: profile.compositionTitle,
            description: '日本語文を見て制限時間内に${profile.label}で発話し、AIが添削します。',
            onTap: () {
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const DeckSelectScreen()));
            },
          ),
          const SizedBox(height: 12),
          _TrainingShortcutCard(
            icon: Icons.mic_none,
            title: profile.monologueTitle,
            description: 'お題について自由に話し、AIがフィードバックします。',
            onTap: () {
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const TopicSelectScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '今日も英語を話そう',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.todayStats});

  final int streak;
  final Map<String, int> todayStats;

  @override
  Widget build(BuildContext context) {
    final drillCount = todayStats['drillCount'] ?? 0;
    final monologueCount = todayStats['monologueCount'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$streak日連続',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ドリル $drillCount問',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '独り言 $monologueCount回',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
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
      child: Row(
        children: [
          Text(
            '${dueItems.length}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '件の復習があります',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          PrimaryButton(
            label: '復習を始める',
            loading: loading,
            onPressed: onStart,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _TrainingShortcutCard extends StatelessWidget {
  const _TrainingShortcutCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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
      color: AppColors.scoreMediumSurface,
      child: const Row(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'APIキーを設定してください',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
