// HistoryServiceのSRS（間隔反復）ロジック・履歴保存のテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/monologue_result.dart';
import 'package:pj_walter/models/phrase.dart';
import 'package:pj_walter/services/history_service.dart';

import 'test_support/hive_test_support.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// テスト用に`daily_stats` boxへ直接、任意の日の統計を書き込む。
Future<void> _setDailyStats(
  DateTime date, {
  int drillCount = 0,
  int monologueCount = 0,
  int studySeconds = 0,
}) async {
  await Hive.box('daily_stats').put(_dateKey(date), {
    'drillCount': drillCount,
    'monologueCount': monologueCount,
    'studySeconds': studySeconds,
  });
}

DrillResult _drillResult({
  required String sentenceId,
  required int score,
  int level = 700,
}) => DrillResult(
  id: 'drill-$sentenceId-$score-${DateTime.now().microsecondsSinceEpoch}',
  sentenceId: sentenceId,
  language: 'en',
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
  language: 'en',
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

    test('updateSrs:falseならスコア70未満でもSRSキューに登録されない', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-030', score: 30),
        updateSrs: false,
      );

      expect(historyService.allSrsItems, isEmpty);
      expect(historyService.drillHistory, hasLength(1));
    });

    test('updateSrs:falseでも履歴・日次統計は通常通り記録される', () async {
      await historyService.saveDrillResult(
        _drillResult(sentenceId: 's700-031', score: 90),
        updateSrs: false,
      );

      final stats = historyService.statsForDate(DateTime.now());
      expect(stats['drillCount'], 1);
      expect(historyService.drillHistory, hasLength(1));
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
      expect(historyService.dueSrsItems(), isEmpty);

      // dueDateを今日に書き換える（内部boxを直接操作してシミュレート）
      final today = _dateOnly(DateTime.now());
      final item = historyService.allSrsItems.first;
      final adjusted = item.copyWith(dueDate: today);
      await Hive.box('srs_items').put(item.sentenceId, adjusted.toJson());

      expect(historyService.dueSrsItems(), hasLength(1));
      expect(historyService.dueSrsItems().first.sentenceId, 's700-020');
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
          target: 'first phrase',
          ja: '最初のフレーズ',
          source: 'manual',
          createdAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await historyService.addPhrase(
        Phrase(
          id: 'p-2',
          target: 'second phrase',
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

  group('deletePhrase', () {
    test('指定idのフレーズだけが削除される', () async {
      await historyService.addPhrase(
        Phrase(
          id: 'p-10',
          target: 'break the ice',
          ja: '緊張をほぐす',
          source: 'manual',
          createdAt: DateTime.now(),
        ),
      );
      await historyService.addPhrase(
        Phrase(
          id: 'p-11',
          target: 'slip my mind',
          ja: 'うっかり忘れる',
          source: 'manual',
          createdAt: DateTime.now(),
        ),
      );

      await historyService.deletePhrase('p-10');

      final phrases = historyService.phrases;
      expect(phrases, hasLength(1));
      expect(phrases.first.id, 'p-11');
    });

    test('存在しないidを指定しても例外にならない', () async {
      await expectLater(historyService.deletePhrase('unknown'), completes);
      expect(historyService.phrases, isEmpty);
    });
  });

  group('currentStreak', () {
    test('学習記録が全くない場合は0', () {
      expect(historyService.currentStreak(), 0);
    });

    test('今日だけ学習していれば1', () async {
      await _setDailyStats(DateTime.now(), drillCount: 1);
      expect(historyService.currentStreak(), 1);
    });

    test('今日未学習でも昨日まで連続していればストリークは維持される', () async {
      final today = _dateOnly(DateTime.now());
      await _setDailyStats(
        today.subtract(const Duration(days: 1)),
        drillCount: 1,
      );
      await _setDailyStats(
        today.subtract(const Duration(days: 2)),
        monologueCount: 1,
      );

      expect(historyService.currentStreak(), 2);
    });

    test('今日も昨日も未学習ならストリークは0（一昨日だけ学習）', () async {
      final today = _dateOnly(DateTime.now());
      await _setDailyStats(
        today.subtract(const Duration(days: 2)),
        drillCount: 1,
      );

      expect(historyService.currentStreak(), 0);
    });

    test('飛び日があるとそれより前の連続日はカウントしない', () async {
      final today = _dateOnly(DateTime.now());
      await _setDailyStats(today, drillCount: 1);
      await _setDailyStats(
        today.subtract(const Duration(days: 1)),
        drillCount: 1,
      );
      // 2日前は未学習（飛び日）、3日前は学習済みだがカウント対象外
      await _setDailyStats(
        today.subtract(const Duration(days: 3)),
        drillCount: 1,
      );

      expect(historyService.currentStreak(), 2);
    });
  });

  group('totalStats', () {
    test('データがなければ全て0', () {
      expect(historyService.totalStats(), {
        'drillCount': 0,
        'monologueCount': 0,
        'studySeconds': 0,
      });
    });

    test('複数日分の統計を合計する', () async {
      final today = _dateOnly(DateTime.now());
      await _setDailyStats(
        today,
        drillCount: 2,
        monologueCount: 1,
        studySeconds: 30,
      );
      await _setDailyStats(
        today.subtract(const Duration(days: 1)),
        drillCount: 3,
        studySeconds: 20,
      );

      final total = historyService.totalStats();
      expect(total['drillCount'], 5);
      expect(total['monologueCount'], 1);
      expect(total['studySeconds'], 50);
    });
  });

  group('statsForLastDays', () {
    test('欠損日は0埋めで、古い→新しい順にdays件返す', () async {
      final today = _dateOnly(DateTime.now());
      await _setDailyStats(today, drillCount: 1);

      final result = historyService.statsForLastDays(3);

      expect(result, hasLength(3));
      expect(result.last.key, today);
      expect(result.last.value['drillCount'], 1);
      expect(result.first.value['drillCount'], 0);
      expect(result.first.key.isBefore(result.last.key), isTrue);
    });

    test('days:0なら空リストを返す', () {
      expect(historyService.statsForLastDays(0), isEmpty);
    });
  });
}
