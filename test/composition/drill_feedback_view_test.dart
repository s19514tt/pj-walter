// DrillFeedbackViewの「あなたの発話 → 修正版」統合差分カード・問題文カード・
// 読み上げボタンのウィジェットテスト。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/models/token_usage.dart';
import 'package:pj_walter/screens/composition/drill_feedback_view.dart';
import 'package:pj_walter/services/tts_service.dart';
import 'package:pj_walter/widgets/speak_button.dart';

import '../test_support/fake_tts_service.dart';

Sentence _sentence() => const Sentence(
  id: 's700-001',
  ja: '日本語の例文',
  target: 'English sentence',
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
          ttsService: FakeTtsService(),
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
          ttsService: FakeTtsService(),
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
          ttsService: FakeTtsService(),
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
          ttsService: FakeTtsService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('あなたの発話'), findsNothing);
    expect(find.text('修正版'), findsNothing);
    expect(find.textContaining('修正なし'), findsNothing);
    expect(find.text('English sentence'), findsOneWidget);
  });

  testWidgets('採点前でも問題文カードに出題された日本語文が表示される', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: null,
          feedback: null,
          onNext: () {},
          onRetry: () {},
          ttsService: FakeTtsService(),
        ),
      ),
    );
    // スケルトンのシマーは無限アニメーションのためpumpAndSettleは使えない
    await tester.pump();

    expect(find.text('問題文'), findsOneWidget);
    expect(find.text('日本語の例文'), findsOneWidget);
  });

  testWidgets('修正版・模範解答の読み上げボタンでそれぞれの文が読み上げられる', (tester) async {
    const feedback = CompositionFeedback(
      score: 85,
      isAcceptable: true,
      corrected: 'I had toast this morning.',
      explanationJa: '解説',
      comparisonJa: '比較',
    );
    final tts = FakeTtsService();

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: 'I eat toast this morning',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
          ttsService: tts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 修正版・模範解答の2箇所に読み上げボタンが出る
    expect(find.byType(SpeakButton), findsNWidgets(2));

    await tester.tap(find.byType(SpeakButton).first);
    await tester.pumpAndSettle();
    // 模範解答カードは初期表示では画面外にあるのでスクロールしてから押す
    await tester.ensureVisible(find.byType(SpeakButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SpeakButton).last);
    await tester.pumpAndSettle();

    expect(tts.spoken, ['I had toast this morning.', 'English sentence']);
  });

  testWidgets('読み上げ中はボタンが停止表示になり、押すと読み上げが止まる', (tester) async {
    const feedback = CompositionFeedback(
      score: 85,
      isAcceptable: true,
      corrected: 'I had toast this morning.',
      explanationJa: '解説',
      comparisonJa: '比較',
    );
    final tts = FakeTtsService()..pending = true;

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: 'I eat toast this morning',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
          ttsService: tts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SpeakButton).first);
    await tester.pumpAndSettle();
    expect(find.text('停止'), findsOneWidget);

    await tester.tap(find.text('停止'));
    await tester.pumpAndSettle();
    expect(tts.stopCount, 1);
    expect(find.text('停止'), findsNothing);
    expect(find.text('読み上げ'), findsNWidgets(2));
  });

  testWidgets('読み上げに失敗した場合はエラー文言をスナックバーで知らせる', (tester) async {
    const feedback = CompositionFeedback(
      score: 85,
      isAcceptable: true,
      corrected: 'I had toast this morning.',
      explanationJa: '解説',
      comparisonJa: '比較',
    );
    final tts = FakeTtsService()..error = TtsException('読み上げできませんでした。');

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: 'I eat toast this morning',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
          ttsService: tts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SpeakButton).first);
    await tester.pumpAndSettle();

    expect(find.text('読み上げできませんでした。'), findsOneWidget);
    expect(find.text('停止'), findsNothing);
  });

  testWidgets('時間切れ（corrected空）でも問題文と模範解答の読み上げは使える', (tester) async {
    const feedback = CompositionFeedback(
      score: 0,
      isAcceptable: false,
      corrected: '',
      explanationJa: '時間切れ',
      comparisonJa: '',
    );
    final tts = FakeTtsService();

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: '',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
          ttsService: tts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('日本語の例文'), findsOneWidget);
    expect(find.byType(SpeakButton), findsOneWidget);

    await tester.tap(find.byType(SpeakButton));
    await tester.pumpAndSettle();
    expect(tts.spoken, ['English sentence']);
  });

  testWidgets('読み上げで消費したトークンが親に通知される', (tester) async {
    const feedback = CompositionFeedback(
      score: 85,
      isAcceptable: true,
      corrected: 'I had toast this morning.',
      explanationJa: '解説',
      comparisonJa: '比較',
    );
    // 1回目はGeminiを呼ぶので使用量が返る
    final tts = FakeTtsService()
      ..usage = const TokenUsage(promptTokens: 20, candidatesTokens: 900);
    final reported = <TokenUsage>[];

    await tester.pumpWidget(
      _wrap(
        DrillFeedbackView(
          sentence: _sentence(),
          spoken: 'I eat toast this morning',
          feedback: feedback,
          onNext: () {},
          onRetry: () {},
          ttsService: tts,
          onSpeechUsage: reported.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SpeakButton).first);
    await tester.pumpAndSettle();
    expect(reported, [
      const TokenUsage(promptTokens: 20, candidatesTokens: 900),
    ]);

    // キャッシュ再生（使用量ゼロ）は通知しない
    tts.usage = TokenUsage.zero;
    await tester.tap(find.byType(SpeakButton).first);
    await tester.pumpAndSettle();
    expect(reported.length, 1);
  });
}
