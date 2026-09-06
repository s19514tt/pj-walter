import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/drill_result.dart';
import '../models/learning_language.dart';
import '../models/monologue_result.dart';
import '../models/token_usage.dart';
import '../utils/wav_builder.dart';
import 'settings_service.dart';

/// [GeminiService.correctComposition]の結果（添削＋トークン使用量）。
typedef CorrectionResult = ({CompositionFeedback feedback, TokenUsage usage});

/// [GeminiService.reviewMonologue]の結果（フィードバック＋トークン使用量）。
typedef MonologueReviewResult = ({
  MonologueFeedback feedback,
  TokenUsage usage,
});

/// [GeminiService.transcribe]の結果（文字起こし＋トークン使用量）。
///
/// [reading]は中国語のときだけ入る「聞こえたままの声調付きピンイン」
/// （DESIGN.md「中国語の文字起こし」参照）。英語では常に null。
typedef TranscriptionResult = ({
  String text,
  String? reading,
  TokenUsage usage,
});

/// [GeminiService.synthesizeSpeech]の結果（WAV音声＋トークン使用量）。
typedef SpeechResult = ({Uint8List wavBytes, TokenUsage usage});

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
/// 各メソッドはレスポンスの`usageMetadata`から読んだ[TokenUsage]を結果と
/// 一緒に返す（料金表示用。DESIGN.md「トークン使用量とコスト」参照）。
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

  /// 読み上げ（TTS）に使うモデル。[modelName]は音声出力に対応していないため、
  /// 読み上げだけ専用モデルを使う（単価も別。[GeminiPricing.tts]参照）。
  static const ttsModelName = 'gemini-3.1-flash-tts-preview';

  /// 読み上げに使うプリセット音声。落ち着いた聞き取りやすい声を選んでいる。
  static const ttsVoiceName = 'Kore';

  /// TTSが返すPCMのサンプリングレート（mimeTypeにrateが無い場合のフォールバック）。
  static const _ttsFallbackSampleRate = 24000;

  /// 思考（thinking）の強さ。Gemini 3系は`thinkingBudget`ではなく
  /// `thinkingLevel`で制御し、完全にオフにはできない。文字起こし・添削は
  /// 深い推論を必要としないため最小の`low`にして応答時間とコストを抑える。
  static const _thinkingLevel = 'low';

  /// 文字起こしで「聞き取れる英語が無い」ときにモデルへ返させる目印。
  ///
  /// 空文字を返させると、モデルが（一時的な不調で）何も生成しなかった応答と
  /// 区別できないため、明示的なマーカーで「無音」を表現させる。
  static const noSpeechMarker = '[NO_SPEECH]';

  /// 本文が空の応答（`parts`ごと省略され`candidatesTokenCount`も無い）に対する
  /// 最大試行回数。Gemini 3系のFlashは`finishReason: STOP`のまま何も返さない
  /// ことが稀にあり、同じリクエストを送り直すと正常に返ることが多い。
  static const _maxAttempts = 3;

  final SettingsService _settings;
  final http.Client _client;

  /// 口頭作文の発話をGeminiに添削させる。
  Future<CorrectionResult> correctComposition({
    required LanguageProfile profile,
    required String ja,
    required String modelAnswer,
    required String spoken,
  }) async {
    final language = profile.label;
    final withReading = profile.readingLabel != null;
    final prompt =
        '''
日本人向けの$languageスピーキング講師として、学習者が日本語文を見て$languageで発話した内容を添削してください。
日本語の解説では学習者本人に語りかける形で書き、学習者を指すときは「あなた」と呼んでください。「生徒」という呼び方は使わないでください。
発話内容は音声認識によって文字起こしされたものなので、大文字・小文字の違いや句読点の有無は減点しないでください。
意味が通り文法的に正しい$languageの文であれば、模範解答と表現が異なっていても許容し、正当に評価してください。
発音・声調は評価対象に含めません（音声認識を経ているため判定できません）。文法・語彙・語順のみを見てください。

日本語原文: $ja
模範解答: $modelAnswer
学習者の発話（文字起こし）: $spoken

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
- explanation_ja: 誤りの解説を「誤り→なぜ誤りか→どう覚えるか」の順で簡潔に（日本語、2〜3文）
- comparison_ja: 模範解答との違いや、どちらでも良い点の解説（日本語）
${withReading ? _correctedReadingInstruction : ''}''';

    final (:json, :usage) = await _generate(
      prompt: prompt,
      schema: withReading ? _compositionSchemaWithReading : _compositionSchema,
    );
    try {
      return (feedback: CompositionFeedback.fromJson(json), usage: usage);
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  /// 独り言トレーニングのトランスクリプトをGeminiにレビューさせる。
  Future<MonologueReviewResult> reviewMonologue({
    required LanguageProfile profile,
    required String topicJa,
    required String topicTarget,
    required int seconds,
    required String transcript,
  }) async {
    final language = profile.label;
    final prompt =
        '''
日本人向けの$languageスピーキング講師として、学習者が下記のお題について$languageで$seconds秒間話した内容を添削してください。
日本語の解説では学習者本人に語りかける形で書き、学習者を指すときは「あなた」と呼んでください。「生徒」という呼び方は使わないでください。
発話内容は音声認識によって文字起こしされたものなので、大文字・小文字の違いや句読点の有無は減点しないでください。
発音・声調は評価対象に含めません（音声認識を経ているため判定できません）。文法・語彙・語順のみを見てください。

お題（日本語）: $topicJa
お題（$language）: $topicTarget
発話の文字起こし: $transcript

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
- corrections: 個別の修正点（original: 元の表現, corrected: 修正後, reason_ja: 理由を日本語で）
- useful_phrases: 次回使える表現を3〜5個（target: $languageの表現, ja: 日本語訳）
- overall_feedback_ja: 良かった点と改善点を含む総評（日本語、3〜4文）
''';

    final (:json, :usage) = await _generate(
      prompt: prompt,
      schema: _monologueSchema,
    );
    try {
      return (feedback: MonologueFeedback.fromJson(json), usage: usage);
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  /// 録音済み音声をGeminiに文字起こしさせる。
  ///
  /// 中国語（[LanguageProfile.readingLabel]が非null）のときだけ構造化出力で
  /// `{pinyin, hanzi}` を受け取り、[TranscriptionResult.reading]に聞こえたままの
  /// 声調付きピンインを入れる。英語はプレーンテキストのままで一切変えない。
  Future<TranscriptionResult> transcribe({
    required LanguageProfile profile,
    required List<int> audioBytes,
    required String mimeType,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse('$_baseUrl/$modelName:generateContent');
    final withReading = profile.readingLabel != null;
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': withReading
                  ? _readingTranscriptionPrompt
                  : _plainTranscriptionPrompt(profile),
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
        if (withReading) ...{
          'responseMimeType': 'application/json',
          'responseSchema': _readingTranscriptionSchema,
        },
        'thinkingConfig': {'thinkingLevel': _thinkingLevel},
      },
    });

    final (:text, :usage) = await _requestText(
      uri: uri,
      apiKey: apiKey,
      body: body,
    );
    // 本文が空の応答は再試行しても解消しなかった（モデルが何も生成しなかった）。
    // 「聞き取れなかった」とは区別し、送り直しを促す。
    if (text.isEmpty) {
      throw GeminiException('Geminiから文字起こし結果が返ってきませんでした。もう一度お試しください。');
    }
    if (!withReading) {
      _checkNoSpeech(text);
      return (text: text, reading: null, usage: usage);
    }

    final String hanzi;
    final String pinyin;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      hanzi = ((json['hanzi'] as String?) ?? '').trim();
      pinyin = ((json['pinyin'] as String?) ?? '').trim();
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
    // 構造化出力では本文が空でもJSONは返るため、漢字が空なら聞き取れなかった扱い。
    if (hanzi.isEmpty) {
      throw GeminiException('音声を聞き取れませんでした。もう一度お試しください。');
    }
    _checkNoSpeech(hanzi);
    return (text: hanzi, reading: pinyin.isEmpty ? null : pinyin, usage: usage);
  }

  /// 聞き取れる発話が無い場合はマーカーが返る（プロンプトでそう指示している）。
  /// 空のまま入力欄に反映すると理由が分からないため、明示的に案内する。
  void _checkNoSpeech(String text) {
    if (text.contains(noSpeechMarker)) {
      throw GeminiException('音声を聞き取れませんでした。もう一度お試しください。');
    }
  }

  /// [text]をGeminiに読み上げさせ、再生可能なWAVバイト列を返す。
  ///
  /// TTSモデルは生のPCM16（モノラル、mimeTypeの`rate`はふつう24000）を
  /// base64で返すため、[buildWavBytes]でWAVヘッダーを付けてから返す。
  /// 読み上げ言語はモデルが入力テキストから自動判定するので明示指定はしない。
  Future<SpeechResult> synthesizeSpeech({
    required LanguageProfile profile,
    required String text,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse('$_baseUrl/$ttsModelName:generateContent');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              // 学習者が発音を追えるように、速度と明瞭さを指示する。
              // 指示文と読み上げ対象を1つのpartに入れるのがTTSモデルの作法。
              'text':
                  'Read the following ${profile.label} sentence clearly and '
                  'a little slowly, in a calm teaching voice: $text',
            },
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['AUDIO'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': ttsVoiceName},
          },
        },
      },
    });

    final response = await _post(uri: uri, apiKey: apiKey, body: body);
    _checkStatus(response);
    final Map<String, dynamic> decoded;
    try {
      decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
    final audio = _extractInlineAudio(decoded);
    if (audio == null) {
      throw GeminiException('読み上げ音声を取得できませんでした。時間を置いて再度お試しください。');
    }
    return (
      wavBytes: buildWavBytes(audio.pcm, sampleRate: audio.sampleRate),
      usage: _extractUsage(decoded),
    );
  }

  /// 音声応答の`inlineData`からPCMデータとサンプリングレートを取り出す。
  ///
  /// 音声が入っていない応答（`parts`省略など）はnullを返す。
  /// mimeTypeは`audio/L16;codec=pcm;rate=24000`の形なので`rate`を読む。
  ({Uint8List pcm, int sampleRate})? _extractInlineAudio(
    Map<String, dynamic> decoded,
  ) {
    try {
      final candidates = decoded['candidates'] as List;
      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;
      final inline = parts.first['inlineData'] ?? parts.first['inline_data'];
      if (inline is! Map) return null;
      final data = inline['data'] as String?;
      if (data == null || data.isEmpty) return null;
      final mimeType = (inline['mimeType'] ?? inline['mime_type']) as String?;
      return (
        pcm: base64Decode(data),
        sampleRate: _sampleRateOf(mimeType) ?? _ttsFallbackSampleRate,
      );
    } catch (_) {
      return null;
    }
  }

  /// `audio/L16;codec=pcm;rate=24000`形式のmimeTypeからサンプリングレートを読む。
  static int? _sampleRateOf(String? mimeType) {
    if (mimeType == null) return null;
    final match = RegExp(r'rate=(\d+)').firstMatch(mimeType);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// 英語など、発音表記を扱わない言語のプレーンテキスト文字起こし指示。
  ///
  /// 「聞き取れなければマーカーを返す」指示が無いと、無音や壊れた音声を
  /// 渡されたときにモデルがそれらしい英文を捏造して返してしまう。
  static String _plainTranscriptionPrompt(LanguageProfile profile) =>
      'Transcribe this ${profile.label} speech verbatim. '
      'Return only the transcript. If the audio contains no '
      'intelligible ${profile.label} speech, return exactly '
      '$noSpeechMarker and nothing else. '
      'Never guess or invent words that are not clearly audible.';

  /// 中国語の文字起こし指示。聞こえたままの声調付きピンインを漢字と一緒に返させる。
  ///
  /// `tool/pinyin_poc`（ブランチ `claude/chinese-hanzi-pinyin-output-n0pzxe`）で
  /// 実測に使ったものと同じ方針: 語彙的に正しい声調へ直させず、ピッチだけを
  /// 根拠に書かせる。**模範解答はこの呼び出しに渡さない**（渡すと引っ張られる）。
  static const _readingTranscriptionPrompt =
      '''
あなたは中国語の音声を音声学的に書き起こす専門家です。話者は中国語学習者（日本語母語）で、声調を間違えている可能性があります。
この音声を書き起こし、pinyin と hanzi の両方を返してください。pinyin を先に、音だけを根拠に確定させてから hanzi を書くこと。

最重要ルール:
- pinyin は「実際に聞こえた音」をそのまま書くこと。声調記号は聞こえたピッチのとおりに付ける。音節ごとに半角スペースで区切る。
- 語彙的に正しい声調に直してはいけない。単語として不自然な声調になっても、聞こえたままを書く。
- 意味や文脈から声調を推測しないこと。ピッチの高さ・変化だけを根拠にする。
- 声調が判断できない音節は軽声（記号なし）とする。
- 変調（3声連続・一・不）は実際に発音されたとおりに書く。
- hanzi は発話をそのまま簡体字で書き起こしたもの。
- 聞き取れる中国語の発話が無い場合は hanzi に $noSpeechMarker だけを入れ、pinyin は空文字にする。聞こえない語を推測して補ってはいけない。
''';

  /// 中国語文字起こしの出力スキーマ。
  ///
  /// `propertyOrdering` で **必ず pinyin を先に生成させる**。構造化出力は左から
  /// 順に生成されるため、漢字を先に確定させるとピンインがその辞書引きになり、
  /// 実際に聞こえた声調が消える。
  static const _readingTranscriptionSchema = {
    'type': 'OBJECT',
    'properties': {
      'pinyin': {
        'type': 'STRING',
        'description': '実際に聞こえたとおりの声調付きピンイン。音節ごとに半角スペース区切り。',
      },
      'hanzi': {'type': 'STRING', 'description': '発話の簡体字書き起こし。'},
    },
    'required': ['pinyin', 'hanzi'],
    'propertyOrdering': ['pinyin', 'hanzi'],
  };

  /// 構造化出力（JSON）でGeminiを呼び出し、パース済みのMapとトークン使用量を返す。
  Future<({Map<String, dynamic> json, TokenUsage usage})> _generate({
    required String prompt,
    required Map<String, dynamic> schema,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse('$_baseUrl/$modelName:generateContent');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': schema,
        'thinkingConfig': {'thinkingLevel': _thinkingLevel},
      },
    });

    final (:text, :usage) = await _requestText(
      uri: uri,
      apiKey: apiKey,
      body: body,
    );
    try {
      return (json: jsonDecode(text) as Map<String, dynamic>, usage: usage);
    } catch (_) {
      throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
    }
  }

  /// `generateContent`を呼び、候補本文のテキストとトークン使用量を返す。
  ///
  /// 本文が空（`parts`省略）の応答は最大[_maxAttempts]回まで同じリクエストを
  /// 送り直す。全試行で空なら空文字を返す（意味付けは呼び出し側で行う）。
  /// 使用量は再試行分も含めた合計（すべて課金対象のため）。
  Future<({String text, TokenUsage usage})> _requestText({
    required Uri uri,
    required String apiKey,
    required String body,
  }) async {
    var usage = TokenUsage.zero;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      final response = await _post(uri: uri, apiKey: apiKey, body: body);
      _checkStatus(response);
      final String text;
      try {
        final decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        text = _extractText(decoded).trim();
        usage += _extractUsage(decoded);
      } catch (_) {
        throw GeminiException('Geminiからの応答を解析できませんでした。時間を置いて再度お試しください。');
      }
      if (text.isNotEmpty) return (text: text, usage: usage);
    }
    return (text: '', usage: usage);
  }

  /// レスポンスの`usageMetadata`を読む。無ければ[TokenUsage.zero]。
  TokenUsage _extractUsage(Map<String, dynamic> decoded) {
    final metadata = decoded['usageMetadata'];
    if (metadata is! Map) return TokenUsage.zero;
    return TokenUsage.fromUsageMetadata(Map<String, dynamic>.from(metadata));
  }

  String _extractText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'] as List;
    final content = candidates.first['content'] as Map<String, dynamic>;
    // 出力が空の場合、partsごと省略された応答が返ることがある
    // （`"content": {}` で `finishReason: STOP`）。解析エラーではなく
    // 空文字として扱い、再試行の判断は[_requestText]に任せる。
    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';
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

  /// 中国語の添削スキーマ。修正版のルビ表示用に標準ピンインを追加で返させる
  /// （こちらは辞書どおりの読みで良い。声調の判定には使わない）。
  static const _compositionSchemaWithReading = {
    'type': 'OBJECT',
    'properties': {
      'score': {'type': 'INTEGER'},
      'is_acceptable': {'type': 'BOOLEAN'},
      'corrected': {'type': 'STRING'},
      'corrected_reading': {
        'type': 'STRING',
        'description':
            'corrected の声調記号付きピンイン（例: wǒ zǒng shì zài tóng yì jiā diàn mǎi）。'
            '声調番号や記号なしは不可。音節ごとに半角スペース区切り。',
      },
      'explanation_ja': {'type': 'STRING'},
      'comparison_ja': {'type': 'STRING'},
    },
    'required': [
      'score',
      'is_acceptable',
      'corrected',
      'corrected_reading',
      'explanation_ja',
      'comparison_ja',
    ],
  };

  static const _correctedReadingInstruction =
      '- corrected_reading: corrected の標準的なピンイン。**必ず声調記号付き**（ā á ǎ à、ü は ǖ ǘ ǚ ǜ）で書き、'
      '声調番号（wo3）や記号なし（wo）は不可。変調（3声の連続・一・不）を実際の発音どおりに適用し、'
      '音節ごとに半角スペースで区切る。軽声だけ記号なし。句読点は含めない。'
      '例: 我总是在同一家店买。→ wǒ zǒng shì zài tóng yì jiā diàn mǎi\n';

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
            'target': {'type': 'STRING'},
            'ja': {'type': 'STRING'},
          },
          'required': ['target', 'ja'],
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
