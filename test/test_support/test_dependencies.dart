// 画面テスト用の依存一式。
//
// Hive 実装の Repository（一時ディレクトリ）とフェイクの設定を組み立て、
// GetIt.asNewInstance() に登録する。画面は scopedApp(getIt: deps.getIt, ...) で描く。

import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/composition/data/hive_drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/record_drill_result.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/content/domain/content_repository.dart';
import 'package:pj_walter/features/monologue/data/hive_monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/record_monologue_result.dart';
import 'package:pj_walter/features/review/data/hive_phrase_repository.dart';
import 'package:pj_walter/features/review/data/hive_srs_repository.dart';
import 'package:pj_walter/features/review/domain/load_review_session.dart';
import 'package:pj_walter/features/review/domain/phrase_repository.dart';
import 'package:pj_walter/features/review/domain/srs_repository.dart';
import 'package:pj_walter/features/settings/domain/app_settings.dart';
import 'package:pj_walter/features/settings/domain/settings_repository.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';
import 'package:pj_walter/features/stats/domain/study_stats_repository.dart';

import 'fake_settings_repository.dart';

/// テスト用に組み立てた依存一式（`initTestHive()` 済みであること）。
class TestDependencies {
  TestDependencies._({
    required this.getIt,
    required this.settings,
    required this.drillHistory,
    required this.monologueHistory,
    required this.srs,
    required this.phrases,
    required this.stats,
  });

  final GetIt getIt;
  final FakeSettingsRepository settings;
  final HiveDrillHistoryRepository drillHistory;
  final HiveMonologueHistoryRepository monologueHistory;
  final HiveSrsRepository srs;
  final HivePhraseRepository phrases;
  final HiveStudyStatsRepository stats;

  RecordDrillResult get recordDrill => getIt<RecordDrillResult>();
  RecordMonologueResult get recordMonologue => getIt<RecordMonologueResult>();

  /// Hive box を開いて Repository を組み立て、[GetIt.asNewInstance] に登録する。
  ///
  /// [srsNow] を渡すと SRS の「今日」（登録時の dueDate の基準）を固定できる。
  static Future<TestDependencies> create({
    String? apiKey,
    AppSettings initial = const AppSettings(),
    DateTime Function()? srsNow,
  }) async {
    final settings = FakeSettingsRepository(initial: initial, apiKey: apiKey);
    final drillHistory = HiveDrillHistoryRepository(
      await Hive.openBox('drill_results'),
    );
    final monologueHistory = HiveMonologueHistoryRepository(
      await Hive.openBox('monologue_results'),
    );
    final srs = HiveSrsRepository(await Hive.openBox('srs_items'), now: srsNow);
    final phrases = HivePhraseRepository(await Hive.openBox('phrases'));
    final stats = HiveStudyStatsRepository(await Hive.openBox('daily_stats'));
    final content = AssetContentRepository();
    final getIt = GetIt.asNewInstance()
      ..allowReassignment = true
      ..registerSingleton<SettingsRepository>(settings)
      ..registerSingleton<ContentRepository>(content)
      ..registerSingleton<DrillHistoryRepository>(drillHistory)
      ..registerSingleton<MonologueHistoryRepository>(monologueHistory)
      ..registerSingleton<SrsRepository>(srs)
      ..registerSingleton<PhraseRepository>(phrases)
      ..registerSingleton<StudyStatsRepository>(stats)
      ..registerSingleton<LoadReviewSession>(
        LoadReviewSession(content: content),
      )
      ..registerSingleton<RecordDrillResult>(
        RecordDrillResult(history: drillHistory, srs: srs, stats: stats),
      )
      ..registerSingleton<RecordMonologueResult>(
        RecordMonologueResult(history: monologueHistory, stats: stats),
      );
    return TestDependencies._(
      getIt: getIt,
      settings: settings,
      drillHistory: drillHistory,
      monologueHistory: monologueHistory,
      srs: srs,
      phrases: phrases,
      stats: stats,
    );
  }
}
