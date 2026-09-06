// StudyLog（日次統計の集計・ストリーク）の純粋ロジックのテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/features/stats/domain/daily_stats.dart';
import 'package:pj_walter/features/stats/domain/study_log.dart';

void main() {
  final today = DateTime(2026, 9, 6);
  DateTime daysAgo(int n) => DateTime(2026, 9, 6 - n);

  group('currentStreak', () {
    test('学習記録が全くない場合は0', () {
      expect(StudyLog.empty.currentStreak(now: today), 0);
    });

    test('今日だけ学習していれば1', () {
      final log = StudyLog.empty.adding(
        today,
        'en',
        const DailyStats(drillCount: 1),
      );
      expect(log.currentStreak(now: today), 1);
    });

    test('今日未学習でも昨日まで連続していればストリークは維持される', () {
      final log = StudyLog.empty
          .adding(daysAgo(1), 'en', const DailyStats(drillCount: 1))
          .adding(daysAgo(2), 'zh', const DailyStats(monologueCount: 1));
      expect(log.currentStreak(now: today), 2);
    });

    test('今日も昨日も未学習ならストリークは0（一昨日だけ学習）', () {
      final log = StudyLog.empty.adding(
        daysAgo(2),
        'en',
        const DailyStats(drillCount: 1),
      );
      expect(log.currentStreak(now: today), 0);
    });

    test('飛び日があるとそれより前の連続日はカウントしない', () {
      final log = StudyLog.empty
          .adding(today, 'en', const DailyStats(drillCount: 1))
          .adding(daysAgo(1), 'en', const DailyStats(drillCount: 1))
          // 2日前は未学習（飛び日）、3日前は学習済みだがカウント対象外
          .adding(daysAgo(3), 'en', const DailyStats(drillCount: 1));
      expect(log.currentStreak(now: today), 2);
    });

    test('言語を指定するとその言語だけで数える', () {
      final log = StudyLog.empty
          .adding(today, 'en', const DailyStats(drillCount: 1))
          .adding(daysAgo(1), 'zh', const DailyStats(drillCount: 1));
      expect(log.currentStreak(now: today), 2);
      expect(log.currentStreak(language: 'en', now: today), 1);
      expect(log.currentStreak(language: 'zh', now: today), 1);
    });
  });

  group('total / studyDayCount / languagesStudiedOn', () {
    test('データがなければ全て0', () {
      expect(StudyLog.empty.total(), DailyStats.zero);
      expect(StudyLog.empty.studyDayCount(), 0);
      expect(StudyLog.empty.languagesStudiedOn(today), isEmpty);
    });

    test('複数日・複数言語の統計を合計する', () {
      final log = StudyLog.empty
          .adding(
            today,
            'en',
            const DailyStats(
              drillCount: 2,
              monologueCount: 1,
              studySeconds: 30,
            ),
          )
          .adding(
            daysAgo(1),
            'zh',
            const DailyStats(drillCount: 3, studySeconds: 20),
          );

      expect(
        log.total(),
        const DailyStats(drillCount: 5, monologueCount: 1, studySeconds: 50),
      );
      expect(log.total(language: 'zh').drillCount, 3);
      expect(log.studyDayCount(), 2);
      expect(log.studyDayCount(language: 'en'), 1);
      expect(log.languagesStudiedOn(today), {'en'});
      expect(log.forDate(today, language: 'zh'), DailyStats.zero);
    });
  });

  group('lastDays', () {
    test('欠損日は0埋めで、古い→新しい順にdays件返す', () {
      final log = StudyLog.empty.adding(
        today,
        'en',
        const DailyStats(drillCount: 1),
      );

      final result = log.lastDays(3, now: today);

      expect(result, hasLength(3));
      expect(result.last.key, today);
      expect(result.last.value.drillCount, 1);
      expect(result.first.value.drillCount, 0);
      expect(result.first.key.isBefore(result.last.key), isTrue);
    });

    test('days:0なら空リストを返す', () {
      expect(StudyLog.empty.lastDays(0, now: today), isEmpty);
    });
  });
}
