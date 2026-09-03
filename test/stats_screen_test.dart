// StatsScreenのウィジェットテスト。
//
// Hive I/Oはtester.runAsync()で実の非同期ゾーンに切り替えて行う
// （test/review_screen_test.dartと同じパターン）。

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/monologue_result.dart';
import 'package:pj_walter/screens/stats_screen.dart';
import 'package:pj_walter/services/history_service.dart';
import 'package:pj_walter/services/sentence_repository.dart';
import 'package:provider/provider.dart';

import 'test_support/hive_test_support.dart';

Future<HistoryService> _buildHistoryService() async => HistoryService(
  drillResultsBox: await Hive.openBox('drill_results'),
  monologueResultsBox: await Hive.openBox('monologue_results'),
  srsItemsBox: await Hive.openBox('srs_items'),
  phrasesBox: await Hive.openBox('phrases'),
  dailyStatsBox: await Hive.openBox('daily_stats'),
);

Widget _buildApp(HistoryService historyService) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<HistoryService>.value(value: historyService),
        Provider<SentenceRepository>(create: (_) => SentenceRepository()),
      ],
      child: const StatsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initTestHive();
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  testWidgets('データが無い場合はストリーク0・空状態メッセージが表示され落ちない', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late HistoryService historyService;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
    });

    await tester.pumpWidget(_buildApp(historyService));
    await tester.pump();

    expect(find.text('連続日数'), findsOneWidget);
    expect(find.text('総ドリル数'), findsOneWidget);
    expect(find.text('総学習分'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('まだ添削履歴がありません'), findsOneWidget);

    final now = DateTime.now();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
  });

  testWidgets('データがある場合はストリーク・履歴一覧が表示され、タップで詳細が開く', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late HistoryService historyService;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      await historyService.saveDrillResult(
        DrillResult(
          id: 'd-1',
          sentenceId: 's700-001',
          level: 700,
          spoken: 'this is my spoken answer',
          timestamp: DateTime.now(),
          feedback: const CompositionFeedback(
            score: 85,
            isAcceptable: true,
            corrected: 'This is my corrected answer.',
            explanationJa: '解説テキスト',
            comparisonJa: '比較テキスト',
          ),
        ),
      );
      await historyService.saveMonologueResult(
        MonologueResult(
          id: 'm-1',
          topicId: 't-001',
          seconds: 60,
          transcript: 'my monologue transcript',
          timestamp: DateTime.now(),
          feedback: const MonologueFeedback(
            fluencyScore: 72,
            correctedTranscript: 'corrected transcript',
            corrections: [],
            usefulPhrases: [],
            overallFeedbackJa: '総評テキスト',
          ),
        ),
      );
    });

    await tester.pumpWidget(_buildApp(historyService));
    await tester.pump();

    expect(find.text('連続日数'), findsOneWidget);
    expect(find.text('this is my spoken answer'), findsOneWidget);
    expect(find.text('my monologue transcript'), findsOneWidget);

    // 口頭英作文の履歴をタップすると詳細ボトムシートが開く
    await tester.tap(find.text('this is my spoken answer'));
    await tester.pumpAndSettle();

    expect(find.text('あなたの発話'), findsOneWidget);
    expect(find.text('This is my corrected answer.'), findsOneWidget);
    expect(find.text('解説テキスト'), findsOneWidget);
  });

  testWidgets('カレンダーの月切替で表示月ラベルが変わる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late HistoryService historyService;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
    });

    await tester.pumpWidget(_buildApp(historyService));
    await tester.pump();

    final now = DateTime.now();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();

    final prevMonth = DateTime(now.year, now.month - 1);
    expect(find.text('${prevMonth.year}年${prevMonth.month}月'), findsOneWidget);
  });
}
