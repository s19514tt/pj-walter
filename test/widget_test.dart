// スモークテスト: シェルが表示され、下部ナビゲーションに4つのタブがあることを確認する。

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/main.dart';
import 'package:pj_walter/services/history_service.dart';
import 'package:pj_walter/services/settings_service.dart';

import 'test_support/hive_test_support.dart';

void main() {
  setUp(() async {
    await initTestHive();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  testWidgets('Shell shows 4 bottom navigation tabs', (
    WidgetTester tester,
  ) async {
    // Hive.openBoxは実ファイルI/Oのため、testWidgets本体の制限されたゾーンでは
    // 完了しない。tester.runAsync()で実の非同期ゾーンに切り替えて実行する。
    final services = (await tester.runAsync(() async {
      final settingsBox = await Hive.openBox('settings');
      final settingsService = SettingsService(settingsBox: settingsBox);
      await settingsService.init();
      final historyService = HistoryService(
        drillResultsBox: await Hive.openBox('drill_results'),
        monologueResultsBox: await Hive.openBox('monologue_results'),
        srsItemsBox: await Hive.openBox('srs_items'),
        phrasesBox: await Hive.openBox('phrases'),
        dailyStatsBox: await Hive.openBox('daily_stats'),
      );
      return (settings: settingsService, history: historyService);
    }))!;
    final settingsService = services.settings;
    final historyService = services.history;

    await tester.pumpWidget(
      MyApp(settingsService: settingsService, historyService: historyService),
    );

    expect(find.text('ホーム'), findsOneWidget);
    expect(find.text('学習'), findsOneWidget);
    expect(find.text('復習'), findsOneWidget);
    expect(find.text('記録'), findsOneWidget);

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.items.length, 4);

    // ホームタブのAppBarタイトルが表示されていること
    expect(find.text('pj-walter'), findsOneWidget);

    // 学習タブに切り替えるとメニューが表示されること
    await tester.tap(find.text('学習'));
    await tester.pumpAndSettle();
    expect(find.text('口頭英作文'), findsOneWidget);
    expect(find.text('独り言英会話'), findsOneWidget);
  });
}
