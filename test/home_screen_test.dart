// HomeScreenのウィジェットテスト。
//
// Hive I/Oはtester.runAsync()で実の非同期ゾーンに切り替えて行う
// （test/review_screen_test.dartと同じパターン）。

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/review/data/srs_item_dto.dart';
import 'package:pj_walter/screens/home_screen.dart';
import 'package:pj_walter/services/history_service.dart';
import 'package:pj_walter/services/sentence_repository.dart';
import 'package:pj_walter/services/settings_service.dart';
import 'package:provider/provider.dart';

import 'test_support/hive_test_support.dart';
import 'test_support/test_app.dart';

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

// Providerはmain.dartと同じくMaterialAppの外側に置く。home:の内側に置くと
// push先の画面（デッキ選択など）からProviderが見えない。
Widget _buildApp(HistoryService historyService, SettingsService settings) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HistoryService>.value(value: historyService),
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      Provider<SentenceRepository>(create: (_) => SentenceRepository()),
    ],
    child: localizedApp(home: const HomeScreen()),
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
    expect(find.text('0'), findsOneWidget);
    expect(find.text('日連続'), findsOneWidget);
    expect(find.text('今週 0/7日'), findsOneWidget);
    expect(find.text('今日はまだ練習していません。3分だけ話してみましょう。'), findsOneWidget);
    expect(find.text('今日の復習はありません🎉'), findsOneWidget);
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
          language: 'en',
          level: 700,
          spoken: 'spoken text',
          timestamp: DateTime.now(),
          feedback: const CompositionFeedback(
            score: 40,
            isAcceptable: false,
            corrected: 'corrected text',
            explanation: '解説',
            comparison: '比較',
          ),
        ),
      );
      // 不正解直後のdueDateは翌日なので、今日の日付に書き換えて
      // 「今日の復習」対象にする。
      final item = historyService.allSrsItems.first;
      final today = DateTime.now();
      await Hive.box('srs_items').put(
        item.sentenceId,
        SrsItemDto.fromEntity(
          item.copyWith(dueDate: DateTime(today.year, today.month, today.day)),
        ).toJson(),
      );
    });

    await tester.pumpWidget(_buildApp(historyService, settings));
    await tester.pump();

    expect(find.text('今日の復習'), findsOneWidget);
    expect(find.textContaining('間隔反復キューに'), findsOneWidget);
    // 今日の学習量がストリークカードの本文に反映されている
    expect(find.textContaining('今日はドリル1問・独り言0回'), findsOneWidget);
    expect(find.text('日連続'), findsOneWidget);
  });

  testWidgets('トレーニングショートカットをタップすると各選択画面へ遷移する', (tester) async {
    // リデザインでカードが縦に増え、デフォルトのビューポートでは
    // トレーニンググリッドがスクロール範囲外になるため縦に広げる。
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
