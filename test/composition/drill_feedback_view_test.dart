// DrillFeedbackViewの「あなたの発話 → 修正版」統合差分カードのウィジェットテスト。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/learning_language.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/screens/composition/drill_feedback_view.dart';

Sentence _sentence() => const Sentence(
  id: 's700-001',
  ja: '日本語の例文',
  target: 'English sentence',
  theme: 'daily',
  tips: 'tips',
  level: 700,
);

Sentence _zhSentence({String? reading = 'Wǒ yào shuǐ'}) => Sentence(
  id: 'z3-001',
  ja: '水がほしい。',
  target: '我要水。',
  theme: 'daily',
  tips: 'tips',
  level: 3,
  reading: reading,
);

const _zhFeedback = CompositionFeedback(
  score: 95,
  isAcceptable: true,
  corrected: '我要水。',
  explanationJa: '解説',
  comparisonJa: '',
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// 「気づいた点」カードのガード検証用。[profile]・[reading]・[spokenReading]・
/// [feedback]だけを変えて DrillFeedbackView を組み立てる。
Widget _toneView({
  LanguageProfile profile = LanguageProfile.chinese,
  String? reading = 'Wǒ yào shuǐ',
  String? spokenReading = 'wǒ yào shuì',
  CompositionFeedback? feedback = _zhFeedback,
}) => _wrap(
  DrillFeedbackView(
    sentence: _zhSentence(reading: reading),
    profile: profile,
    spoken: '我要睡',
    spokenReading: spokenReading,
    feedback: feedback,
    onNext: () {},
    onRetry: () {},
  ),
);

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

  group('気づいた点（声調）カード', () {
    testWidgets('中国語で綴りが一致し声調だけ違う音節があるときだけカードが出る', (tester) async {
      await tester.pumpWidget(_toneView());
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsOneWidget);
      expect(find.text('3声 → 4声'), findsOneWidget);
      expect(find.text('水'), findsOneWidget);
      // 期待と実測の両方のピンインが1つのテキストに並ぶ
      expect(find.textContaining('shuǐ'), findsOneWidget);
      expect(find.textContaining('shuì'), findsOneWidget);
      expect(find.textContaining('参考値'), findsOneWidget);
      // ガード3: 「声調をチェックした」「声調OK」といった断定は出さない
      expect(find.textContaining('声調チェック'), findsNothing);
      expect(find.textContaining('声調OK'), findsNothing);
      expect(find.textContaining('問題なし'), findsNothing);
    });

    testWidgets('英語モードではカードが出ない', (tester) async {
      await tester.pumpWidget(_toneView(profile: LanguageProfile.english));
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsNothing);
      expect(find.textContaining('声'), findsNothing);
    });

    testWidgets('ガード1: 音節列が模範解答と一致しないときはカードが出ない', (tester) async {
      // 1音節多い（聞き取りの崩れ・言い回しの違い）
      await tester.pumpWidget(_toneView(spokenReading: 'wǒ yào shuì le'));
      await tester.pumpAndSettle();
      expect(find.text('気づいた点'), findsNothing);

      // 同じ音節数でも綴りがずれている。別の音節に声調差があっても出さない
      await tester.pumpWidget(_toneView(spokenReading: 'wó yào shǔ'));
      await tester.pumpAndSettle();
      expect(find.text('気づいた点'), findsNothing);
    });

    testWidgets('ガード3: 指摘0件のときはカードごと出ない（「問題なし」も出さない）', (tester) async {
      await tester.pumpWidget(_toneView(spokenReading: 'wǒ yào shuǐ'));
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsNothing);
      expect(find.textContaining('問題なし'), findsNothing);
      expect(find.textContaining('参考値'), findsNothing);
    });

    testWidgets('ガード2: 軽声がらみの差だけならカードが出ない', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DrillFeedbackView(
            sentence: const Sentence(
              id: 'z3-002',
              ja: '私はあなたが好きです。',
              target: '我喜欢你。',
              theme: 'daily',
              tips: '',
              level: 3,
              reading: 'Wǒ xǐhuān nǐ',
            ),
            profile: LanguageProfile.chinese,
            spoken: '我喜欢你',
            spokenReading: 'wǒ xǐ huan nǐ',
            feedback: _zhFeedback,
            onNext: () {},
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsNothing);
    });

    testWidgets('sentence.reading が null のときはカードが出ない', (tester) async {
      await tester.pumpWidget(_toneView(reading: null));
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsNothing);
    });

    testWidgets('文字起こしにピンインが無い（null）ときはカードが出ない', (tester) async {
      await tester.pumpWidget(_toneView(spokenReading: null));
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsNothing);
    });

    testWidgets('採点完了前（stage 1）はカードを出さない', (tester) async {
      await tester.pumpWidget(_toneView(feedback: null));
      await tester.pump();

      expect(find.text('気づいた点'), findsNothing);
    });
  });
}
