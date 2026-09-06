// DrillFeedbackViewの「あなたの発話 → 修正版」統合差分カード・問題文カード・
// 読み上げボタンのウィジェットテスト。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/models/token_usage.dart';
import 'package:pj_walter/screens/composition/drill_feedback_view.dart';
import 'package:pj_walter/services/tts_service.dart';
import 'package:pj_walter/core/theme/app_theme.dart';
import 'package:pj_walter/core/widgets/speak_button.dart';

import '../test_support/fake_tts_service.dart';
import '../test_support/test_app.dart';

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
  correctedReading: 'wǒ yào shuǐ',
  explanationJa: '解説',
  comparisonJa: '',
);

Widget _wrap(Widget child) => localizedApp(home: Scaffold(body: child));

/// ルビ付きカードは縦に長く、既定のテスト画面では下のカードがListViewの
/// 描画範囲外（未構築）になるため、画面を縦に広げる。
Future<void> _tall(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(500, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

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
    ttsService: FakeTtsService(),
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

  group('気づいた点（声調）カード', () {
    testWidgets('中国語で綴りが一致し声調だけ違う音節があるときだけカードが出る', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView());
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsOneWidget);
      expect(find.text('3声 → 4声'), findsOneWidget);
      // 気づいた点の行: 期待と実測の両方のピンインが1つのテキストに並ぶ
      expect(find.textContaining('shuǐ  →  shuì'), findsOneWidget);
      expect(find.textContaining('参考値'), findsWidgets);
      // ガード3: 「声調をチェックした」「声調OK」といった断定は出さない
      expect(find.textContaining('声調チェック'), findsNothing);
      expect(find.textContaining('声調OK'), findsNothing);
      expect(find.textContaining('問題なし'), findsNothing);
      expect(find.textContaining('声調は問題ありません'), findsNothing);
    });

    testWidgets('中国語では漢字ごとにピンインのルビが付き、声調の違う文字は赤ルビ＋下に期待声調', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView());
      await tester.pumpAndSettle();

      // あなたの発話「我要睡」: 聞こえた読み wǒ yào shuì がルビになる
      expect(find.text('wǒ'), findsWidgets);
      expect(find.text('yào'), findsWidgets);
      // 睡 のセル: 上に聞こえた shuì（赤）、下に期待の shuǐ（緑）
      expect(find.text('shuì'), findsOneWidget);
      final heard = tester.widget<Text>(find.text('shuì'));
      expect(heard.style?.color, AppColors.scoreLow);
      // 修正版（我要水）・模範解答（我要水）・期待声調の3箇所に shuǐ
      expect(find.text('shuǐ'), findsNWidgets(3));
      expect(find.text('赤字のルビは上＝実際の声調（参考値）／下＝期待された声調'), findsOneWidget);
      // ルビは1文字ずつ漢字と縦に並ぶ（1文字のTextとして描画される）
      expect(find.text('睡'), findsOneWidget);
      expect(find.text('水'), findsNWidgets(3));
      // 下段（期待声調）が付く「睡」も、他の漢字と縦位置が揃う（横一列）
      final spokenCard = find.ancestor(
        of: find.text('睡'),
        matching: find.byType(Wrap),
      );
      final woTop = tester
          .getTopLeft(find.descendant(of: spokenCard, matching: find.text('我')))
          .dy;
      final shuiTop = tester.getTopLeft(find.text('睡')).dy;
      expect(shuiTop, woTop);
    });

    testWidgets('声調の指摘が無いときもルビは付くが、赤ルビの注記は出ない', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView(spokenReading: 'wǒ yào shuǐ'));
      await tester.pumpAndSettle();

      expect(find.text('wǒ'), findsWidgets);
      expect(find.text('shuǐ'), findsWidgets);
      expect(find.textContaining('赤字のルビ'), findsNothing);
      expect(find.text('気づいた点'), findsNothing);
    });

    testWidgets('漢字数と音節数が合わないときはルビを付けず漢字だけ並べる', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView(spokenReading: 'wǒ yào'));
      await tester.pumpAndSettle();

      // あなたの発話にはルビ無し（wǒ は修正版・模範解答のルビにだけ現れる）
      expect(find.text('wǒ'), findsNWidgets(2));
      expect(find.text('shuì'), findsNothing);
      expect(find.text('睡'), findsOneWidget);
      expect(find.text('気づいた点'), findsNothing);
    });

    testWidgets('採点前（stage 1）でも聞き取った読みのルビと赤ルビが出る', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView(feedback: null));
      await tester.pump();

      expect(find.text('shuì'), findsOneWidget);
      expect(find.text('shuǐ'), findsOneWidget); // 期待声調（下段）
      expect(find.text('気づいた点'), findsNothing); // カードは採点完了後
    });

    testWidgets('声調の気づきがあるとスコアカードの一文が声調へ誘導する', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView());
      await tester.pumpAndSettle();
      expect(find.text('声調が違って聞こえた音節が1つあります。赤いルビを確認しましょう。'), findsOneWidget);

      await tester.pumpWidget(_toneView(spokenReading: 'wǒ yào shuǐ'));
      await tester.pumpAndSettle();
      expect(find.text('よくできました。この調子で次へ進みましょう。'), findsOneWidget);
      expect(find.textContaining('声調は問題ありません'), findsNothing);
    });

    testWidgets('模範解答にはピンインのルビが付く（英語モードでは付かない）', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView(spokenReading: null));
      await tester.pumpAndSettle();
      // 模範解答 我要水 のルビ（修正版にも wǒ yào shuǐ）
      expect(find.text('shuǐ'), findsNWidgets(2));

      await tester.pumpWidget(_toneView(profile: LanguageProfile.english));
      await tester.pumpAndSettle();
      expect(find.text('shuǐ'), findsNothing);
      // 英語モードでは従来どおり文全体が1つのTextで描画される
      expect(find.text('我要水。'), findsOneWidget);
    });

    testWidgets('英語モードではカードが出ない', (tester) async {
      await tester.pumpWidget(_toneView(profile: LanguageProfile.english));
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsNothing);
      expect(find.textContaining('声調'), findsNothing);
    });

    testWidgets('ガード1: 綴りが崩れた音節には声調の指摘を乗せない', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView(spokenReading: 'wǒ yào shǔ'));
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsNothing);
      expect(find.textContaining('赤字のルビ'), findsNothing);
    });

    testWidgets('ガード1: 語数が違っても綴りが一致した音節は比較して出す', (tester) async {
      await _tall(tester);
      await tester.pumpWidget(_toneView(spokenReading: 'wǒ yào shuì le'));
      await tester.pumpAndSettle();

      expect(find.text('気づいた点'), findsOneWidget);
      expect(find.text('3声 → 4声'), findsOneWidget);
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
            ttsService: FakeTtsService(),
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

  group('差分のハイライトの単位', () {
    // 模範解答（这里）と修正版（建筑物前面）で漢字が重ならないようにして、
    // 修正版のセルだけを find.text で一意に取れるようにしている。
    Sentence sentence() => const Sentence(
      id: 'z3-020',
      ja: '建物の前で写真を撮ろう。',
      target: '我在这里拍照。',
      theme: 'daily',
      tips: 'tips',
      level: 3,
      reading: 'Wǒ zài zhèli pāizhào',
    );

    CompositionFeedback feedback({
      List<WordUnit>? correctedWords,
      List<WordUnit>? spokenWords,
    }) => CompositionFeedback(
      score: 70,
      isAcceptable: true,
      corrected: '我在建筑物前面拍照。',
      correctedWords: correctedWords,
      spokenWords: spokenWords,
      explanationJa: '解説',
      comparisonJa: '',
    );

    List<WordUnit> correctedWords({String jianzhuwu = 'jiàn zhù wù'}) => [
      const WordUnit(text: '我', reading: 'wǒ'),
      const WordUnit(text: '在', reading: 'zài'),
      WordUnit(text: '建筑物', reading: jianzhuwu),
      const WordUnit(text: '前面', reading: 'qián miàn'),
      const WordUnit(text: '拍照', reading: 'pāi zhào'),
      const WordUnit(text: '。', reading: ''),
    ];

    Future<void> pumpView(WidgetTester tester, CompositionFeedback f) async {
      await _tall(tester);
      await tester.pumpWidget(
        _wrap(
          DrillFeedbackView(
            sentence: sentence(),
            profile: LanguageProfile.chinese,
            spoken: '我拍照',
            spokenReading: null,
            feedback: f,
            onNext: () {},
            onRetry: () {},
            ttsService: FakeTtsService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// 文字[char]のセルの背景（角丸と右の隙間で箱の繋がりが分かる）。
    Container cell(WidgetTester tester, String char) =>
        tester.widget<Container>(
          find
              .ancestor(of: find.text(char), matching: find.byType(Container))
              .first,
        );

    BorderRadius radiusOf(WidgetTester tester, String char) =>
        ((cell(tester, char).decoration! as BoxDecoration).borderRadius!)
            as BorderRadius;

    double gapOf(WidgetTester tester, String char) =>
        (cell(tester, char).margin! as EdgeInsets).right;

    testWidgets('語区切りがあると差分のハイライトは単語ごとに1つの箱になる', (tester) async {
      await pumpView(
        tester,
        feedback(
          correctedWords: correctedWords(),
          spokenWords: const [
            WordUnit(text: '我'),
            WordUnit(text: '拍照'),
          ],
        ),
      );

      // 建筑物: 左端だけ左が丸く、中は角無し、右端だけ右が丸い＝1つの箱
      expect(
        radiusOf(tester, '建'),
        const BorderRadius.horizontal(left: Radius.circular(4)),
      );
      expect(radiusOf(tester, '筑'), BorderRadius.zero);
      expect(
        radiusOf(tester, '物'),
        const BorderRadius.horizontal(right: Radius.circular(4)),
      );
      // 箱の中は隙間なしで繋がり、語の切れ目では隙間が空く
      expect(gapOf(tester, '建'), 0);
      expect(gapOf(tester, '物'), 2);
      // 次の語「前面」は別の箱として始まる
      expect(
        radiusOf(tester, '前'),
        const BorderRadius.horizontal(left: Radius.circular(4)),
      );
    });

    testWidgets('語区切りが無い（旧データ）ときは連続する差分がまとめて1つの箱になる', (tester) async {
      await pumpView(tester, feedback());

      // 在建筑物前面 がひと続きの箱（左端＝在、右端＝面）
      expect(
        radiusOf(tester, '在'),
        const BorderRadius.horizontal(left: Radius.circular(4)),
      );
      expect(radiusOf(tester, '建'), BorderRadius.zero);
      expect(
        radiusOf(tester, '面'),
        const BorderRadius.horizontal(right: Radius.circular(4)),
      );
    });

    testWidgets('修正版のルビは語ごとに割り当てられ、合わない語だけ落ちる', (tester) async {
      await pumpView(tester, feedback(correctedWords: correctedWords()));
      expect(find.text('jiàn'), findsOneWidget);
      expect(find.text('qián'), findsOneWidget);

      // 「建筑物」のピンインだけ音節数が合わない場合
      await pumpView(
        tester,
        feedback(correctedWords: correctedWords(jianzhuwu: 'jiàn zhù')),
      );
      expect(find.text('jiàn'), findsNothing);
      expect(find.text('zhù'), findsNothing);
      // ほかの語のルビは残る（文全体のルビが消えない）
      expect(find.text('qián'), findsOneWidget);
      expect(find.text('miàn'), findsOneWidget);
    });
  });
}
