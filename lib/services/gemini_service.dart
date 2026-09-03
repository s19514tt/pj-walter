import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/drill_result.dart';
import '../models/monologue_result.dart';
import '../models/pronunciation_feedback.dart';
import 'settings_service.dart';

/// Gemini API呼び出し失敗時に投げられる例外。
///
/// [message]はUIにそのまま表示できる日本語文言。
class GeminiException implements Exception {
  GeminiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Gemini REST APIクライアント（DESIGN.md「Gemini API契約」参照）。
///
/// APIキーは[SettingsService]から取得し、モデルは[modelName]に固定する。
/// テスト容易性のため[http.Client]はコンストラクタ注入できる。
class GeminiService {
  GeminiService({required SettingsService settingsService, http.Client? client})
    : _settings = settingsService,
      _client = client ?? http.Client();

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _timeout = Duration(seconds: 30);

  /// 使用するGeminiモデル。最新のFlash系1本に固定し、設定画面からは変更できない
  /// （料金計算・動作検証の対象を1モデルに絞るため）。
  static const modelName = 'gemini-3.8-flash';

  /// 思考（thinking）の強さ。Gemini 3系は`thinkingBudget`ではなく
  /// `thinkingLevel`で制御し、完全にオフにはできない。文字起こし・添削は
  /// 深い推論を必要としないため最小の`low`にして応答時間とコストを抑える。
  static const _thinkingLevel = 'low';

  /// 発音評価に使う思考の強さ。音声を聞いて単語ごとに判定する必要があり、
  /// `low`では評価が粗くなりやすいため一段上げる（コストは出力トークンとして加算）。
  static const _pronunciationThinkingLevel = 'medium';

  final SettingsService _settings;
  final http.Client _client;

