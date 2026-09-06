// 旧 provider ベースの画面のための一時的なファサード。
// 画面が Store（signals）へ移行し終わったら削除する。

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../features/composition/data/hive_drill_history_repository.dart';
import '../features/composition/domain/drill_history_repository.dart';
import '../features/composition/domain/drill_result.dart';
import '../features/composition/domain/record_drill_result.dart';
import '../features/monologue/data/hive_monologue_history_repository.dart';
import '../features/monologue/domain/monologue_history_repository.dart';
import '../features/monologue/domain/monologue_result.dart';
import '../features/monologue/domain/record_monologue_result.dart';
import '../features/review/data/hive_phrase_repository.dart';
import '../features/review/data/hive_srs_repository.dart';
import '../features/review/domain/phrase.dart';
import '../features/review/domain/phrase_repository.dart';
import '../features/review/domain/srs_item.dart';
import '../features/review/domain/srs_repository.dart';
import '../features/stats/data/hive_study_stats_repository.dart';
import '../features/stats/domain/daily_stats.dart';
import '../features/stats/domain/study_stats_repository.dart';

/// 履歴・SRS・フレーズ帳・日次統計の Repository を `ChangeNotifier` として
/// 見せる移行用ファサード。
class HistoryService extends ChangeNotifier {
  HistoryService({
    required Box drillResultsBox,
    required Box monologueResultsBox,
    required Box srsItemsBox,
    required Box phrasesBox,
    required Box dailyStatsBox,
  }) : this.of(
         drillHistoryRepository: HiveDrillHistoryRepository(drillResultsBox),
         monologueHistoryRepository: HiveMonologueHistoryRepository(
           monologueResultsBox,
         ),
         srs: HiveSrsRepository(srsItemsBox),
         phraseRepository: HivePhraseRepository(phrasesBox),
         stats: HiveStudyStatsRepository(dailyStatsBox),
       );

  HistoryService.of({
    required this.drillHistoryRepository,
    required this.monologueHistoryRepository,
    required this.srs,
    required this.phraseRepository,
    required this.stats,
  }) {
    _cleanups = [
      drillHistoryRepository.results.subscribe((_) => notifyListeners()),
      monologueHistoryRepository.results.subscribe((_) => notifyListeners()),
      srs.items.subscribe((_) => notifyListeners()),
      phraseRepository.phrases.subscribe((_) => notifyListeners()),
      stats.log.subscribe((_) => notifyListeners()),
    ];
  }

  final DrillHistoryRepository drillHistoryRepository;
  final MonologueHistoryRepository monologueHistoryRepository;
  final SrsRepository srs;
  final PhraseRepository phraseRepository;
  final StudyStatsRepository stats;
  late final List<void Function()> _cleanups;

  Future<void> saveDrillResult(
    DrillResult result, {
    bool updateSrs = true,
  }) async {
    if (updateSrs) {
      await RecordDrillResult(
        history: drillHistoryRepository,
        srs: srs,
        stats: stats,
      )(result, isReview: false);
      return;
    }
    await drillHistoryRepository.save(result);
    await stats.record(
      language: result.language,
      delta: const DailyStats(drillCount: 1),
    );
  }

  List<DrillResult> get drillHistory => drillHistoryRepository.results.value;

  Future<void> saveMonologueResult(MonologueResult result) =>
      RecordMonologueResult(history: monologueHistoryRepository, stats: stats)(
        result,
      );

  List<MonologueResult> get monologueHistory =>
      monologueHistoryRepository.results.value;

  List<SrsItem> dueSrsItems({String? language}) => srs.due(language: language);

  List<SrsItem> get allSrsItems => srs.items.value;

  Future<void> applyReviewResult(String sentenceId, bool correct) =>
      srs.applyReviewResult(sentenceId, correct);

  Future<void> addPhrase(Phrase phrase) => phraseRepository.add(phrase);

  List<Phrase> get phrases => phraseRepository.phrases.value;

  Future<void> deletePhrase(String id) => phraseRepository.delete(id);

  Map<String, int> statsForDate(DateTime date, {String? language}) =>
      _toMap(stats.log.value.forDate(date, language: language));

  Set<String> languagesStudiedOn(DateTime date) =>
      stats.log.value.languagesStudiedOn(date);

  int currentStreak({String? language}) =>
      stats.log.value.currentStreak(language: language);

  Map<String, int> totalStats({String? language}) =>
      _toMap(stats.log.value.total(language: language));

  int studyDayCount({String? language}) =>
      stats.log.value.studyDayCount(language: language);

  List<MapEntry<DateTime, Map<String, int>>> statsForLastDays(
    int days, {
    String? language,
  }) => [
    for (final entry in stats.log.value.lastDays(days, language: language))
      MapEntry(entry.key, _toMap(entry.value)),
  ];

  static Map<String, int> _toMap(DailyStats s) => {
    'drillCount': s.drillCount,
    'monologueCount': s.monologueCount,
    'studySeconds': s.studySeconds,
  };

  @override
  void dispose() {
    for (final cleanup in _cleanups) {
      cleanup();
    }
    super.dispose();
  }
}
