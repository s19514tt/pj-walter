import '../../../core/data/gemini_client.dart';
import '../../../core/domain/app_failure.dart';
import '../../../core/language/learning_language.dart';
import '../../composition/data/gemini_correction_repository.dart';
import '../domain/monologue_review_repository.dart';
import 'monologue_result_dto.dart';

/// [MonologueReviewRepository] の Gemini 直叩き実装。
///
/// プロンプトと JSON スキーマ（DESIGN.md「独り言英会話のフィードバック」）はここに置く。
/// **次フェーズで Rust 側へ移植し、サーバ呼び出しに置き換わる。**
class GeminiMonologueReviewRepository implements MonologueReviewRepository {
  const GeminiMonologueReviewRepository(this._client);

  final GeminiClient _client;

  @override
  Future<MonologueReviewResult> review(MonologueReviewRequest request) async {
    final (:json, :usage) = await _client.generateJson(
      prompt: buildPrompt(request),
      schema: schema,
    );
    try {
      return MonologueReviewResult(
        feedback: MonologueFeedbackDto.fromJson(json).toEntity(),
        usage: usage,
      );
    } catch (_) {
      throw const AppFailure(FailureKind.invalidResponse);
    }
  }

  static String buildPrompt(MonologueReviewRequest request) {
    final profile = LanguageProfile.ofCode(request.learningLanguage);
    final language = profile.support.englishName;
    final explanationLanguage =
        GeminiCorrectionRepository.explanationLanguageName(request.uiLocale);
    return '''
$explanationLanguage話者向けの$languageスピーキング講師として、学習者が下記のお題について$languageで${request.seconds}秒間話した内容を添削してください。
解説は$explanationLanguageで、学習者本人に語りかける形で書き、学習者を指すときは「あなた」と呼んでください。「生徒」という呼び方は使わないでください。
発話内容は音声認識によって文字起こしされたものなので、大文字・小文字の違いや句読点の有無は減点しないでください。
発音・声調は評価対象に含めません（音声認識を経ているため判定できません）。文法・語彙・語順のみを見てください。

お題（$explanationLanguage）: ${request.topicSource}
お題（$language）: ${request.topicTarget}
発話の文字起こし: ${request.transcript}

以下のJSONスキーマに従ってフィードバックを出力してください。

- fluency_score: 下記のルーブリックに従って0〜100で採点する
  - 95-100: ほぼ完璧で自然
  - 85-94: 正確だがわずかに不自然
  - 70-84: 軽微な文法・語彙ミスはあるが問題なく伝わる（70点が合格ライン）
  - 50-69: 意味は伝わるが明確な文法ミスがある
  - 30-49: 部分的にしか伝わらない
  - 0-29: ほぼ伝わらない
- corrected_transcript: 発話全文を、発話の流れ・語彙選択をできる限り保った最小限の修正で自然な$languageに
  直したもの（模範解答的な書き直しではなく、学習者自身の言い回しを活かすこと）
- corrections: 個別の修正点（original: 元の表現, corrected: 修正後, reason: 理由を$explanationLanguageで）
- useful_phrases: 次回使える表現を3〜5個（target: $languageの表現, ja: $explanationLanguageでの訳）
- overall_feedback: 良かった点と改善点を含む総評（$explanationLanguage、3〜4文）
''';
  }

  static const schema = {
    'type': 'OBJECT',
    'properties': {
      'fluency_score': {'type': 'INTEGER'},
      'corrected_transcript': {'type': 'STRING'},
      'corrections': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'original': {'type': 'STRING'},
            'corrected': {'type': 'STRING'},
            'reason': {'type': 'STRING'},
          },
          'required': ['original', 'corrected', 'reason'],
        },
      },
      'useful_phrases': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'target': {'type': 'STRING'},
            'ja': {'type': 'STRING'},
          },
          'required': ['target', 'ja'],
        },
      },
      'overall_feedback': {'type': 'STRING'},
    },
    'required': [
      'fluency_score',
      'corrected_transcript',
      'corrections',
      'useful_phrases',
      'overall_feedback',
    ],
  };
}
