import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/score_square_badge.dart';
import '../../../core/widgets/section_header.dart';
import '../../composition/presentation/deck_select_screen.dart';
import '../../monologue/presentation/topic_select_screen.dart';
import '../../review/presentation/review_launcher.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../stats/domain/daily_stats.dart';
import 'home_store.dart';

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
  late final HomeStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).home();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _startReview() async {
    final sentences = await _store.loadReviewSentences();
    if (!mounted) return;
    await startReviewSession(context, sentences);
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(appRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context) {
          final profile = _store.profile.value;
          final dueItems = _store.dueItems.value;
          final recent = _store.recentEntries.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _GreetingHeader(
                greeting: l10n.greeting(_store.greeting.name),
                language: l10n.languageName(profile.code),
              ),
              const SizedBox(height: 16),
              if (!_store.hasApiKey.value) ...[
                _ApiKeyBanner(onTap: _openSettings),
                const SizedBox(height: 16),
              ],
              _StreakCard(
                streak: _store.streak.value,
                todayStats: _store.todayStats.value,
                weekStudied: _store.weekStudied.value,
              ),
              const SizedBox(height: 16),
              _TodayReviewCard(
                dueCount: dueItems.length,
                loading: _store.startingReview.value,
                onStart: _startReview,
              ),
              const SizedBox(height: 24),
              SectionHeader(title: l10n.trainingSection),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TrainingShortcutCard(
                      icon: Icons.edit_note,
                      title: l10n.compositionTitle(profile.code),
                      description: l10n.compositionShortcutDesc,
                      onTap: () {
                        Navigator.of(context).push(
                          appRoute(builder: (_) => const DeckSelectScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrainingShortcutCard(
                      icon: Icons.forum_outlined,
                      title: l10n.monologueTitle(profile.code),
                      description: l10n.monologueShortcutDesc,
                      onTap: () {
                        Navigator.of(context).push(
                          appRoute(builder: (_) => const TopicSelectScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 24),
                SectionHeader(title: l10n.recentStudy),
                const SizedBox(height: 12),
                _RecentHistoryCard(entries: recent, store: _store),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 最近の学習（ドリル・独り言の直近履歴）を1枚のカードにまとめたリスト。
class _RecentHistoryCard extends StatelessWidget {
  const _RecentHistoryCard({required this.entries, required this.store});

  final List<RecentEntry> entries;
  final HomeStore store;

  String _when(BuildContext context, DateTime timestamp) {
    final l10n = context.l10n;
    final days = store.daysAgo(timestamp);
    if (days <= 0) return l10n.today;
    if (days == 1) return l10n.yesterday;
    return l10n.daysAgo(days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: i == entries.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFF3F4F6)),
                      ),
              ),
              child: Row(
                children: [
                  ScoreSquareBadge(score: entries[i].score),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].isDrill
                              ? l10n.compositionTitle(entries[i].language)
                              : l10n.monologueTitle(entries[i].language),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entries[i].isDrill
                              ? l10n.drillRecentMeta(
                                  l10n.deckLevelLabel(
                                    entries[i].language,
                                    entries[i].level,
                                  ),
                                  entries[i].score,
                                )
                              : l10n.monologueRecentMeta(
                                  l10n.durationSeconds(entries[i].seconds),
                                  entries[i].score,
                                ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _when(context, entries[i].timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA0A6),
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting, required this.language});

  final String greeting;

  /// 学習中の言語名（「今日も◯◯を話そう」に差し込む）
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.greetingWave(greeting),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.todayLetsSpeak(language),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streak,
    required this.todayStats,
    required this.weekStudied,
  });

  final int streak;
  final DailyStats todayStats;

  /// 今週（月〜日）の各曜日に学習したかどうか
  final List<bool> weekStudied;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final studiedToday = todayStats.isStudyDay;
    final weekCount = weekStudied.where((v) => v).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$streak',
                style: const TextStyle(
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  l10n.streakDays,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.thisWeekDays(weekCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            studiedToday
                ? l10n.todayProgress(
                    todayStats.drillCount,
                    todayStats.monologueCount,
                  )
                : l10n.todayNothingYet,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(bottom: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: weekStudied[i]
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.25),
                        ),
                        child: weekStudied[i]
                            ? const Text(
                                '✓',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      Text(
                        l10n.weekdayShort('${i + 1}'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
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
    required this.dueCount,
    required this.loading,
    required this.onStart,
  });

  final int dueCount;
  final bool loading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (dueCount == 0) {
      return AppCard(
        child: Text(
          l10n.noReviewToday,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      );
    }
    return AppCard(
      onTap: loading ? null : onStart,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.refresh, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todayReview,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.reviewQueueCount(dueCount),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$dueCount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
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
      color: AppColors.scoreMediumSurface,
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.setApiKeyBanner,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
