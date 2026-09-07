import 'dart:convert';

import '../../../core/data/gemini_client.dart';
import '../../../core/domain/app_failure.dart';
import '../../../core/language/learning_language.dart';
import '../domain/transcription_repository.dart';

/// [TranscriptionRepository] の Gemini 直叩き実装（DESIGN.md「音声文字起こし」）。
///
/// 中国語（[LanguageProfile.hasReading]）のときだけ構造化出力で `{pinyin, hanzi}` を
/// 受け取り、[TranscriptionResult.reading]に聞こえたままの声調付きピンインを入れる。
/// 英語はプレーンテキストのままで一切変えない。
/// **次フェーズで Rust 側へ移植し、サーバ呼び出しに置き換わる。**
class GeminiTranscriptionRepository implements TranscriptionRepository {
  const GeminiTranscriptionRepository(this._client);

  final GeminiClient _client;

  /// 文字起こしで「聞き取れる発話が無い」ときにモデルへ返させる目印。
  ///
  /// 空文字を返させると、モデルが（一時的な不調で）何も生成しなかった応答と
  /// 区別できないため、明示的なマーカーで「無音」を表現させる。
  static const noSpeechMarker = '[NO_SPEECH]';

  @override
  Future<TranscriptionResult> transcribe(TranscriptionRequest request) async {
    final profile = LanguageProfile.ofCode(request.learningLanguage);
    final withReading = profile.hasReading;
    final (:text, :usage) = await _client.generateText(
      parts: [
        {
          'text': withReading
              ? readingTranscriptionPrompt
              : plainTranscriptionPrompt(profile),
        },
        {
          'inline_data': {
            'mime_type': request.mimeType,
            'data': base64Encode(request.audioBytes),
          },
        },
      ],
      responseSchema: withReading ? readingTranscriptionSchema : null,
    );
    // 本文が空の応答は再試行しても解消しなかった（モデルが何も生成しなかった）。
    // 「聞き取れなかった」とは区別し、送り直しを促す。
    if (text.isEmpty) throw const AppFailure(FailureKind.emptyResponse);
    if (!withReading) {
      _checkNoSpeech(text);
      return TranscriptionResult(text: text, usage: usage);
    }

    final String hanzi;
    final String pinyin;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      hanzi = ((json['hanzi'] as String?) ?? '').trim();
      pinyin = ((json['pinyin'] as String?) ?? '').trim();
    } catch (_) {
      throw const AppFailure(FailureKind.invalidResponse);
    }
    // 構造化出力では本文が空でもJSONは返るため、漢字が空なら聞き取れなかった扱い。
    if (hanzi.isEmpty) throw const AppFailure(FailureKind.noSpeech);
    _checkNoSpeech(hanzi);
    return TranscriptionResult(
      text: hanzi,
      reading: pinyin.isEmpty ? null : pinyin,
      usage: usage,
    );
  }

  /// 聞き取れる発話が無い場合はマーカーが返る（プロンプトでそう指示している）。
  void _checkNoSpeech(String text) {
    if (text.contains(noSpeechMarker)) {
      throw const AppFailure(FailureKind.noSpeech);
    }
  }

  /// 英語など、発音表記を扱わない言語のプレーンテキスト文字起こし指示。
  ///
  /// 「聞き取れなければマーカーを返す」指示が無いと、無音や壊れた音声を
  /// 渡されたときにモデルがそれらしい英文を捏造して返してしまう。
  static String plainTranscriptionPrompt(LanguageProfile profile) =>
      'Transcribe this ${profile.support.englishName} speech verbatim. '
      'Return only the transcript. If the audio contains no '
      'intelligible ${profile.support.englishName} speech, return exactly '
      '$noSpeechMarker and nothing else. '
      'Never guess or invent words that are not clearly audible.';

  /// 中国語の文字起こし指示。聞こえたままの声調付きピンインを漢字と一緒に返させる。
  ///
  /// `tool/pinyin_poc`（ブランチ `claude/chinese-hanzi-pinyin-output-n0pzxe`）で
  /// 実測に使ったものと同じ方針: 語彙的に正しい声調へ直させず、ピッチだけを
  /// 根拠に書かせる。**模範解答はこの呼び出しに渡さない**（渡すと引っ張られる）。
  static const readingTranscriptionPrompt =
      '''
あなたは中国語の音声を音声学的に書き起こす専門家です。話者は中国語学習者で、声調を間違えている可能性があります。
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
  static const readingTranscriptionSchema = {
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
}
