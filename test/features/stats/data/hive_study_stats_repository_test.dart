// HiveStudyStatsRepository（日次統計の永続化と signal 更新）のテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';
import 'package:pj_walter/features/stats/domain/daily_stats.dart';

import '../../../test_support/hive_test_support.dart';

void main() {
  late Box box;
  final today = DateTime(2026, 9, 6, 10);

  setUp(() async {
    await initTestHive();
    box = await Hive.openBox('daily_stats');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test('recordで今日の言語別統計に加算され、signalが更新される', () async {
    final repository = HiveStudyStatsRepository(box, now: () => today);
    var notified = 0;
    final cleanup = repository.log.subscribe((_) => notified++);

    await repository.record(
      language: 'en',
      delta: const DailyStats(drillCount: 1),
    );
    await repository.record(
      language: 'zh',
      delta: const DailyStats(monologueCount: 1, studySeconds: 45),
    );
    await repository.record(
      language: 'en',
      delta: const DailyStats(drillCount: 1),
    );

    final log = repository.log.value;
    expect(log.forDate(today, language: 'en').drillCount, 2);
    expect(log.forDate(today, language: 'zh').studySeconds, 45);
    expect(log.forDate(today).monologueCount, 1);
    // subscribe は初回に現在値を流すので +1
    expect(notified, 4);
    cleanup();
  });

  test('保存した内容は別インスタンスで読み直せる（言語別の形式）', () async {
    final first = HiveStudyStatsRepository(box, now: () => today);
    await first.record(
      language: 'en',
      delta: const DailyStats(drillCount: 3, studySeconds: 20),
    );

    final reopened = HiveStudyStatsRepository(box, now: () => today);

    expect(reopened.log.value.forDate(today, language: 'en').drillCount, 3);
    expect(reopened.log.value.total().studySeconds, 20);
    expect(box.get('2026-09-06'), {
      'en': {'drillCount': 3, 'monologueCount': 0, 'studySeconds': 20},
    });
  });
}
