// StatsScreenのウィジェットテスト。
//
// Hive I/Oはtester.runAsync()で実の非同期ゾーンに切り替えて行う。

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/monologue/domain/monologue_result.dart';
import 'package:pj_walter/features/stats/presentation/stats_screen.dart';

import '../../../test_support/hive_test_support.dart';
import '../../../test_support/test_app.dart';
import '../../../test_support/test_dependencies.dart';

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

    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create();
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const StatsScreen()),
    );
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

    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create();
      await deps.recordDrill(
        DrillResult(
          id: 'd-1',
          sentenceId: 's700-001',
          language: 'en',
          level: 700,
          spoken: 'this is my spoken answer',
          timestamp: DateTime.now(),
          feedback: const CompositionFeedback(
            score: 85,
            isAcceptable: true,
            corrected: 'This is my corrected answer.',
            explanation: '解説テキスト',
            comparison: '比較テキスト',
          ),
        ),
        isReview: false,
      );
      await deps.recordMonologue(
        MonologueResult(
          id: 'm-1',
          topicId: 't-001',
          language: 'en',
          seconds: 60,
          transcript: 'my monologue transcript',
          timestamp: DateTime.now(),
          feedback: const MonologueFeedback(
            fluencyScore: 72,
            correctedTranscript: 'corrected transcript',
            corrections: [],
            usefulPhrases: [],
            overallFeedback: '総評テキスト',
          ),
        ),
      );
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const StatsScreen()),
    );
    await tester.pump();

    expect(find.text('連続日数'), findsOneWidget);
    expect(find.text('this is my spoken answer'), findsOneWidget);
    expect(find.text('my monologue transcript'), findsOneWidget);

    // 口頭作文の履歴をタップすると詳細ボトムシートが開く
    await tester.tap(find.text('this is my spoken answer'));
    await tester.pumpAndSettle();

    expect(find.text('あなたの発話'), findsOneWidget);
    expect(find.text('This is my corrected answer.'), findsOneWidget);
    expect(find.text('解説テキスト'), findsOneWidget);
  });

  testWidgets('カレンダーの月切替で表示月ラベルが変わる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create();
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const StatsScreen()),
    );
    await tester.pump();

    final now = DateTime.now();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();

    final prevMonth = DateTime(now.year, now.month - 1);
    expect(find.text('${prevMonth.year}年${prevMonth.month}月'), findsOneWidget);
  });
}
