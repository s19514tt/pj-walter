// RecordDrillResult（履歴保存＋日次統計＋SRS更新の UseCase）のテスト。
//
// Hive 実装の Repository を実際に使い、通常モードと復習モードで
// SRS の扱いが変わることを担保する。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/composition/data/hive_drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/composition/domain/record_drill_result.dart';
import 'package:pj_walter/features/monologue/data/hive_monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_result.dart';
import 'package:pj_walter/features/monologue/domain/record_monologue_result.dart';
import 'package:pj_walter/features/review/data/hive_srs_repository.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';

import '../../../test_support/hive_test_support.dart';

final _now = DateTime(2026, 9, 6, 12);

DrillResult _drillResult({
  required String sentenceId,
  required int score,
  DateTime? timestamp,
}) => DrillResult(
  id: 'drill-$sentenceId-$score',
  sentenceId: sentenceId,
  language: 'en',
  level: 700,
  spoken: 'spoken text',
  timestamp: timestamp ?? _now,
  feedback: CompositionFeedback(
    score: score,
    isAcceptable: score >= 70,
    corrected: 'corrected text',
    explanation: '解説',
    comparison: '比較',
  ),
);

void main() {
  late HiveDrillHistoryRepository history;
  late HiveSrsRepository srs;
  late HiveStudyStatsRepository stats;
  late RecordDrillResult record;

  setUp(() async {
    await initTestHive();
    history = HiveDrillHistoryRepository(await Hive.openBox('drill_results'));
    srs = HiveSrsRepository(await Hive.openBox('srs_items'), now: () => _now);
    stats = HiveStudyStatsRepository(
      await Hive.openBox('daily_stats'),
      now: () => _now,
    );
    record = RecordDrillResult(history: history, srs: srs, stats: stats);
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test('スコア70未満でSRSキューにstage0で登録される', () async {
    await record(
      _drillResult(sentenceId: 's700-001', score: 50),
      isReview: false,
    );

    final items = srs.items.value;
    expect(items, hasLength(1));
    expect(items.first.sentenceId, 's700-001');
    expect(items.first.stage, 0);
    expect(items.first.dueDate, DateTime(2026, 9, 7));
  });

  test('スコア70以上ではSRSキューに登録されない', () async {
    await record(
      _drillResult(sentenceId: 's700-002', score: 90),
      isReview: false,
    );

    expect(srs.items.value, isEmpty);
  });

  test('日次統計のdrillCountが更新され、履歴は新しい順に並ぶ', () async {
    await record(
      _drillResult(sentenceId: 's700-004', score: 90, timestamp: _now),
      isReview: false,
    );
    await record(
      _drillResult(
        sentenceId: 's700-005',
        score: 40,
        timestamp: _now.add(const Duration(minutes: 1)),
      ),
      isReview: false,
    );

    expect(stats.log.value.forDate(_now).drillCount, 2);
    expect(history.results.value.map((r) => r.sentenceId), [
      's700-005',
      's700-004',
    ]);
  });

  test('復習モードでは登録せず、正解ならstageを進める', () async {
    await srs.registerFailure(
      sentenceId: 's700-030',
      language: 'en',
      level: 700,
    );

    await record(
      _drillResult(sentenceId: 's700-030', score: 90),
      isReview: true,
    );

    expect(srs.items.value.single.stage, 1);
    expect(history.results.value, hasLength(1));
    expect(stats.log.value.forDate(_now).drillCount, 1);
  });

  test('復習モードで不正解ならstage0に戻り、二重登録（lapses増）はしない', () async {
    await srs.registerFailure(
      sentenceId: 's700-031',
      language: 'en',
      level: 700,
    );
    await srs.applyReviewResult('s700-031', true);

    await record(
      _drillResult(sentenceId: 's700-031', score: 30),
      isReview: true,
    );

    final item = srs.items.value.single;
    expect(item.stage, 0);
    expect(item.lapses, 0);
  });

  test('復習モードでキューに無い文を記録しても落ちない', () async {
    await record(
      _drillResult(sentenceId: 'unknown', score: 30),
      isReview: true,
    );

    expect(srs.items.value, isEmpty);
    expect(history.results.value, hasLength(1));
  });

  test('RecordMonologueResult は履歴とmonologueCount・studySecondsを記録する', () async {
    final monologueHistory = HiveMonologueHistoryRepository(
      await Hive.openBox('monologue_results'),
    );
    final recordMonologue = RecordMonologueResult(
      history: monologueHistory,
      stats: stats,
    );

    await recordMonologue(
      MonologueResult(
        id: 'mono-1',
        topicId: 't-001',
        language: 'en',
        seconds: 45,
        transcript: 'transcript',
        timestamp: _now,
        feedback: const MonologueFeedback(
          fluencyScore: 80,
          correctedTranscript: 'corrected transcript',
          corrections: [],
          usefulPhrases: [],
          overallFeedback: '総評',
        ),
      ),
    );

    final today = stats.log.value.forDate(_now);
    expect(today.monologueCount, 1);
    expect(today.studySeconds, 45);
    expect(monologueHistory.results.value, hasLength(1));
  });
}
