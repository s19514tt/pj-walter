// ReviewScreenのウィジェットテスト。
//
// Hive I/Oはtester.runAsync()で実の非同期ゾーンに切り替えて行う
// （test/composition/drill_screen_test.dartと同じパターン）。

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/phrase.dart';
import 'package:pj_walter/screens/review_screen.dart';
import 'package:pj_walter/services/history_service.dart';
import 'package:pj_walter/services/sentence_repository.dart';
import 'package:pj_walter/services/settings_service.dart';
import 'package:provider/provider.dart';

import 'test_support/hive_test_support.dart';

Future<HistoryService> _buildHistoryService() async => HistoryService(
  drillResultsBox: await Hive.openBox('drill_results'),
  monologueResultsBox: await Hive.openBox('monologue_results'),
  srsItemsBox: await Hive.openBox('srs_items'),
  phrasesBox: await Hive.openBox('phrases'),
  dailyStatsBox: await Hive.openBox('daily_stats'),
);

Future<SettingsService> _buildSettingsService() async {
  final settings = SettingsService(settingsBox: await Hive.openBox('settings'));
  await settings.init();
  return settings;
}

// Providerはmain.dartと同じくMaterialAppの外側に置く。home:の内側に置くと
// push先の画面（復習ドリルなど）からProviderが見えない。
Widget _buildApp(HistoryService historyService, SettingsService settings) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HistoryService>.value(value: historyService),
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      Provider<SentenceRepository>(create: (_) => SentenceRepository()),
    ],
    child: const MaterialApp(home: ReviewScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initTestHive();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  testWidgets('復習が0件のとき空状態メッセージが表示され開始ボタンは出ない', (tester) async {
    late HistoryService historyService;
    late SettingsService settings;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      settings = await _buildSettingsService();
    });

    await tester.pumpWidget(_buildApp(historyService, settings));
    await tester.pump();

    expect(find.textContaining('今日の復習はありません'), findsOneWidget);
    expect(find.text('今日の復習はありません🎉'), findsOneWidget);
    expect(find.text('復習予定の文はまだありません'), findsOneWidget);
    expect(find.text('フレーズはまだ登録されていません'), findsOneWidget);
  });

  testWidgets('復習アイテムがある場合は件数と開始ボタンが表示される', (tester) async {
    late HistoryService historyService;
    late SettingsService settings;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      settings = await _buildSettingsService();
      await historyService.saveDrillResult(
        DrillResult(
          id: 'd-1',
          sentenceId: 's700-001',
          language: 'en',
          level: 700,
          spoken: 'spoken text',
          timestamp: DateTime.now(),
          feedback: const CompositionFeedback(
            score: 40,
            isAcceptable: false,
            corrected: 'corrected text',
            explanationJa: '解説',
            comparisonJa: '比較',
          ),
        ),
      );
      // 不正解直後のdueDateは翌日なので、今日の日付に書き換えて
      // 「今日の復習」対象にする。
      final item = historyService.allSrsItems.first;
      final today = DateTime.now();
      await Hive.box('srs_items').put(
        item.sentenceId,
        item
            .copyWith(dueDate: DateTime(today.year, today.month, today.day))
            .toJson(),
      );
    });

    await tester.pumpWidget(_buildApp(historyService, settings));
    await tester.pump();

    expect(find.text('1件を一括で開始'), findsOneWidget);
    expect(find.text('合計1件'), findsOneWidget);
  });

  testWidgets('フレーズ帳の一覧表示・検索・削除ができる', (tester) async {
    late HistoryService historyService;
    late SettingsService settings;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      settings = await _buildSettingsService();
      await historyService.addPhrase(
        Phrase(
          id: 'p-1',
          target: 'break the ice',
          ja: '緊張をほぐす',
          source: 'manual',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await historyService.addPhrase(
        Phrase(
          id: 'p-2',
          target: 'slip my mind',
          ja: 'うっかり忘れる',
          source: 'manual',
          createdAt: DateTime(2026, 1, 2),
        ),
      );
    });

    await tester.pumpWidget(_buildApp(historyService, settings));
    await tester.pump();

    // 新しい順（p-2が先）で両方表示されている
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('slip my mind'), findsOneWidget);

    // en部分一致で検索すると絞り込まれる
    await tester.enterText(find.byType(TextField), 'break');
    await tester.pump();
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('slip my mind'), findsNothing);

    // ja部分一致でも検索できる
    await tester.enterText(find.byType(TextField), 'うっかり');
    await tester.pump();
    expect(find.text('slip my mind'), findsOneWidget);
    expect(find.text('break the ice'), findsNothing);

    // 一致しない語では「一致するフレーズがありません」を表示する
    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pump();
    expect(find.text('一致するフレーズがありません'), findsOneWidget);

    // 検索をクリアして削除する（確認なし、SnackBar表示）
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('slip my mind'), findsOneWidget);

    await tester.runAsync(() async {
      // 新しい順で先頭に表示されているslip my mindの削除ボタンをタップする
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.text('slip my mind'), findsNothing);
    expect(find.text('break the ice'), findsOneWidget);
    expect(find.text('削除しました'), findsOneWidget);
  });
}
