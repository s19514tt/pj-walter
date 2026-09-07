import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../core/data/gemini_client.dart';
import '../stats/domain/study_stats_repository.dart';
import 'data/gemini_monologue_review_repository.dart';
import 'data/hive_monologue_history_repository.dart';
import 'domain/monologue_history_repository.dart';
import 'domain/monologue_review_repository.dart';
import 'domain/record_monologue_result.dart';

/// monologue feature の依存を登録する（コンポジションルートから呼ぶ）。
///
/// 次フェーズでは [GeminiMonologueReviewRepository] をサーバ呼び出しの実装に差し替える。
void registerMonologue(GetIt getIt, {required Box monologueResultsBox}) {
  getIt.registerLazySingleton<MonologueReviewRepository>(
    () => GeminiMonologueReviewRepository(getIt<GeminiClient>()),
  );
  getIt.registerLazySingleton<MonologueHistoryRepository>(
    () => HiveMonologueHistoryRepository(monologueResultsBox),
  );
  getIt.registerLazySingleton<RecordMonologueResult>(
    () => RecordMonologueResult(
      history: getIt<MonologueHistoryRepository>(),
      stats: getIt<StudyStatsRepository>(),
    ),
  );
}
