// HomeStore のユニットテスト（ウィジェットを pump しない）。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/composition/data/hive_drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/home/presentation/home_store.dart';
import 'package:pj_walter/features/monologue/data/hive_monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_result.dart';
import 'package:pj_walter/features/review/data/hive_srs_repository.dart';
import 'package:pj_walter/features/review/domain/load_review_session.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';
import 'package:pj_walter/features/stats/domain/daily_stats.dart';

import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/hive_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2026-09-06 は日曜日（weekday 7）
  final now = DateTime(2026, 9, 6, 9);
  late FakeSettingsRepository settings;
  late HiveSrsRepository srs;
  late HiveStudyStatsRepository stats;
  late HiveDrillHistoryRepository drillHistory;
  late HiveMonologueHistoryRepository monologueHistory;

  setUp(() async {
    await initTestHive();
    settings = FakeSettingsRepository();
    srs = HiveSrsRepository(
      await Hive.openBox('srs_items'),
      now: () => DateTime(2026, 9, 5),
    );
    stats = HiveStudyStatsRepository(
      await Hive.openBox('daily_stats'),
      now: () => now,
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

  HomeStore build({DateTime? at}) => HomeStore(
    settings: settings,
    srs: srs,
    stats: stats,
    drillHistory: drillHistory,
    monologueHistory: monologueHistory,
    loadReviewSession: LoadReviewSession(content: AssetContentRepository()),
    now: () => at ?? now,
  );

  test('初期状態: APIキー無し・復習0件・ストリーク0・今週の学習なし', () {
    final store = build();
    addTearDown(store.dispose);

    expect(store.hasApiKey.value, isFalse);
    expect(store.profile.value.code, 'en');
    expect(store.dueItems.value, isEmpty);
    expect(store.streak.value, 0);
    expect(store.todayStats.value, DailyStats.zero);
    expect(store.weekStudied.value, List.filled(7, false));
    expect(store.recentEntries.value, isEmpty);
    expect(store.greeting, GreetingKind.morning);
  });

  test('時間帯であいさつが変わる', () {
    expect(build(at: DateTime(2026, 9, 6, 3)).greeting, GreetingKind.evening);
    expect(
      build(at: DateTime(2026, 9, 6, 14)).greeting,
      GreetingKind.afternoon,
    );
    expect(build(at: DateTime(2026, 9, 6, 20)).greeting, GreetingKind.evening);
  });

  test('学習・復習・履歴の更新が Repository の signal から伝わる', () async {
    final store = build();
    addTearDown(store.dispose);

    await settings.setApiKey('key');
    expect(store.hasApiKey.value, isTrue);

    await stats.record(language: 'en', delta: const DailyStats(drillCount: 1));
    expect(store.todayStats.value.drillCount, 1);
    expect(store.streak.value, 1);
    // 日曜日（今週の最後）が学習済み
    expect(store.weekStudied.value, [
      false,
      false,
      false,
      false,
      false,
      false,
      true,
    ]);

    await srs.registerFailure(
      sentenceId: 's700-001',
      language: 'en',
      level: 700,
    );
    expect(store.dueItems.value, hasLength(1));

    await drillHistory.save(
      DrillResult(
        id: 'd-1',
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
        spoken: 's',
        timestamp: now.subtract(const Duration(days: 2)),
        feedback: const CompositionFeedback(
          score: 40,
          isAcceptable: false,
          corrected: 'c',
          explanation: '',
          comparison: '',
        ),
      ),
    );
    await monologueHistory.save(
      MonologueResult(
        id: 'm-1',
        topicId: 't-001',
        language: 'zh',
        seconds: 60,
        transcript: 't',
        timestamp: now,
        feedback: const MonologueFeedback(
          fluencyScore: 72,
          correctedTranscript: '',
          corrections: [],
          usefulPhrases: [],
          overallFeedback: '',
        ),
      ),
    );

    final recent = store.recentEntries.value;
    expect(recent, hasLength(2));
    expect(recent.first.isDrill, isFalse);
    expect(recent.first.language, 'zh');
    expect(store.daysAgo(recent.first.timestamp), 0);
    expect(recent.last.isDrill, isTrue);
    expect(store.daysAgo(recent.last.timestamp), 2);
  });

  test('loadReviewSentences は今日の復習を教材に解決する', () async {
    await srs.registerFailure(
      sentenceId: 's700-001',
      language: 'en',
      level: 700,
    );
    final store = build();
    addTearDown(store.dispose);

    final sentences = await store.loadReviewSentences();

    expect(sentences.map((s) => s.id), ['s700-001']);
    expect(store.startingReview.value, isFalse);
  });
}
