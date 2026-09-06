// CountdownRingのウィジェットテスト。
//
// 聞き取り開始時に一度だけ弾む演出（デザインの`ringPop`: 1.0→1.11→1.08、
// 620ms）と、pre/recの状態表示を検証する。拡大はScaleTransitionが持つので、
// レンダリングされたTransformの倍率で確認する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/widgets/countdown_ring.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  /// リング全体に掛かっている拡大率（ScaleTransitionのTransform）
  double scaleOf(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.ancestor(
        of: find.byType(SizedBox).first,
        matching: find.byType(Transform),
      ),
    );
    return transform.transform.getMaxScaleOnAxis();
  }

  testWidgets('pre（聞き取り前）は等倍で、待機ラベルを表示する', (tester) async {
    await tester.pumpWidget(
      wrap(
        const CountdownRing(
          progress: 1,
          label: '30',
          recording: false,
          idleLabel: '聞き取り前',
          dimmed: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('30'), findsOneWidget);
    expect(find.text('聞き取り前'), findsOneWidget);
    expect(scaleOf(tester), moreOrLessEquals(1, epsilon: 0.001));
  });

  testWidgets('聞き取りを開始すると一度大きく弾んでから1.08倍で止まる', (tester) async {
    Widget build({required bool recording}) => wrap(
      CountdownRing(
        progress: 0.6,
        label: '18',
        recording: recording,
        idleLabel: '聞き取り前',
        dimmed: !recording,
      ),
    );

    await tester.pumpWidget(build(recording: false));
    await tester.pumpAndSettle();
    expect(scaleOf(tester), moreOrLessEquals(1, epsilon: 0.001));

    // rec に入ると 620ms かけて 1.11 まで膨らみ、1.08 に落ち着く
    await tester.pumpWidget(build(recording: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 236)); // 38%地点＝ピーク
    expect(scaleOf(tester), moreOrLessEquals(1.11, epsilon: 0.005));

    await tester.pumpAndSettle();
    expect(scaleOf(tester), moreOrLessEquals(1.08, epsilon: 0.001));
    expect(find.text('聞き取り中'), findsOneWidget);

    // pre に戻ると等倍に戻る
    await tester.pumpWidget(build(recording: false));
    await tester.pumpAndSettle();
    expect(scaleOf(tester), moreOrLessEquals(1, epsilon: 0.001));
  });

  testWidgets('最初から聞き取り中なら弾み終わった1.08倍で表示する', (tester) async {
    await tester.pumpWidget(
      wrap(
        const CountdownRing(
          progress: 0.6,
          label: '18',
          recording: true,
          idleLabel: '聞き取り前',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(scaleOf(tester), moreOrLessEquals(1.08, epsilon: 0.001));
  });
}
