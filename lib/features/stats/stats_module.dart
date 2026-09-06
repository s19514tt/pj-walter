import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import 'data/hive_study_stats_repository.dart';
import 'domain/study_stats_repository.dart';

/// stats feature の依存を登録する（コンポジションルートから呼ぶ）。
void registerStats(GetIt getIt, {required Box dailyStatsBox}) {
  getIt.registerLazySingleton<StudyStatsRepository>(
    () => HiveStudyStatsRepository(dailyStatsBox),
  );
}
