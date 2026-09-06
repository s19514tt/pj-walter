// スモークテスト: 本番と同じ配線（configureDependencies）でシェルが表示され、
// 下部ナビゲーションに4つのタブがあることを確認する。

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pj_walter/core/di/injector.dart';
import 'package:pj_walter/main.dart';

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
    final getIt = GetIt.asNewInstance();
    await tester.runAsync(() async {
      final boxes = await AppBoxes.open();
      await configureDependencies(getIt, boxes: boxes);
    });

    await tester.pumpWidget(App(getIt: getIt));

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
