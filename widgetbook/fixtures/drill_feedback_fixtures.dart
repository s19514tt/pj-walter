// 添削画面（DrillFeedbackView）の状態一覧。
//
// Widgetbook（widgetbook/main.dart）のユースケースと、ゴールデンテスト
// （test/goldens/drill_feedback_view_golden_test.dart）の両方がこのリストを使う。
// 「Widgetbook で見た状態」と「CIが崩れを検出する状態」を必ず同じにするため、
// 状態はここにだけ書く。widgetbook パッケージには依存しない（テストからも読むため）。

import 'package:flutter/material.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/content/domain/sentence.dart';
import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/screens/composition/drill_feedback_view.dart';
import 'package:pj_walter/features/speech/domain/tts_service.dart';

/// ストーリー1件（名前＋ウィジェットの組み立て）。
class Story {
  const Story({required this.name, required this.slug, required this.build});

  /// Widgetbook に出す名前（日本語可）
  final String name;

  /// ゴールデン画像のファイル名に使う識別子（英数字とハイフン）
  final String slug;

  final Widget Function() build;
}

const _zhSentence = Sentence(
  id: 'z3-001',
  ja: '水がほしい。',
  target: '我要水。',
  theme: 'daily',
  tips: '「要」は「ほしい・〜したい」。',
  level: 3,
  reading: 'Wǒ yào shuǐ',
);

const _zhErhuaSentence = Sentence(
  id: 'z3-015',
  ja: '早めに帰って休みなさい。',
  target: '你早点儿回家休息吧。',
  theme: 'daily',
  tips: '「早点儿」で「早めに」。',
  level: 3,
  reading: 'Nǐ zǎo diǎnr huíjiā xiūxi ba',
);

const _zhLongSentence = Sentence(
  id: 'z4-001',
  ja: 'もう一度説明していただけますか。',
  target: '请重新说明一下好吗？',
  theme: 'business',
  tips: '「重新」は「改めて」。',
  level: 4,
  reading: 'Qǐng chóngxīn shuōmíng yíxià hǎo ma',
);

const _enSentence = Sentence(
  id: 's700-001',
  ja: '朝食にトーストを食べました。',
  target: 'I had toast this morning.',
  theme: 'daily',
  tips: 'had で「食べた」。',
  level: 700,
);

/// 発話の語区切り（ピンインは持たない）。
List<WordUnit> _spokenWords(List<String> words) => [
  for (final word in words) WordUnit(text: word),
];

/// 修正版の語区切り（語とその語のピンインの組）。
List<WordUnit> _correctedWords(List<(String, String)> words) => [
  for (final (text, reading) in words) WordUnit(text: text, reading: reading),
];

/// 添削応答は発話ごとに語区切りが変わるため、発話の語を引数で受ける。
CompositionFeedback _zhPerfect(List<String> spokenWords) => CompositionFeedback(
  score: 100,
  isAcceptable: true,
  corrected: '我要水。',
  correctedWords: _correctedWords([
    ('我', 'wǒ'),
    ('要', 'yào'),
    ('水', 'shuǐ'),
    ('。', ''),
  ]),
  spokenWords: _spokenWords(spokenWords),
  correctedReading: 'wǒ yào shuǐ',
  explanation: '文法的な誤りはありません。',
  comparison: '模範解答と同じです。',
);

CompositionFeedback _zhFixed(List<String> spokenWords) => CompositionFeedback(
  score: 72,
  isAcceptable: true,
  corrected: '请重新说明一下好吗？',
  correctedWords: _correctedWords([
    ('请', 'qǐng'),
    ('重新', 'chóng xīn'),
    ('说明', 'shuō míng'),
    ('一下', 'yí xià'),
    ('好吗', 'hǎo ma'),
    ('？', ''),
  ]),
  spokenWords: _spokenWords(spokenWords),
  correctedReading: 'qǐng chóngxīn shuōmíng yíxià hǎo ma',
  explanation: '文末の「好吗」を付けると依頼の口調になります。',
  comparison: '模範解答と同じ形に直しました。',
);

