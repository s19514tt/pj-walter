// ScoreRingのウィジェットテスト。
//
// TweenAnimationBuilderによる0→scoreへの800msアニメーションを持つため、
// pumpAndSettle()でアニメーション完了後の表示を検証する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/widgets/score_ring.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('アニメーション完了後にスコアと/100が表示される', (tester) async {
    await tester.pumpWidget(wrap(const ScoreRing(score: 85)));
    await tester.pumpAndSettle();

    expect(find.text('85'), findsOneWidget);
    expect(find.text('/100'), findsOneWidget);
  });

  testWidgets('アニメーション開始直後は0からカウントアップする', (tester) async {
    await tester.pumpWidget(wrap(const ScoreRing(score: 60)));
    // アニメーション開始直後（1フレーム目）は0付近から始まる。
    await tester.pump();

    expect(find.text('0'), findsOneWidget);

    // 完了までアニメーションを進めると最終スコアが表示される。
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('サイズを指定できる', (tester) async {
    await tester.pumpWidget(wrap(const ScoreRing(score: 40, size: 120)));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ScoreRing)), const Size(120, 120));
  });
}
