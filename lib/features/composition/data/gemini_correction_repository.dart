import '../../../core/data/gemini_client.dart';
import '../../../core/domain/app_failure.dart';
import '../../../core/language/learning_language.dart';
import '../domain/correction_repository.dart';
import 'drill_result_dto.dart';

/// [CorrectionRepository] の Gemini 直叩き実装。
///
/// プロンプトと JSON スキーマ（DESIGN.md「口頭英作文の添削」）はここに置く。
/// **次フェーズで丸ごと Rust 側へ移植し、この実装はサーバ呼び出しに置き換わる**
/// ので、プロンプトは作り込まない（契約の形だけを最終形にしてある）。
class GeminiCorrectionRepository implements CorrectionRepository {
  const GeminiCorrectionRepository(this._client);

  final GeminiClient _client;

  @override
  Future<CorrectionResult> correct(CorrectionRequest request) async {
    final profile = LanguageProfile.ofCode(request.learningLanguage);
    final withReading = profile.hasReading;
    final (:json, :usage) = await _client.generateJson(
      prompt: buildPrompt(request, profile: profile),
      schema: withReading ? schemaWithReading : schema,
    );
    try {
      return CorrectionResult(
        feedback: CompositionFeedbackDto.fromJson(json).toEntity(),
        usage: usage,
      );
    } catch (_) {
      throw const AppFailure(FailureKind.invalidResponse);
    }
  }

  /// 添削プロンプト。解説の言語は [CorrectionRequest.uiLocale] から決める。
  static String buildPrompt(
    CorrectionRequest request, {
    required LanguageProfile profile,
  }) {
    final language = profile.support.englishName;
    final explanationLanguage = explanationLanguageName(request.uiLocale);
    return '''
$explanationLanguage話者向けの$languageスピーキング講師として、学習者が$explanationLanguageの文を見て$languageで発話した内容を添削してください。
解説は$explanationLanguageで、学習者本人に語りかける形で書き、学習者を指すときは「あなた」と呼んでください。「生徒」という呼び方は使わないでください。
発話内容は音声認識によって文字起こしされたものなので、大文字・小文字の違いや句読点の有無は減点しないでください。
意味が通り文法的に正しい$languageの文であれば、模範解答と表現が異なっていても許容し、正当に評価してください。
発音・声調は評価対象に含めません（音声認識を経ているため判定できません）。文法・語彙・語順のみを見てください。

原文（$explanationLanguage）: ${request.source}
模範解答: ${request.modelAnswer}
学習者の発話（文字起こし）: ${request.spoken}

以下のJSONスキーマに従って評価結果を出力してください。

- score: 下記のルーブリックに従って0〜100で採点する
  - 95-100: ほぼ完璧で自然
  - 85-94: 正確だがわずかに不自然
  - 70-84: 軽微な文法・語彙ミスはあるが問題なく伝わる（70点が合格ライン）
  - 50-69: 意味は伝わるが明確な文法ミスがある
  - 30-49: 部分的にしか伝わらない
  - 0-29: ほぼ伝わらない
- is_acceptable: scoreが70以上なら合格(true)
- corrected: 学習者の発話を最小限の編集で正しくした$languageの文にすること。模範解答を丸写しするのではなく、
  学習者が選んだ語彙・構文をできる限りそのまま活かして修正する。学習者が模範解答と違う構文を選んでいても、
  その構文のまま正しい形に直すこと（模範解答の構文に置き換えるのはNG。学習者の言い回しを壊すため）。
- explanation: 誤りの解説を「誤り→なぜ誤りか→どう覚えるか」の順で簡潔に（$explanationLanguage、2〜3文）
- comparison: 模範解答との違いや、どちらでも良い点の解説（$explanationLanguage）
${profile.hasReading ? correctedWordsInstruction : ''}''';
  }

