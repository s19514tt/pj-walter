import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/app_failure.dart';
import '../domain/token_usage.dart';

/// `generateContent` 1回分の本文テキストとトークン使用量。
typedef GeminiTextResponse = ({String text, TokenUsage usage});

/// 構造化出力（JSON）1回分のパース済み Map とトークン使用量。
typedef GeminiJsonResponse = ({Map<String, dynamic> json, TokenUsage usage});

/// 音声出力1回分の PCM16 とサンプリングレート、トークン使用量。
typedef GeminiAudioResponse = ({
  Uint8List pcm,
  int sampleRate,
  TokenUsage usage,
});

/// Gemini REST API の共通トランスポート（DESIGN.md「Gemini API契約」）。
///
/// 認証ヘッダー・ステータス判定・本文が空の応答の再試行・`usageMetadata` の
/// 読み取りだけを担い、プロンプトやスキーマは各 Repository 実装が持つ。
///
/// **次フェーズで API キーと Gemini 呼び出しはサーバ側に集約され、このクラスは
/// アプリから削除される。** 各 Repository の Gemini 実装だけがこれに依存する。
class GeminiClient {
  GeminiClient({required this._apiKey, http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _timeout = Duration(seconds: 30);

  /// 使用するGeminiモデル。最新のFlash系1本に固定し、設定画面からは変更できない
  /// （料金計算・動作検証の対象を1モデルに絞るため）。
  static const modelName = 'gemini-3.8-flash';

  /// 読み上げ（TTS）に使うモデル。[modelName]は音声出力に対応していないため、
  /// 読み上げだけ専用モデルを使う（単価も別。`GeminiPricing.tts`参照）。
  static const ttsModelName = 'gemini-3.1-flash-tts-preview';

  /// TTSが返すPCMのサンプリングレート（mimeTypeにrateが無い場合のフォールバック）。
  static const _ttsFallbackSampleRate = 24000;

  /// 思考（thinking）の強さ。Gemini 3系は`thinkingBudget`ではなく
  /// `thinkingLevel`で制御し、完全にオフにはできない。文字起こし・添削は
  /// 深い推論を必要としないため最小の`low`にして応答時間とコストを抑える。
  static const thinkingLevel = 'low';

  /// 本文が空の応答（`parts`ごと省略され`candidatesTokenCount`も無い）に対する
  /// 最大試行回数。Gemini 3系のFlashは`finishReason: STOP`のまま何も返さない
  /// ことが稀にあり、同じリクエストを送り直すと正常に返ることが多い。
  static const maxAttempts = 3;

  final String? Function() _apiKey;
  final http.Client _client;

  /// 構造化出力（JSON）で呼び出し、パース済みのMapとトークン使用量を返す。
  Future<GeminiJsonResponse> generateJson({
    required String prompt,
    required Map<String, dynamic> schema,
  }) async {
    final (:text, :usage) = await generateText(
      parts: [
        {'text': prompt},
      ],
      responseSchema: schema,
    );
    try {
      return (json: jsonDecode(text) as Map<String, dynamic>, usage: usage);
    } catch (_) {
      throw const AppFailure(FailureKind.invalidResponse);
    }
  }

  /// テキスト（または構造化出力）で呼び出し、候補本文のテキストとトークン使用量を返す。
  ///
  /// 本文が空（`parts`省略）の応答は最大[maxAttempts]回まで同じリクエストを
  /// 送り直す。全試行で空なら空文字を返す（意味付けは呼び出し側で行う）。
  /// 使用量は再試行分も含めた合計（すべて課金対象のため）。
  Future<GeminiTextResponse> generateText({
    required List<Map<String, dynamic>> parts,
    Map<String, dynamic>? responseSchema,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse('$_baseUrl/$modelName:generateContent');
    final body = jsonEncode({
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {
        if (responseSchema != null) ...{
          'responseMimeType': 'application/json',
          'responseSchema': responseSchema,
        },
        'thinkingConfig': {'thinkingLevel': thinkingLevel},
      },
    });

    var usage = TokenUsage.zero;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final decoded = await _postJson(uri: uri, apiKey: apiKey, body: body);
      final String text;
      try {
        text = _extractText(decoded).trim();
      } catch (_) {
        throw const AppFailure(FailureKind.invalidResponse);
      }
      usage += _extractUsage(decoded);
      if (text.isNotEmpty) return (text: text, usage: usage);
    }
    return (text: '', usage: usage);
  }

  /// TTS モデルで[text]を読み上げ、生のPCM16（モノラル）とサンプリングレートを返す。
  ///
  /// 音声が入っていない応答は [FailureKind.noAudio]。
  /// `thinkingConfig` は付けない（TTSモデルは思考を持たない）。
  Future<GeminiAudioResponse> generateSpeech({
    required String instruction,
    required String voiceName,
  }) async {
    final apiKey = _requireApiKey();
    final uri = Uri.parse('$_baseUrl/$ttsModelName:generateContent');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': instruction},
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['AUDIO'],
        'speechConfig': {
          'voiceConfig': {
            'prebuiltVoiceConfig': {'voiceName': voiceName},
          },
        },
      },
    });

    final decoded = await _postJson(uri: uri, apiKey: apiKey, body: body);
    final audio = _extractInlineAudio(decoded);
    if (audio == null) throw const AppFailure(FailureKind.noAudio);
    return (
      pcm: audio.pcm,
      sampleRate: audio.sampleRate,
      usage: _extractUsage(decoded),
    );
  }

  Future<Map<String, dynamic>> _postJson({
    required Uri uri,
    required String apiKey,
    required String body,
  }) async {
    final response = await _post(uri: uri, apiKey: apiKey, body: body);
    _checkStatus(response);
    try {
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (_) {
      throw const AppFailure(FailureKind.invalidResponse);
    }
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

  /// レスポンスの`usageMetadata`を読む。無ければ[TokenUsage.zero]。
  static TokenUsage _extractUsage(Map<String, dynamic> decoded) {
    final metadata = decoded['usageMetadata'];
    if (metadata is! Map) return TokenUsage.zero;
    int read(String key) => (metadata[key] as num?)?.toInt() ?? 0;
    return TokenUsage(
      promptTokens: read('promptTokenCount'),
      candidatesTokens: read('candidatesTokenCount'),
      thoughtsTokens: read('thoughtsTokenCount'),
    );
  }

  static String _extractText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'] as List;
    final content = candidates.first['content'] as Map<String, dynamic>;
    // 出力が空の場合、partsごと省略された応答が返ることがある
    // （`"content": {}` で `finishReason: STOP`）。解析エラーではなく
    // 空文字として扱い、再試行の判断は[generateText]に任せる。
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
      throw const AppFailure(FailureKind.timeout);
    } catch (_) {
      throw const AppFailure(FailureKind.network);
    }
  }

  String _requireApiKey() {
    final apiKey = _apiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AppFailure(FailureKind.apiKeyMissing);
    }
    return apiKey;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode == 200) return;
    final detail = 'HTTP ${response.statusCode}';
    switch (response.statusCode) {
      case 401:
      case 403:
        throw AppFailure(FailureKind.apiKeyInvalid, detail: detail);
      case 429:
        throw AppFailure(FailureKind.rateLimited, detail: detail);
      case 400:
        throw AppFailure(FailureKind.badRequest, detail: detail);
      default:
        if (response.statusCode >= 500) {
          throw AppFailure(FailureKind.serverError, detail: detail);
        }
        throw AppFailure(FailureKind.unexpectedStatus, detail: detail);
    }
  }
}
