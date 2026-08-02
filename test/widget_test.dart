// スモークテスト: シェルが表示され、下部ナビゲーションに4つのタブがあることを確認する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj_walter/main.dart';

void main() {
  testWidgets('Shell shows 4 bottom navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

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