  /// 口頭英作文の発話をGeminiに添削させる。
  Future<CompositionFeedback> correctComposition({
    required String ja,
    required String modelAnswer,
    required String spoken,
  }) async {
    final prompt =
        '''
あなたは日本人向けの英語スピーキング講師です。生徒が日本語文を見て英語で発話した内容を添削してください。
発話内容は音声認識によって文字起こしされたものなので、大文字・小文字の違いや句読点の有無は減点しないでください。
意味が通り文法的に正しい英文であれば、模範解答と表現が異なっていても許容し、正当に評価してください。

日本語原文: $ja
模範解答: $modelAnswer
生徒の発話（文字起こし）: $spoken

以下のJSONスキーマに従って評価結果を出力してください。

- score: 下記のルーブリックに従って0〜100で採点する
  - 95-100: ほぼ完璧で自然
  - 85-94: 正確だがわずかに不自然
  - 70-84: 軽微な文法・語彙ミスはあるが問題なく伝わる（70点が合格ライン）
  - 50-69: 意味は伝わるが明確な文法ミスがある
  - 30-49: 部分的にしか伝わらない
  - 0-29: ほぼ伝わらない
- is_acceptable: scoreが70以上なら合格(true)
- corrected: 生徒の発話を最小限の編集で正しくした英文にすること。模範解答を丸写しするのではなく、
  生徒が選んだ語彙・構文をできる限りそのまま活かして修正する。
  例: 発話が "I was too tired so that I couldn't go out" なら、
  corrected は生徒のso that構文を活かして "I was so tired that I couldn't go out" とする。
  模範解答が "too tired to go out" のような表現でも、それに書き換えるのはNG（生徒の構文を壊すため）。
- explanation_ja: 誤りの解説を「誤り→なぜ誤りか→どう覚えるか」の順で簡潔に（日本語、2〜3文）
- comparison_ja: 模範解答との違いや、どちらでも良い点の解説（日本語）
''';

    final json = await _generate(
      parts: [_textPart(prompt)],
      schema: _compositionSchema,
    );
    try {
      return CompositionFeedback.fromJson(json);
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  /// 独り言英会話のトランスクリプトをGeminiにレビューさせる。
  Future<MonologueFeedback> reviewMonologue({
    required String topicJa,
    required String topicEn,
    required int seconds,
    required String transcript,
  }) async {
    final prompt =
        '''
あなたは日本人向けの英語スピーキング講師です。生徒が下記のお題について英語で$seconds秒間話した内容を添削してください。
発話内容は音声認識によって文字起こしされたものなので、大文字・小文字の違いや句読点の有無は減点しないでください。

お題（日本語）: $topicJa
お題（英語）: $topicEn
発話の文字起こし: $transcript

以下のJSONスキーマに従ってフィードバックを出力してください。

- fluency_score: 下記のルーブリックに従って0〜100で採点する
  - 95-100: ほぼ完璧で自然
  - 85-94: 正確だがわずかに不自然
  - 70-84: 軽微な文法・語彙ミスはあるが問題なく伝わる（70点が合格ライン）
  - 50-69: 意味は伝わるが明確な文法ミスがある
  - 30-49: 部分的にしか伝わらない
  - 0-29: ほぼ伝わらない
- corrected_transcript: 発話全文を、発話の流れ・語彙選択をできる限り保った最小限の修正で自然な英語に
  直したもの（模範解答的な書き直しではなく、生徒自身の言い回しを活かすこと）
- corrections: 個別の修正点（original: 元の表現, corrected: 修正後, reason_ja: 理由を日本語で）
- useful_phrases: 次回使える表現を3〜5個（en: 英語表現, ja: 日本語訳）
- overall_feedback_ja: 良かった点と改善点を含む総評（日本語、3〜4文）
''';

    final json = await _generate(
      parts: [_textPart(prompt)],
      schema: _monologueSchema,
    );
    try {
      return MonologueFeedback.fromJson(json);
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  /// 録音音声の発音をGeminiに評価させる（口頭英作文の添削と並列で呼ぶ）。
  ///
  /// 音声を`inline_data`で送り、[spokenText]（文字起こし）の単語ごとの
  /// 発音スコアと総合スコア・アドバイスをJSONで受け取る。
  Future<PronunciationFeedback> assessPronunciation({
    required List<int> audioBytes,
    required String mimeType,
    required String spokenText,
    required String modelAnswer,
  }) async {
    final prompt =
        '''
あなたは日本人向けの英語発音コーチです。添付の音声は、生徒が下記の英文を声に出して言ったものです。
音声を聞いて、発音の観点だけで評価してください（文法・語彙の誤りは評価対象外です）。

生徒が言おうとした英文（文字起こし）: $spokenText
参考（模範解答）: $modelAnswer

評価の観点:
- 個々の音（日本人が苦手な r/l、th、v/b、f/h、母音の区別など）
- 語の強勢（アクセント位置）と文のリズム・イントネーション
- 音のつながり（リンキング）と不要な母音の挿入（例: "and" を「アンド」と言う）
- 音声認識が読み取れる程度に明瞭か

以下のJSONスキーマに従って出力してください。

- score: 発音の総合スコアを0〜100で採点する
  - 90-100: ネイティブに近く、ほぼ違和感がない
  - 75-89: 明瞭で問題なく伝わるが、日本語訛りが少し残る
  - 60-74: 伝わるが、いくつかの音や強勢に明確な癖がある
  - 40-59: 聞き返される可能性がある音が複数ある
  - 0-39: 大部分が聞き取りにくい
- words: 文字起こしの単語を語順どおりに1つずつ評価する（分割・結合・省略をしない）
  - word: 単語（文字起こしと同じ表記）
  - score: その単語の発音スコア（0〜100）
  - issue_ja: 問題があれば具体的な指摘を日本語で1文（例: "th が s に聞こえます"）。問題なければ空文字
- advice_ja: 次に意識すべき最重要ポイントを日本語で2〜3文。良かった点も1つ含める
''';

    final json = await _generate(
      parts: [
        _textPart(prompt),
        {
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Encode(audioBytes),
          },
        },
      ],
      schema: _pronunciationSchema,
      thinkingLevel: _pronunciationThinkingLevel,
    );
    try {
      return PronunciationFeedback.fromJson(json);
    } catch (_) {
      throw GeminiException('発音評価の応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  /// 録音済み音声をGeminiに文字起こしさせる（STT方式=geminiのとき使用）。
  Future<String> transcribe({
    required List<int> audioBytes,
    required String mimeType,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse('$_baseUrl/$modelName:generateContent');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Transcribe this English speech verbatim. Return only the transcript.',
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(audioBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'thinkingConfig': {'thinkingLevel': _thinkingLevel},
      },
    });

    final response = await _post(uri: uri, apiKey: apiKey, body: body);
    _checkStatus(response);
    try {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return _extractText(decoded).trim();
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  static Map<String, dynamic> _textPart(String text) => {'text': text};

  /// 構造化出力（JSON）でGeminiを呼び出し、パース済みのMapを返す。
  ///
  /// [parts]はテキストや`inline_data`（音声）を含むリクエストのparts配列。
  Future<Map<String, dynamic>> _generate({
    required List<Map<String, dynamic>> parts,
    required Map<String, dynamic> schema,
    String thinkingLevel = _thinkingLevel,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse('$_baseUrl/$modelName:generateContent');
    final body = jsonEncode({
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': schema,
        'thinkingConfig': {'thinkingLevel': thinkingLevel},
      },
    });

    final response = await _post(uri: uri, apiKey: apiKey, body: body);
    _checkStatus(response);
    try {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final text = _extractText(decoded);
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  String _extractText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'] as List;
    final content = candidates.first['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List;
    return parts.first['text'] as String;
  }

  Future<http.Response> _post({
    required Uri uri,
    required String apiKey,
    required String body,
  }) async {
    try {
      return await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: body,
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw GeminiException('通信がタイムアウトしました。電波状況を確認して再度お試しください。');
    } catch (_) {
      throw GeminiException('通信エラーが発生しました。ネットワーク接続を確認してください。');
    }
  }

  String _requireApiKey() {
    final apiKey = _settings.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw GeminiException('APIキーが設定されていません。設定画面からAPIキーを登録してください。');
    }
    return apiKey;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode == 200) return;
    switch (response.statusCode) {
      case 401:
      case 403:
        throw GeminiException('APIキーが無効です。設定画面で正しいAPIキーを設定してください。');
      case 429:
        throw GeminiException('リクエストが多すぎます。しばらく待ってから再度お試しください。');
      case 400:
        throw GeminiException('リクエストが不正です。入力内容を確認してください。');
      default:
        if (response.statusCode >= 500) {
          throw GeminiException('Geminiサーバーでエラーが発生しました。しばらくしてから再度お試しください。');
        }
        throw GeminiException('通信エラーが発生しました（エラーコード: ${response.statusCode}）。');
    }
  }

  static const _compositionSchema = {
    'type': 'OBJECT',
    'properties': {
      'score': {'type': 'INTEGER'},
      'is_acceptable': {'type': 'BOOLEAN'},
      'corrected': {'type': 'STRING'},
      'explanation_ja': {'type': 'STRING'},
      'comparison_ja': {'type': 'STRING'},
    },
    'required': [
      'score',
      'is_acceptable',
      'corrected',
      'explanation_ja',
      'comparison_ja',
    ],
  };

  static const _pronunciationSchema = {
    'type': 'OBJECT',
    'properties': {
      'score': {'type': 'INTEGER'},
      'words': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'word': {'type': 'STRING'},
            'score': {'type': 'INTEGER'},
            'issue_ja': {'type': 'STRING'},
          },
          'required': ['word', 'score', 'issue_ja'],
        },
      },
      'advice_ja': {'type': 'STRING'},
    },
    'required': ['score', 'words', 'advice_ja'],
  };

  static const _monologueSchema = {
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
            'reason_ja': {'type': 'STRING'},
          },
          'required': ['original', 'corrected', 'reason_ja'],
        },
      },
      'useful_phrases': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'en': {'type': 'STRING'},
            'ja': {'type': 'STRING'},
          },
          'required': ['en', 'ja'],
        },
      },
      'overall_feedback_ja': {'type': 'STRING'},
    },
    'required': [
      'fluency_score',
      'corrected_transcript',
      'corrections',
      'useful_phrases',
      'overall_feedback_ja',
    ],
  };
}
