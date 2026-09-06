import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../core/data/gemini_client.dart';
import '../review/domain/srs_repository.dart';
import '../stats/domain/study_stats_repository.dart';
import 'data/gemini_correction_repository.dart';
import 'data/hive_drill_history_repository.dart';
import 'domain/correction_repository.dart';
import 'domain/drill_history_repository.dart';
import 'domain/record_drill_result.dart';

/// composition feature の依存を登録する（コンポジションルートから呼ぶ）。
///
/// 次フェーズでは [GeminiCorrectionRepository] をサーバ呼び出しの実装に差し替える。
void registerComposition(GetIt getIt, {required Box drillResultsBox}) {
  getIt.registerLazySingleton<CorrectionRepository>(
    () => GeminiCorrectionRepository(getIt<GeminiClient>()),
  );
  getIt.registerLazySingleton<DrillHistoryRepository>(
    () => HiveDrillHistoryRepository(drillResultsBox),
  );
  getIt.registerLazySingleton<RecordDrillResult>(
    () => RecordDrillResult(
      history: getIt<DrillHistoryRepository>(),
      srs: getIt<SrsRepository>(),
      stats: getIt<StudyStatsRepository>(),
    ),
  );
}
