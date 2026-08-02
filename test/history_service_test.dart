// HistoryServiceのSRS（間隔反復）ロジック・履歴保存のテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/monologue_result.dart';
import 'package:pj_walter/models/phrase.dart';
import 'package:pj_walter/services/history_service.dart';

import 'test_support/hive_test_support.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DrillResult _drillResult({
  required String sentenceId,
  required int score,
  int level = 700,
}) => DrillResult(
  id: 'drill-$sentenceId-$score-${DateTime.now().microsecondsSinceEpoch}',
  sentenceId: sentenceId,
  level: level,
  spoken: 'spoken text',
  timestamp: DateTime.now(),
  feedback: CompositionFeedback(
    score: score,
    isAcceptable: score >= 70,
    corrected: 'corrected text',
    explanationJa: '解説',
    comparisonJa: '比較',
  ),
);

MonologueResult _monologueResult({int seconds = 60}) => MonologueResult(
  id: 'mono-${DateTime.now().microsecondsSinceEpoch}',
  topicId: 't-001',
  seconds: seconds,
  transcript: 'transcript',
  timestamp: DateTime.now(),
  feedback: const MonologueFeedback(
    fluencyScore: 80,
    correctedTranscript: 'corrected transcript',
    corrections: [],
    usefulPhrases: [],
    overallFeedbackJa: '総評',
  ),
);

void main() {
  late HistoryService historyService;

  setUp(() async {
    await initTestHive();
    final drillResultsBox = await Hive.openBox('drill_results');
    final monologueResultsBox = await Hive.openBox('monologue_results');
    final srsItemsBox = await Hive.openBox('srs_items');
    final phrasesBox = await Hive.openBox('phrases');
    final dailyStatsBox = await Hive.openBox('daily_stats');

    historyService = HistoryService(
      drillResultsBox: drillResultsBox,
      monologueResultsBox: monologueResultsBox,
      srsItemsBox: srsItemsBox,
      phrasesBox: phrasesBox,
      dailyStatsBox: dailyStatsBox,
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('saveDrillResult', () {
    test('スコア70未満でSRSキューにstage0で登録される', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-001', score: 50),
      );

      final items = historyService.allSrsItems;
      expect(items, hasLength(1));
      expect(items.first.sentenceId, 's700-001');
      expect(items.first.stage, 0);
      expect(items.first.lapses, 0);
      expect(
        _dateOnly(items.first.dueDate),
        _dateOnly(DateTime.now()).add(const Duration(days: 1)),
      );
    });

    test('スコア70以上ではSRSキューに登録されない', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-002', score: 90),
      );

      expect(historyService.allSrsItems, isEmpty);
    });

    test('既にキューにある文が再度不合格になるとlapsesが増えstage0に戻る', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-003', score: 50),
      );
      // 復習で一度昇格させておく
      await historyService.applyReviewResult('s700-003', true);
      expect(historyService.allSrsItems.first.stage, 1);

      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-003', score: 40),
      );

      final item = historyService.allSrsItems.first;
      expect(item.stage, 0);
      expect(item.lapses, 1);
    });

    test('日次統計のdrillCountが更新される', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-004', score: 90),
      );
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-005', score: 40),
      );

      final stats = historyService.statsForDate(DateTime.now());
      expect(stats['drillCount'], 2);
    });

    test('保存した結果が新しい順に取得できる', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-006', score: 90),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-007', score: 90),
      );

      final history = historyService.drillHistory;
      expect(history, hasLength(2));
      expect(history.first.sentenceId, 's700-007');
    });
  });

  group('applyReviewResult', () {
    test('正解するとstageが1進みdueDateが更新される', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-010', score: 50),
      );

      await historyService.applyReviewResult('s700-010', true);

      final item = historyService.allSrsItems.first;
      expect(item.stage, 1);
      expect(
        _dateOnly(item.dueDate),
        _dateOnly(DateTime.now()).add(const Duration(days: 3)),
      );
    });

    test('stage4から正解するとstage5で卒業しキューから削除される', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-011', score: 50),
      );
      // stage0 -> 1 -> 2 -> 3 -> 4
      for (var i = 0; i < 4; i++) {
        await historyService.applyReviewResult('s700-011', true);
      }
      expect(historyService.allSrsItems.first.stage, 4);

      // stage4 -> 5(卒業)
      await historyService.applyReviewResult('s700-011', true);

      expect(historyService.allSrsItems, isEmpty);
    });

    test('不正解だとstage0に戻る', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-012', score: 50),
      );
      await historyService.applyReviewResult('s700-012', true);
      expect(historyService.allSrsItems.first.stage, 1);

      await historyService.applyReviewResult('s700-012', false);

      final item = historyService.allSrsItems.first;
      expect(item.stage, 0);
    });

    test('存在しないsentenceIdに対しては何もしない', () async {
      await historyService.applyReviewResult('unknown', true);
      expect(historyService.allSrsItems, isEmpty);
    });
  });

  group('dueSrsItems', () {
    test('dueDateが今日以前のアイテムのみ返す（日単位比較）', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-020', score: 50),
      );
      // dueDateは翌日なので、まだ「今日の復習」には含まれない
      expect(historyService.dueSrsItems, isEmpty);

      // dueDateを今日に書き換える（内部boxを直接操作してシミュレート）
      final today = _dateOnly(DateTime.now());
      final item = historyService.allSrsItems.first;
      final adjusted = item.copyWith(dueDate: today);
      await Hive.box('srs_items').put(item.sentenceId, adjusted.toJson());

      expect(historyService.dueSrsItems, hasLength(1));
      expect(historyService.dueSrsItems.first.sentenceId, 's700-020');
    });
  });

  group('saveMonologueResult', () {
    test('保存後にmonologueCountとstudySecondsが更新される', () async {
      await historyService.saveMonologueResult(_monologueResult(seconds: 45));

      final stats = historyService.statsForDate(DateTime.now());
      expect(stats['monologueCount'], 1);
      expect(stats['studySeconds'], 45);
      expect(historyService.monologueHistory, hasLength(1));
    });
  });

  group('phrases', () {
    test('addPhraseで追加し新しい順に取得できる', () async {
      await historyService.addPhrase(
        Phrase(
          id: 'p-1',
          en: 'first phrase',
          ja: '最初のフレーズ',
          source: 'manual',
          createdAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await historyService.addPhrase(
        Phrase(
          id: 'p-2',
          en: 'second phrase',
          ja: '2番目のフレーズ',
          source: 'manual',
          createdAt: DateTime.now(),
        ),
      );

      final phrases = historyService.phrases;
      expect(phrases, hasLength(2));
      expect(phrases.first.id, 'p-2');
    });
  });
}