const _enFeedback = CompositionFeedback(
  score: 85,
  isAcceptable: true,
  corrected: 'I had toast this morning.',
  explanation: '過去の話なので had を使います。',
  comparison: '模範解答と同じ意味です。',
);

DrillFeedbackView _view({
  required Sentence sentence,
  required LanguageProfile profile,
  required String? spoken,
  required String? spokenReading,
  required CompositionFeedback? feedback,
  bool skipped = false,
}) => DrillFeedbackView(
  sentence: sentence,
  profile: profile,
  spoken: spoken,
  spokenReading: spokenReading,
  feedback: feedback,
  skipped: skipped,
  onNext: () {},
  onRetry: () {},
  ttsService: _SilentTtsService(),
);

/// 見た目だけを確認するための、何も鳴らさない[TtsService]。
///
/// Widgetbook もゴールデンテストも音声は扱わないので、読み上げボタンが
/// 押されても何もしない実装を渡す（テスト用のフェイクは test/ にあるため
/// ここからは参照しない）。
class _SilentTtsService implements TtsService {
  @override
  Future<SpeakResult> speak(String text) async => (usage: TokenUsage.zero);

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

/// 添削画面の状態一覧。上から「よく見る順」。
final drillFeedbackStories = <Story>[
  Story(
    name: '中国語: 声調の気づき1件（睡 → 水）',
    slug: 'zh-tone-note-one',
    build: () => _view(
      sentence: _zhSentence,
      profile: LanguageProfile.chinese,
      spoken: '我要睡',
      spokenReading: 'wǒ yào shuì',
      feedback: _zhPerfect(const ['我', '要', '睡']),
    ),
  ),
  Story(
    name: '中国語: 声調の気づきなし（完全一致）',
    slug: 'zh-no-tone-note',
    build: () => _view(
      sentence: _zhSentence,
      profile: LanguageProfile.chinese,
      spoken: '我要水',
      spokenReading: 'wǒ yào shuǐ',
      feedback: _zhPerfect(const ['我', '要', '水']),
    ),
  ),
  Story(
    name: '中国語: 語数が違う＋声調の気づき（一 の1声）',
    slug: 'zh-tone-note-with-diff',
    build: () => _view(
      sentence: _zhLongSentence,
      profile: LanguageProfile.chinese,
      spoken: '请重新说明一下',
      spokenReading: 'qǐng chóng xīn shuō míng yī xià',
      feedback: _zhFixed(const ['请', '重新', '说明', '一下']),
    ),
  ),
  Story(
    name: '中国語: 声調の気づき複数（2件）',
    slug: 'zh-tone-note-many',
    build: () => _view(
      sentence: _zhLongSentence,
      profile: LanguageProfile.chinese,
      spoken: '请重新说明一下好吗',
      spokenReading: 'qíng chóng xīn shuō míng yī xià hǎo ma',
      feedback: _zhFixed(const ['请', '重新', '说明', '一下', '好吗']),
    ),
  ),
  Story(
    name: '中国語: 儿化（点儿）の声調の気づき',
    slug: 'zh-erhua',
    build: () => _view(
      sentence: _zhErhuaSentence,
      profile: LanguageProfile.chinese,
      spoken: '你早点儿回家休息吧',
      spokenReading: 'nǐ zǎo diànr huíjiā xiūxi ba',
      feedback: CompositionFeedback(
        score: 100,
        isAcceptable: true,
        corrected: '你早点儿回家休息吧。',
        correctedWords: _correctedWords(const [
          ('你', 'nǐ'),
          ('早点儿', 'zǎo diǎnr'),
          ('回家', 'huí jiā'),
          ('休息', 'xiū xi'),
          ('吧', 'ba'),
          ('。', ''),
        ]),
        spokenWords: _spokenWords(const ['你', '早点儿', '回家', '休息', '吧']),
        correctedReading: 'nǐ zǎo diǎnr huíjiā xiūxi ba',
        explanation: '問題ありません。',
        comparison: '',
      ),
    ),
  ),
  Story(
    name: '中国語: 漢字数と音節数が合わない（ルビなし）',
    slug: 'zh-ruby-misaligned',
    build: () => _view(
      sentence: _zhSentence,
      profile: LanguageProfile.chinese,
      spoken: '我要水',
      spokenReading: 'wǒ yào',
      feedback: _zhPerfect(const ['我', '要', '水']),
    ),
  ),
  Story(
    name: '中国語: 修正版のピンインが1語だけ合わない（その語だけルビなし）',
    slug: 'zh-word-reading-partial',
    build: () => _view(
      sentence: _zhLongSentence,
      profile: LanguageProfile.chinese,
      spoken: '请重新说明一下',
      spokenReading: 'qǐng chóng xīn shuō míng yī xià',
      feedback: CompositionFeedback(
        score: 72,
        isAcceptable: true,
        corrected: '请重新说明一下好吗？',
        // 「说明」だけ音節数が合わない。ほかの語のルビは残る
        correctedWords: _correctedWords(const [
          ('请', 'qǐng'),
          ('重新', 'chóng xīn'),
          ('说明', 'shuō míng bái'),
          ('一下', 'yí xià'),
          ('好吗', 'hǎo ma'),
          ('？', ''),
        ]),
        spokenWords: _spokenWords(const ['请', '重新', '说明', '一下']),
        explanation: '文末の「好吗」を付けると依頼の口調になります。',
        comparison: '模範解答と同じ形に直しました。',
      ),
    ),
  ),
  Story(
    name: '中国語: 語区切りが無い旧データ＋修正版のピンインが記号なし',
    slug: 'zh-corrected-reading-toneless',
    build: () => _view(
      sentence: _zhSentence,
      profile: LanguageProfile.chinese,
      spoken: '我要水',
      spokenReading: 'wǒ yào shuǐ',
      feedback: const CompositionFeedback(
        score: 100,
        isAcceptable: true,
        corrected: '我要水。',
        correctedReading: 'wo yao shui',
        explanation: '問題ありません。',
        comparison: '',
      ),
    ),
  ),
  Story(
    name: '中国語: stage 1（文字起こし済み・採点待ち）',
    slug: 'zh-stage1',
    build: () => _view(
      sentence: _zhSentence,
      profile: LanguageProfile.chinese,
      spoken: '我要睡',
      spokenReading: 'wǒ yào shuì',
      feedback: null,
    ),
  ),
  Story(
    name: '中国語: stage 0（全カードスケルトン）',
    slug: 'zh-stage0',
    build: () => _view(
      sentence: _zhSentence,
      profile: LanguageProfile.chinese,
      spoken: null,
      spokenReading: null,
      feedback: null,
    ),
  ),
  Story(
    name: '中国語: 時間切れ',
    slug: 'zh-timeout',
    build: () => _view(
      sentence: _zhSentence,
      profile: LanguageProfile.chinese,
      spoken: '',
      spokenReading: null,
      feedback: const CompositionFeedback(
        score: 0,
        isAcceptable: false,
        corrected: '',
        explanation: '時間切れで回答できませんでした。模範解答を確認して復習しましょう。',
        comparison: '',
      ),
    ),
  ),
  Story(
    name: '英語: わからないので飛ばした（未採点）',
    slug: 'en-skipped',
    build: () => _view(
      sentence: _enSentence,
      profile: LanguageProfile.english,
      spoken: '',
      spokenReading: null,
      skipped: true,
      feedback: const CompositionFeedback(
        score: 0,
        isAcceptable: false,
        corrected: '',
        explanation: 'わからないので飛ばした問題です。模範解答を声に出して真似るところから始めましょう。',
        comparison: '',
      ),
    ),
  ),
  Story(
    name: '英語: 差分あり',
    slug: 'en-diff',
    build: () => _view(
      sentence: _enSentence,
      profile: LanguageProfile.english,
      spoken: 'I eat toast this morning',
      spokenReading: null,
      feedback: _enFeedback,
    ),
  ),
  Story(
    name: '英語: 修正なし',
    slug: 'en-no-diff',
    build: () => _view(
      sentence: _enSentence,
      profile: LanguageProfile.english,
      spoken: 'I had toast this morning.',
      spokenReading: null,
      feedback: _enFeedback,
    ),
  ),
];
