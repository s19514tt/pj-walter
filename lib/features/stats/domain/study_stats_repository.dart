import 'package:signals_core/signals_core.dart';

import 'daily_stats.dart';
import 'study_log.dart';

/// 日次の学習量（ストリーク・カレンダー・グラフの元データ）。
///
/// [log] はアプリ寿命の signal で、[record] のたびに差し替わる。
abstract interface class StudyStatsRepository {
  ReadonlySignal<StudyLog> get log;

  /// 今日の[language]の学習量に[delta]を加算する。
  Future<void> record({required String language, required DailyStats delta});
}
