import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../composition/domain/drill_history_repository.dart';
import '../../content/domain/sentence.dart';
import '../../monologue/domain/monologue_history_repository.dart';
import '../../review/domain/load_review_session.dart';
import '../../review/domain/srs_item.dart';
import '../../review/domain/srs_repository.dart';
import '../../settings/domain/settings_repository.dart';
import '../../stats/domain/daily_stats.dart';
import '../../stats/domain/study_stats_repository.dart';

/// 時間帯のあいさつ（文言は ARB の `greeting`）。
enum GreetingKind { morning, afternoon, evening }

/// 最近の学習1件分の表示データ。
class RecentEntry {
  const RecentEntry({
    required this.isDrill,
    required this.language,
    required this.level,
    required this.seconds,
    required this.score,
    required this.timestamp,
  });

  final bool isDrill;
  final String language;

  /// 口頭作文のデッキレベル（独り言では 0）
  final int level;

  /// 独り言の発話秒数（口頭作文では 0）
  final int seconds;
  final int score;
  final DateTime timestamp;
}

/// ホームタブの Store。ストリーク・今日の学習量・今日の復習・最近の学習を派生する。
class HomeStore extends Store {
  HomeStore({
    required SettingsRepository settings,
    required this._srs,
    required StudyStatsRepository stats,
    required DrillHistoryRepository drillHistory,
    required MonologueHistoryRepository monologueHistory,
    required this._loadReviewSession,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    profile = createComputed(() => settings.settings.value.languageProfile);
    hasApiKey = createComputed(() => (settings.apiKey.value ?? '').isNotEmpty);
    dueItems = createComputed(() {
      _srs.items.value;
      return _srs.due(language: profile.value.code, now: _now());
    });
    streak = createComputed(() => stats.log.value.currentStreak(now: _now()));
    todayStats = createComputed(() => stats.log.value.forDate(_now()));
    weekStudied = createComputed(() {
      // 今週（月〜日）の各曜日に学習があったか。未来の曜日はfalse。
      final now = _now();
      final monday = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final log = stats.log.value;
      return [
        for (var i = 0; i < 7; i++)
          !monday.add(Duration(days: i)).isAfter(now) &&
              log.forDate(monday.add(Duration(days: i))).isStudyDay,
      ];
    });
    recentEntries = createComputed(() {
      // 履歴は言語混在なので、各エントリを記録された言語で表示する。
      final entries = <RecentEntry>[
        for (final r in drillHistory.results.value)
          RecentEntry(
            isDrill: true,
            language: r.language,
            level: r.level,
            seconds: 0,
            score: r.feedback.score,
            timestamp: r.timestamp,
          ),
        for (final r in monologueHistory.results.value)
          RecentEntry(
            isDrill: false,
            language: r.language,
            level: 0,
            seconds: r.seconds,
            score: r.feedback.fluencyScore,
            timestamp: r.timestamp,
          ),
      ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries.take(recentEntryCount).toList();
    });
    startingReview = createSignal(false);
  }

  /// 「最近の学習」に出す件数
  static const recentEntryCount = 3;

  final SrsRepository _srs;
  final LoadReviewSession _loadReviewSession;
  final DateTime Function() _now;

  late final Computed<LanguageProfile> profile;
  late final Computed<bool> hasApiKey;
  late final Computed<List<SrsItem>> dueItems;
  late final Computed<int> streak;
  late final Computed<DailyStats> todayStats;
  late final Computed<List<bool>> weekStudied;
  late final Computed<List<RecentEntry>> recentEntries;
  late final Signal<bool> startingReview;

  GreetingKind get greeting {
    final hour = _now().hour;
    if (hour < 5) return GreetingKind.evening;
    if (hour < 11) return GreetingKind.morning;
    if (hour < 18) return GreetingKind.afternoon;
    return GreetingKind.evening;
  }

  /// [timestamp]が今日から何日前か（0 = 今日）。
  int daysAgo(DateTime timestamp) {
    final now = _now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(timestamp.year, timestamp.month, timestamp.day))
        .inDays;
  }

  /// 今日の復習の出題文を解決する。解決中は [startingReview] が true。
  Future<List<Sentence>> loadReviewSentences() async {
    if (startingReview.value) return const [];
    startingReview.value = true;
    try {
      return await _loadReviewSession(dueItems.peek());
    } finally {
      if (!disposed) startingReview.value = false;
    }
  }
}
