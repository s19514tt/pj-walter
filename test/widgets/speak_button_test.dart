// 読み上げボタンの3状態（待機・準備中・読み上げ中）の見た目のテスト。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/theme/app_theme.dart';
import 'package:pj_walter/widgets/speak_button.dart';

Widget _wrap(SpeakButtonState state, {VoidCallback? onPressed}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SpeakButton(state: state, onPressed: onPressed ?? () {}),
    ),
  ),
);

/// ボタンの地の色（待機中だけ白地、それ以外はオレンジの薄背景）
Color? _background(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(SpeakButton),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration as BoxDecoration).color;
}

void main() {
  testWidgets('待機中はスピーカーアイコンと「読み上げ」', (tester) async {
    await tester.pumpWidget(_wrap(SpeakButtonState.idle));

    expect(find.text('読み上げ'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_background(tester), AppColors.background);
  });

  testWidgets('生成中はスピナーと「生成中」', (tester) async {
    await tester.pumpWidget(_wrap(SpeakButtonState.preparing));

    expect(find.text('生成中'), findsOneWidget);
    // 押したのに無音の間もスピナーで反応が見えるようにする
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsNothing);
    expect(find.byIcon(Icons.stop), findsNothing);
    expect(_background(tester), AppColors.primarySurface);
  });

  testWidgets('読み上げ中は停止アイコンと「停止」', (tester) async {
    await tester.pumpWidget(_wrap(SpeakButtonState.speaking));

    expect(find.text('停止'), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_background(tester), AppColors.primarySurface);
  });

  testWidgets('どの状態でも押せる（生成中・読み上げ中は停止に使う）', (tester) async {
    for (final state in SpeakButtonState.values) {
      var taps = 0;
      await tester.pumpWidget(_wrap(state, onPressed: () => taps++));
      await tester.tap(find.byType(SpeakButton));
      expect(taps, 1, reason: '$state で押せていない');
    }
  });
}
