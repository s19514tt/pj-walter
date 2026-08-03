// HomeScreenのウィジェットテスト。
//
// Hive I/Oはtester.runAsync()で実の非同期ゾーンに切り替えて行う
// （test/review_screen_test.dartと同じパターン）。

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/screens/home_screen.dart';
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
  final settingsBox = await Hive.openBox('settings');
  final settings = SettingsService(settingsBox: settingsBox);
  await settings.init();
  return settings;
}

Widget _buildApp(HistoryService historyService, SettingsService settings) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<HistoryService>.value(value: historyService),
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        Provider<SentenceRepository>(create: (_) => SentenceRepository()),
      ],
      child: const HomeScreen(),
    ),
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

  testWidgets('APIキー未設定・データ無し: バナー表示、復習0件、ストリーク0', (tester) async {
    late HistoryService historyService;
    late SettingsService settings;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      settings = await _buildSettingsService();
    });

    await tester.pumpWidget(_buildApp(historyService, settings));
    await tester.pump();

    expect(find.text('APIキーを設定してください'), findsOneWidget);
    expect(find.text('0日連続'), findsOneWidget);
    expect(find.text('ドリル 0問'), findsOneWidget);
    expect(find.text('独り言 0回'), findsOneWidget);
    expect(find.text('今日の復習はありません🎉'), findsOneWidget);
    expect(find.text('復習を始める'), findsNothing);
    expect(find.text('口頭英作文'), findsOneWidget);
    expect(find.text('独り言英会話'), findsOneWidget);
  });

  testWidgets('APIキー設定済みならバナーは表示されない', (tester) async {
    late HistoryService historyService;
    late SettingsService settings;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      settings = await _buildSettingsService();
      await settings.setApiKey('test-api-key');
    });

    await tester.pumpWidget(_buildApp(historyService, settings));
    await tester.pump();

    expect(find.text('APIキーを設定してください'), findsNothing);
  });

  testWidgets('今日の復習がある場合は件数と開始ボタンが表示される', (tester) async {
    late HistoryService historyService;
    late SettingsService settings;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      settings = await _buildSettingsService();
      await historyService.saveDrillResult(
        DrillResult(
          id: 'd-1',
          sentenceId: 's700-001',
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

    expect(find.text('件の復習があります'), findsOneWidget);
    expect(find.text('復習を始める'), findsOneWidget);
    // 今日の学習量に今回のドリルが反映されている
    expect(find.text('ドリル 1問'), findsOneWidget);
    expect(find.text('独り言 0回'), findsOneWidget);
    expect(find.text('1日連続'), findsOneWidget);
  });

  testWidgets('トレーニングショートカットをタップすると各選択画面へ遷移する', (tester) async {
    late HistoryService historyService;
    late SettingsService settings;
    await tester.runAsync(() async {
      historyService = await _buildHistoryService();
      settings = await _buildSettingsService();
    });

    await tester.pumpWidget(_buildApp(historyService, settings));
    await tester.pump();

    await tester.tap(find.text('口頭英作文'));
    await tester.pumpAndSettle();
    expect(find.text('レベルを選ぶ'), findsOneWidget);
  });
}