  /// [uiLocale] に対応する解説言語の呼び名（プロンプト内で使う）。
  ///
  /// 現在の UI 言語は日本語のみ。多言語対応（最終フェーズ）ではここが増えるが、
  /// その頃にはプロンプトはサーバ側にある。
  static String explanationLanguageName(String uiLocale) =>
      switch (uiLocale.split(RegExp('[-_]')).first) {
        'ja' => '日本語',
        'en' => 'English',
        'zh' => '中文',
        _ => uiLocale,
      };

  static const schema = {
    'type': 'OBJECT',
    'properties': {
      'score': {'type': 'INTEGER'},
      'is_acceptable': {'type': 'BOOLEAN'},
      'corrected': {'type': 'STRING'},
      'explanation': {'type': 'STRING'},
      'comparison': {'type': 'STRING'},
    },
    'required': [
      'score',
      'is_acceptable',
      'corrected',
      'explanation',
      'comparison',
    ],
  };

  /// 中国語の添削スキーマ。修正版・発話それぞれの語区切りを追加で返させる。
  ///
  /// 修正版は語ごとにピンイン付き（辞書どおりの読みで良い。声調の判定には
  /// 使わない）で、ルビの割り当てと差分ハイライトの単位に使う
  /// （DESIGN.md「口頭中国語作文の添削画面」参照）。
  static const schemaWithReading = {
    'type': 'OBJECT',
    'properties': {
      'score': {'type': 'INTEGER'},
      'is_acceptable': {'type': 'BOOLEAN'},
      'corrected': {'type': 'STRING'},
      'corrected_words': {
        'type': 'ARRAY',
        'description': 'corrected を単語ごとに区切ったもの。hanzi を順に連結すると corrected と一致する。',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'hanzi': {'type': 'STRING', 'description': 'その単語の漢字（句読点だけの要素もある）。'},
            'pinyin': {
              'type': 'STRING',
              'description':
                  'その単語の声調記号付きピンイン（例: zǒng shì）。声調番号や記号なしは不可。'
                  '音節ごとに半角スペース区切り。句読点だけの要素は空文字。',
            },
          },
          'required': ['hanzi', 'pinyin'],
        },
      },
      'spoken_words': {
        'type': 'ARRAY',
        'description': '生徒の発話を単語ごとに区切ったもの。順に連結すると発話と一致する。',
        'items': {'type': 'STRING'},
      },
      'explanation': {'type': 'STRING'},
      'comparison': {'type': 'STRING'},
    },
    'required': [
      'score',
      'is_acceptable',
      'corrected',
      'corrected_words',
      'spoken_words',
      'explanation',
      'comparison',
    ],
  };

  static const correctedWordsInstruction =
      '- corrected_words: corrected を中国語の単語（語彙）単位で区切った配列。「建筑物」「前面」のように'
      'ひとまとまりの語は分割しない。hanzi を順に連結したとき corrected と1文字も違わないこと'
      '（句読点も1要素として残す）。\n'
      '  pinyin はその単語の標準的なピンイン。**必ず声調記号付き**（ā á ǎ à、ü は ǖ ǘ ǚ ǜ）で書き、'
      '声調番号（wo3）や記号なし（wo）は不可。変調（3声の連続・一・不）を実際の発音どおりに適用し、'
      '音節ごとに半角スペースで区切る。軽声だけ記号なし。句読点だけの要素は pinyin を空文字にする。'
      '例: 我总是在同一家店买。→ '
      '[{"hanzi":"我","pinyin":"wǒ"},{"hanzi":"总是","pinyin":"zǒng shì"},{"hanzi":"在","pinyin":"zài"},'
      '{"hanzi":"同一","pinyin":"tóng yì"},{"hanzi":"家","pinyin":"jiā"},{"hanzi":"店","pinyin":"diàn"},'
      '{"hanzi":"买","pinyin":"mǎi"},{"hanzi":"。","pinyin":""}]\n'
      '- spoken_words: 生徒の発話（文字起こし）を同じ規則で単語に区切った文字列の配列。'
      '順に連結したとき発話と1文字も違わないこと。聞き取りが崩れていても直さず、そのまま区切る。\n';
}
