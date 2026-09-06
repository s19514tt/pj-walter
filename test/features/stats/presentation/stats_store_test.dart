// StatsStore のユニットテスト（ウィジェットを pump しない）。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/composition/data/hive_drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/monologue/data/hive_monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_result.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';
import 'package:pj_walter/features/stats/domain/daily_stats.dart';
import 'package:pj_walter/features/stats/presentation/stats_store.dart';

import '../../../test_support/hive_test_support.dart';

DrillResult _drill(String id, DateTime at, {String sentenceId = 's700-001'}) =>
    DrillResult(
      id: id,
      sentenceId: sentenceId,
      language: 'en',
      level: 700,
      spoken: 'spoken $id',
      timestamp: at,
      feedback: const CompositionFeedback(
        score: 85,
        isAcceptable: true,
        corrected: 'c',
        explanation: '',
        comparison: '',
      ),
    );

MonologueResult _monologue(String id, DateTime at) => MonologueResult(
  id: id,
  topicId: 't-001',
  language: 'en',
  seconds: 60,
  transcript: 'transcript $id',
  timestamp: at,
  feedback: const MonologueFeedback(
    fluencyScore: 70,
    correctedTranscript: '',
    corrections: [],
    usefulPhrases: [],
    overallFeedback: '',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 9, 6, 12);
  late HiveStudyStatsRepository stats;
  late HiveDrillHistoryRepository drillHistory;
  late HiveMonologueHistoryRepository monologueHistory;

  setUp(() async {
    await initTestHive();
    stats = HiveStudyStatsRepository(
      await Hive.openBox('daily_stats'),
      now: () => today,
    );
    drillHistory = HiveDrillHistoryRepository(
      await Hive.openBox('drill_results'),
    );
    monologueHistory = HiveMonologueHistoryRepository(
      await Hive.openBox('monologue_results'),
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  StatsStore build() => StatsStore(
    stats: stats,
    drillHistory: drillHistory,
    monologueHistory: monologueHistory,
    content: AssetContentRepository(),
    now: () => today,
  );

  test('ストリーク・累計・直近7日・カレンダーは統計の signal から派生する', () async {
    final store = build();
    addTearDown(store.dispose);

    expect(store.streak.value, 0);
    expect(store.totalStats.value, DailyStats.zero);
    expect(store.lastWeek.value, hasLength(StatsStore.weeklyChartDays));
    expect(store.isStudyDay(today), isFalse);

    await stats.record(
      language: 'en',
      delta: const DailyStats(drillCount: 2, studySeconds: 90),
    );

    expect(store.streak.value, 1);
    expect(store.totalStats.value.drillCount, 2);
    expect(store.lastWeek.value.last.value.drillCount, 2);
    expect(store.isStudyDay(today), isTrue);
  });

  test('カレンダーの月は前後に切り替えられる', () {
    final store = build();
    addTearDown(store.dispose);

    expect(store.displayedMonth.value, DateTime(2026, 9));
    store.changeMonth(-1);
    expect(store.displayedMonth.value, DateTime(2026, 8));
    store.changeMonth(2);
    expect(store.displayedMonth.value, DateTime(2026, 10));
    expect(store.today, today);
  });

  test('履歴はドリル・独り言を混ぜて新しい順に並び、ページングできる', () async {
    for (var i = 0; i < historyPageSize + 1; i++) {
      await drillHistory.save(
        _drill('d-$i', today.subtract(Duration(minutes: i))),
      );
    }
    await monologueHistory.save(
      _monologue('m-1', today.add(const Duration(minutes: 1))),
    );
    final store = build();
    addTearDown(store.dispose);

    expect(store.entries.value, hasLength(historyPageSize + 2));
    expect(store.entries.value.first, isA<MonologueHistoryEntry>());
    expect(store.shownEntries.value, hasLength(historyPageSize));
    expect(store.remainingEntries.value, 2);

    store.showMore();
    expect(store.shownEntries.value, hasLength(historyPageSize + 2));
    expect(store.remainingEntries.value, 0);
  });

  test('詳細の原文・お題を教材から引く', () async {
    final store = build();
    addTearDown(store.dispose);

    expect(await store.drillSource(_drill('d', today)), isNotEmpty);
    expect(
      await store.drillSource(_drill('d', today, sentenceId: 'missing')),
      isNull,
    );
    expect(await store.topicSource(_monologue('m', today)), isNotEmpty);
  });
}
