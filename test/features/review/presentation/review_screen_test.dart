// ReviewScreenのウィジェットテスト。
//
// Hive I/Oはtester.runAsync()で実の非同期ゾーンに切り替えて行う。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/features/review/domain/phrase.dart';
import 'package:pj_walter/features/review/presentation/review_screen.dart';

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

  testWidgets('復習が0件のとき空状態メッセージが表示され開始ボタンは出ない', (tester) async {
    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create();
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const ReviewScreen()),
    );
    await tester.pump();

    expect(find.text('今日の復習はありません🎉'), findsOneWidget);
    expect(find.text('復習予定の文はまだありません'), findsOneWidget);
    expect(find.text('フレーズはまだ登録されていません'), findsOneWidget);
  });

  testWidgets('復習アイテムがある場合は件数と開始ボタンが表示される', (tester) async {
    late TestDependencies deps;
    await tester.runAsync(() async {
      // 登録直後のdueDateは翌日なので、SRS の「今日」を1日戻した時計で組み立てる
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      deps = await TestDependencies.create(srsNow: () => yesterday);
      await deps.srs.registerFailure(
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
      );
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const ReviewScreen()),
    );
    await tester.pump();

    expect(find.text('1件を一括で開始'), findsOneWidget);
    expect(find.text('合計1件'), findsOneWidget);
    expect(find.text('TOEIC700点台の文'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
  });

  testWidgets('フレーズ帳の一覧表示・検索・削除ができる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late TestDependencies deps;
    await tester.runAsync(() async {
      deps = await TestDependencies.create();
      await deps.phrases.add(
        Phrase(
          id: 'p-1',
          target: 'break the ice',
          ja: '緊張をほぐす',
          source: 'manual',
          createdAt: DateTime(2026, 8, 1),
        ),
      );
      await deps.phrases.add(
        Phrase(
          id: 'p-2',
          target: 'slip my mind',
          ja: 'うっかり忘れる',
          source: 'manual',
          createdAt: DateTime(2026, 8, 2),
        ),
      );
    });

    await tester.pumpWidget(
      scopedApp(getIt: deps.getIt, home: const ReviewScreen()),
    );
    await tester.pump();

    expect(find.text('2件'), findsOneWidget);
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('slip my mind'), findsOneWidget);

    // 学習言語側で検索
    await tester.enterText(find.byType(TextField), 'break');
    await tester.pump();
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('slip my mind'), findsNothing);

    // 日本語側で検索
    await tester.enterText(find.byType(TextField), 'うっかり');
    await tester.pump();
    expect(find.text('slip my mind'), findsOneWidget);
    expect(find.text('break the ice'), findsNothing);

    // 一致なし
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('一致するフレーズがありません'), findsOneWidget);

    // 検索を消すと全件に戻る
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('slip my mind'), findsOneWidget);

    // 削除（Hive I/O）
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.text('slip my mind'), findsNothing);
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('削除しました'), findsOneWidget);
    expect(deps.phrases.phrases.value, hasLength(1));
  });
}
