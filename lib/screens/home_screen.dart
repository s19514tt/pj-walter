import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/review/domain/srs_item.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_route.dart';
import '../core/utils/review_launcher.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/score_square_badge.dart';
import '../core/widgets/section_header.dart';
import 'composition/deck_select_screen.dart';
import 'monologue/topic_select_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

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

  /// ドリル・独り言の履歴を新しい順に混ぜて上位3件を返す。
  List<_RecentEntry> _recentEntries(HistoryService history, DateTime now) {
    final l10n = context.l10n;
    // 履歴は言語混在なので、各エントリを記録された言語の呼び名で表示する。
    String when(DateTime t) {
      final days = DateTime(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime(t.year, t.month, t.day)).inDays;
      if (days <= 0) return '今日';
      if (days == 1) return '昨日';
      return '$days日前';
    }

    final entries = <(DateTime, _RecentEntry)>[
      for (final r in history.drillHistory)
        (
          r.timestamp,
          _RecentEntry(
            title: l10n.compositionTitle(r.language),
            meta:
                '${l10n.deckLevelLabel(r.language, r.level)}'
                ' · ${r.feedback.score}点',
            when: when(r.timestamp),
            score: r.feedback.score,
          ),
        ),
      for (final r in history.monologueHistory)
        (
          r.timestamp,
          _RecentEntry(
            title: l10n.monologueTitle(r.language),
            meta: '${r.seconds}秒 · 流暢さ${r.feedback.fluencyScore}',
            when: when(r.timestamp),
            score: r.feedback.fluencyScore,
          ),
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final e in entries.take(3)) e.$2];
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
    final dueItems = history.dueSrsItems(language: profile.code);
    final now = DateTime.now();
    final todayStats = history.statsForDate(now);
    // 今週（月〜日）の各曜日に学習があったか。未来の曜日はfalse。
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekStudied = [
      for (var i = 0; i < 7; i++)
        !monday.add(Duration(days: i)).isAfter(now) &&
            history
                    .statsForDate(monday.add(Duration(days: i)))
                    .values
                    .fold(0, (a, b) => a + b) >
                0,
    ];
    final recent = _recentEntries(history, now);

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
          _GreetingHeader(
            greeting: _greeting,
            language: context.l10n.languageName(profile.code),
          ),
          const SizedBox(height: 16),
          if (!settings.hasApiKey) ...[
            _ApiKeyBanner(onTap: _openSettings),
            const SizedBox(height: 16),
          ],
          _StreakCard(
            streak: history.currentStreak(),
            todayStats: todayStats,
            weekStudied: weekStudied,
          ),
          const SizedBox(height: 16),
          _TodayReviewCard(
            dueItems: dueItems,
            loading: _startingReview,
            onStart: () => _startReview(dueItems),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'トレーニング'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TrainingShortcutCard(
                  icon: Icons.edit_note,
                  title: context.l10n.compositionTitle(profile.code),
                  description: '制限時間内に発話',
                  onTap: () {
                    Navigator.of(
                      context,
                    ).push(appRoute(builder: (_) => const DeckSelectScreen()));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TrainingShortcutCard(
                  icon: Icons.forum_outlined,
                  title: context.l10n.monologueTitle(profile.code),
                  description: 'お題を30秒〜3分',
                  onTap: () {
                    Navigator.of(
                      context,
                    ).push(appRoute(builder: (_) => const TopicSelectScreen()));
                  },
                ),
              ),
            ],
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: '最近の学習'),
            const SizedBox(height: 12),
            _RecentHistoryCard(entries: recent),
          ],
        ],
      ),
    );
  }
}

/// 最近の学習1件分の表示データ。
class _RecentEntry {
  const _RecentEntry({
    required this.title,
    required this.meta,
    required this.when,
    required this.score,
  });

  final String title;
  final String meta;
  final String when;
  final int score;
}

/// 最近の学習（ドリル・独り言の直近履歴）を1枚のカードにまとめたリスト。
class _RecentHistoryCard extends StatelessWidget {
  const _RecentHistoryCard({required this.entries});

  final List<_RecentEntry> entries;

  @override
  Widget build(BuildContext context) {
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
                          entries[i].title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entries[i].meta,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    entries[i].when,
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
        Text(
          '今日も$languageを話そう',
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
  final Map<String, int> todayStats;

  /// 今週（月〜日）の各曜日に学習したかどうか
  final List<bool> weekStudied;

  @override
  Widget build(BuildContext context) {
    final drillCount = todayStats['drillCount'] ?? 0;
    final monologueCount = todayStats['monologueCount'] ?? 0;
    final studiedToday = drillCount + monologueCount > 0;
    final weekCount = weekStudied.where((v) => v).length;
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
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
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '日連続',
                  style: TextStyle(
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
                  '今週 $weekCount/7日',
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
                ? '今日はドリル$drillCount問・独り言$monologueCount回。いい調子です！'
                : '今日はまだ練習していません。3分だけ話してみましょう。',
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
                        labels[i],
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
                const Text(
                  '今日の復習',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '間隔反復キューに${dueItems.length}件たまっています',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${dueItems.length}',
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
