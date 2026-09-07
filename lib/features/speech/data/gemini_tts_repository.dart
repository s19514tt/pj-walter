import '../../../core/data/gemini_client.dart';
import '../../../core/language/learning_language.dart';
import '../../../core/utils/wav_builder.dart';
import '../domain/tts_repository.dart';

/// [TtsRepository] の Gemini TTS 直叩き実装（DESIGN.md「読み上げ（TTS）」）。
///
/// TTSモデルは生のPCM16（モノラル、mimeTypeの`rate`はふつう24000）を
/// base64で返すため、[buildWavBytes]でWAVヘッダーを付けてから返す。
/// 読み上げ言語はモデルが入力テキストから自動判定するので明示指定はしない。
/// **次フェーズで Rust 側へ移植し、サーバ呼び出しに置き換わる。**
class GeminiTtsRepository implements TtsRepository {
  const GeminiTtsRepository(this._client);

  final GeminiClient _client;

  @override
  Future<TtsResult> synthesize(TtsRequest request) async {
    final profile = LanguageProfile.ofCode(request.learningLanguage);
    final (:pcm, :sampleRate, :usage) = await _client.generateSpeech(
      instruction: instruction(profile, request.text),
      voiceName: profile.support.ttsVoice,
    );
    return TtsResult(
      wavBytes: buildWavBytes(pcm, sampleRate: sampleRate),
      usage: usage,
    );
  }

  /// 学習者が発音を追えるように、速度と明瞭さを指示する。
  /// 指示文と読み上げ対象を1つのpartに入れるのがTTSモデルの作法。
  static String instruction(LanguageProfile profile, String text) =>
      'Read the following ${profile.support.englishName} sentence clearly and '
      'a little slowly, in a calm teaching voice: $text';
}
