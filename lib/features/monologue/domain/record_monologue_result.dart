// コンストラクタの公開パラメータ名と内部実装用のプライベートフィールド名を
// あえて分けているため、initializing formalは使わない
// （使うとパラメータ名がprivateになり外部から渡せなくなる）。
// ignore_for_file: prefer_initializing_formals

import '../../stats/domain/daily_stats.dart';
import '../../stats/domain/study_stats_repository.dart';
import 'monologue_history_repository.dart';
import 'monologue_result.dart';

/// 独り言1回の結果を記録する UseCase（履歴の保存＋日次統計の加算）。
class RecordMonologueResult {
  const RecordMonologueResult({
    required MonologueHistoryRepository history,
    required StudyStatsRepository stats,
  }) : _history = history,
       _stats = stats;

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
