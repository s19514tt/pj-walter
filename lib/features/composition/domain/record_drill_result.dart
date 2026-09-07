import '../../review/domain/srs_repository.dart';
import '../../stats/domain/daily_stats.dart';
import '../../stats/domain/study_stats_repository.dart';
import 'drill_history_repository.dart';
import 'drill_result.dart';

/// 口頭作文1問の結果を記録する UseCase。
///
/// 履歴の保存・日次統計の加算・SRS の更新をまとめて行う（DESIGN.md「SRS アルゴリズム」）:
/// - 通常モード: スコアが [passingScore] 未満なら対象文を SRS キューに登録する
/// - 復習モード（[isReview]）: SRS の二重更新を避けるため登録はせず、
///   [SrsRepository.applyReviewResult] で stage を進める／戻す
class RecordDrillResult {
  const RecordDrillResult({
    required this._history,
    required this._srs,
    required this._stats,
  });

  final DrillHistoryRepository _history;
  final SrsRepository _srs;
  final StudyStatsRepository _stats;

  Future<void> call(DrillResult result, {required bool isReview}) async {
    await _history.save(result);
    await _stats.record(
      language: result.language,
      delta: const DailyStats(drillCount: 1),
    );
    if (isReview) {
      await _srs.applyReviewResult(
        result.sentenceId,
        result.feedback.isAcceptable,
      );
    } else if (result.feedback.score < passingScore) {
      await _srs.registerFailure(
        sentenceId: result.sentenceId,
        language: result.language,
        level: result.level,
      );
    }
  }
}
