// HomeScreenのウィジェットテスト。
//
// Hive I/Oはtester.runAsync()で実の非同期ゾーンに切り替えて行う。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/home/presentation/home_screen.dart';

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

  testWidgets('APIキー未設定・データ無し: バナー表示、復習0件、ストリーク0', (tester) async {
    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create();
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const HomeScreen()),
    );
    await tester.pump();

    expect(find.text('APIキーを設定してください'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('日連続'), findsOneWidget);
    expect(find.text('今週 0/7日'), findsOneWidget);
    expect(find.text('今日はまだ練習していません。3分だけ話してみましょう。'), findsOneWidget);
    expect(find.text('今日の復習はありません🎉'), findsOneWidget);
    expect(find.text('口頭英作文'), findsOneWidget);
    expect(find.text('独り言英会話'), findsOneWidget);
  });

  testWidgets('APIキー設定済みならバナーは表示されない', (tester) async {
    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create(apiKey: 'test-api-key');
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const HomeScreen()),
    );
    await tester.pump();

    expect(find.text('APIキーを設定してください'), findsNothing);
  });

  testWidgets('今日の復習がある場合は件数と開始ボタンが表示される', (tester) async {
    // 「最近の学習」はスクロール範囲外になるため縦に広げる
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late TestDependencies deps;
    await tester.runAsync(() async {
      // 不正解直後のdueDateは翌日なので、SRS の「今日」を1日戻した時計で
      // Repository を組み立てて、登録した文を「今日の復習」対象にする。
      final registeredAt = DateTime.now();
      final yesterday = registeredAt.subtract(const Duration(days: 1));
      deps = await TestDependencies.create(srsNow: () => yesterday);
      await deps.recordDrill(
        DrillResult(
          id: 'd-1',
          sentenceId: 's700-001',
          language: 'en',
          level: 700,
          spoken: 'spoken text',
          timestamp: registeredAt,
          feedback: const CompositionFeedback(
            score: 40,
            isAcceptable: false,
            corrected: 'corrected text',
            explanation: '解説',
            comparison: '比較',
          ),
        ),
        isReview: false,
      );
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const HomeScreen()),
    );
    await tester.pump();

    expect(find.text('今日の復習'), findsOneWidget);
    expect(find.textContaining('間隔反復キューに'), findsOneWidget);
    // 今日の学習量がストリークカードの本文に反映されている
    expect(find.textContaining('今日はドリル1問・独り言0回'), findsOneWidget);
    expect(find.text('日連続'), findsOneWidget);
    // 最近の学習に出る
    expect(find.text('最近の学習'), findsOneWidget);
    expect(find.text('TOEIC700点台 · 40点'), findsOneWidget);
  });

  testWidgets('トレーニングショートカットをタップすると各選択画面へ遷移する', (tester) async {
    // リデザインでカードが縦に増え、デフォルトのビューポートでは
    // トレーニンググリッドがスクロール範囲外になるため縦に広げる。
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create();
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const HomeScreen()),
    );
    await tester.pump();

    await tester.tap(find.text('口頭英作文'));
    await tester.pumpAndSettle();
    expect(find.text('レベルを選ぶ'), findsOneWidget);
  });
}
