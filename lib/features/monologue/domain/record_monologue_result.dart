import '../../stats/domain/daily_stats.dart';
import '../../stats/domain/study_stats_repository.dart';
import 'monologue_history_repository.dart';
import 'monologue_result.dart';

/// 独り言1回の結果を記録する UseCase（履歴の保存＋日次統計の加算）。
class RecordMonologueResult {
  const RecordMonologueResult({required this._history, required this._stats});

  final MonologueHistoryRepository _history;
  final StudyStatsRepository _stats;

  Future<void> call(MonologueResult result) async {
    await _history.save(result);
    await _stats.record(
      language: result.language,
      delta: DailyStats(monologueCount: 1, studySeconds: result.seconds),
    );
  }
}
