import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/state/store.dart';
import '../../composition/domain/drill_history_repository.dart';
import '../../composition/domain/drill_result.dart';
import '../../content/domain/content_repository.dart';
import '../../../core/language/learning_language.dart';
import '../../monologue/domain/monologue_history_repository.dart';
import '../../monologue/domain/monologue_result.dart';
import '../domain/daily_stats.dart';
import '../domain/study_stats_repository.dart';

/// 履歴一覧で一度に表示する件数
const historyPageSize = 20;

/// 口頭作文・独り言のいずれか一方を保持する履歴エントリ。
sealed class HistoryEntry {
  const HistoryEntry();

  DateTime get timestamp;
  int get score;
}

class DrillHistoryEntry extends HistoryEntry {
  const DrillHistoryEntry(this.result);

  final DrillResult result;

  @override
  DateTime get timestamp => result.timestamp;

  @override
  int get score => result.feedback.score;
}

class MonologueHistoryEntry extends HistoryEntry {
  const MonologueHistoryEntry(this.result);

  final MonologueResult result;

  @override
  DateTime get timestamp => result.timestamp;

  @override
  int get score => result.feedback.fluencyScore;
}

/// 記録タブの Store。ストリーク・累計・直近7日・カレンダー・添削履歴を派生する。
class StatsStore extends Store {
  StatsStore({
    required this._stats,
    required DrillHistoryRepository drillHistory,
    required MonologueHistoryRepository monologueHistory,
    required this._content,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    final today = _now();
    displayedMonth = createSignal(DateTime(today.year, today.month));
    streak = createComputed(() => _stats.log.value.currentStreak(now: _now()));
    totalStats = createComputed(() => _stats.log.value.total());
    lastWeek = createComputed(
      () => _stats.log.value.lastDays(weeklyChartDays, now: _now()),
    );
    entries = createComputed(() {
      final list = <HistoryEntry>[
        for (final result in drillHistory.results.value)
          DrillHistoryEntry(result),
        for (final result in monologueHistory.results.value)
          MonologueHistoryEntry(result),
      ];
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
    limit = createSignal(historyPageSize);
    shownEntries = createComputed(
      () => entries.value.take(limit.value).toList(),
    );
    remainingEntries = createComputed(
      () => entries.value.length - shownEntries.value.length,
    );
  }

  /// 直近のグラフに出す日数
  static const weeklyChartDays = 7;

  final StudyStatsRepository _stats;
  final ContentRepository _content;
  final DateTime Function() _now;

  /// カレンダーの表示月（day は無視）
  late final Signal<DateTime> displayedMonth;
  late final Computed<int> streak;
  late final Computed<DailyStats> totalStats;
  late final Computed<List<MapEntry<DateTime, DailyStats>>> lastWeek;
  late final Computed<List<HistoryEntry>> entries;
  late final Signal<int> limit;
  late final Computed<List<HistoryEntry>> shownEntries;
  late final Computed<int> remainingEntries;

  /// 今日（カレンダーの強調用）
  DateTime get today => _now();

  /// [day]に学習したかどうか（`SignalBuilder` の中で呼ぶと log の変化に追従する）
  bool isStudyDay(DateTime day) => _stats.log.value.forDate(day).isStudyDay;

  void changeMonth(int delta) {
    final current = displayedMonth.value;
    displayedMonth.value = DateTime(current.year, current.month + delta);
  }

  void showMore() => limit.value += historyPageSize;

  /// 口頭作文の結果に対応する出題文（日本語）。教材から見つからなければ null。
  Future<String?> drillSource(DrillResult result) async {
    final sentences = await _content.sentences(
      profile: LanguageProfile.ofCode(result.language),
      level: result.level,
    );
    for (final s in sentences) {
      if (s.id == result.sentenceId) return s.ja;
    }
    return null;
  }

  /// 独り言の結果に対応するお題（日本語）。見つからなければ null。
  Future<String?> topicSource(MonologueResult result) async {
    final topics = await _content.topics(
      profile: LanguageProfile.ofCode(result.language),
    );
    for (final t in topics) {
      if (t.id == result.topicId) return t.ja;
    }
    return null;
  }
}
