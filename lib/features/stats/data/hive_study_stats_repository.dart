import 'package:hive/hive.dart';
import 'package:signals_core/signals_core.dart';

import '../domain/daily_stats.dart';
import '../domain/study_log.dart';
import '../domain/study_stats_repository.dart';

/// [StudyStatsRepository] の Hive 実装（box `daily_stats`）。
///
/// キーは `YYYY-MM-DD`、値は `{言語コード: {drillCount, monologueCount, studySeconds}}`。
class HiveStudyStatsRepository implements StudyStatsRepository {
  HiveStudyStatsRepository(this._box, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _log = signal(StudyLog.empty) {
    _log.value = _readAll();
  }

  final Box _box;
  final DateTime Function() _now;
  final Signal<StudyLog> _log;

  @override
  ReadonlySignal<StudyLog> get log => _log;

  @override
  Future<void> record({
    required String language,
    required DailyStats delta,
  }) async {
    final date = _now();
    final key = StudyLog.dateKey(date);
    final day = _readDay(_box.get(key));
    final current = day[language] ?? DailyStats.zero;
    day[language] = current + delta;
    await _box.put(key, {
      for (final entry in day.entries) entry.key: _toJson(entry.value),
    });
    _log.value = _log.value.adding(date, language, delta);
  }

  StudyLog _readAll() => StudyLog({
    for (final key in _box.keys) key.toString(): _readDay(_box.get(key)),
  });

  static Map<String, DailyStats> _readDay(Object? raw) {
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(raw as Map);
    return {
      for (final entry in map.entries)
        entry.key: _fromJson(Map<String, dynamic>.from(entry.value as Map)),
    };
  }

  static DailyStats _fromJson(Map<String, dynamic> map) => DailyStats(
    drillCount: (map['drillCount'] as num?)?.toInt() ?? 0,
    monologueCount: (map['monologueCount'] as num?)?.toInt() ?? 0,
    studySeconds: (map['studySeconds'] as num?)?.toInt() ?? 0,
  );

  static Map<String, int> _toJson(DailyStats stats) => {
    'drillCount': stats.drillCount,
    'monologueCount': stats.monologueCount,
    'studySeconds': stats.studySeconds,
  };
}
