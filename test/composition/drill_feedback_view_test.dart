// DrillFeedbackViewの「あなたの発話 → 修正版」統合差分カードのウィジェットテスト。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/screens/composition/drill_feedback_view.dart';

Sentence _sentence() => const Sentence(
  id: 's700-001',
  ja: '日本語の例文',
  en: 'English sentence',
  theme: 'daily',
  tips: 'tips',
  level: 700,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('発話と修正版に差分がある場合、両方のラベル・全文が表示される', (tester) async {
    const feedback = CompositionFeedback(
      score: 85,
      isAcceptable: true,
      corrected: 'I had toast this morning.',
      explanationJa: '解説',
      comparisonJa: '比較',
    );

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: 'I eat toast this morning',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('あなたの発話'), findsOneWidget);
    expect(find.text('修正版'), findsOneWidget);
    // 完全一致ではないので「修正なし」メッセージは出ない
    expect(find.textContaining('修正なし'), findsNothing);
    // 差分の有無に関わらず、単語をつなぎ合わせた元の全文がそれぞれ表示される
    expect(find.text('I eat toast this morning'), findsOneWidget);
    expect(find.text('I had toast this morning.'), findsOneWidget);
  });

  testWidgets('発話と修正版が完全一致する場合、修正なしメッセージが表示され修正版セクションは出ない', (tester) async {
    const feedback = CompositionFeedback(
      score: 100,
      isAcceptable: true,
      corrected: 'I had toast this morning.',
      explanationJa: '解説',
      comparisonJa: '',
    );

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: 'I had toast this morning.',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('あなたの発話'), findsOneWidget);
    expect(find.text('修正版'), findsNothing);
    expect(find.text('修正なし！そのままでOKです 🎉'), findsOneWidget);
    // 上段の発話は表示される
    expect(find.text('I had toast this morning.'), findsOneWidget);
  });

  testWidgets('大文字小文字だけの違いも完全一致（修正なし）として扱われる', (tester) async {
    const feedback = CompositionFeedback(
      score: 100,
      isAcceptable: true,
      corrected: 'I had toast.',
      explanationJa: '解説',
      comparisonJa: '',
    );

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: 'i had TOAST.',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('修正なし！そのままでOKです 🎉'), findsOneWidget);
  });

  testWidgets('時間切れ（corrected空）の場合はあなたの発話・修正版どちらも表示されない', (tester) async {
    const feedback = CompositionFeedback(
      score: 0,
      isAcceptable: false,
      corrected: '',
      explanationJa: '時間切れで回答できませんでした。模範解答を確認して復習しましょう。',
      comparisonJa: '',
    );

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: '',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('あなたの発話'), findsNothing);
    expect(find.text('修正版'), findsNothing);
    expect(find.textContaining('修正なし'), findsNothing);
    expect(find.text('English sentence'), findsOneWidget);
  });
}
