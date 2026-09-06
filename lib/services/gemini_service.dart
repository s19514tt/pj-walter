// 旧 provider ベースの画面のための一時的なファサード。
// 画面が Store（signals）へ移行し終わったら削除する。

import 'package:http/http.dart' as http;

import '../core/data/gemini_client.dart';
import '../core/language/learning_language.dart';
import '../features/composition/data/gemini_correction_repository.dart';
import '../features/composition/domain/correction_repository.dart';
import '../features/monologue/data/gemini_monologue_review_repository.dart';
import '../features/monologue/domain/monologue_review_repository.dart';
import '../features/speech/data/gemini_transcription_repository.dart';
import '../features/speech/data/gemini_tts_repository.dart';
import '../features/speech/domain/transcription_repository.dart';
import '../features/speech/domain/tts_repository.dart';
import 'settings_service.dart';

/// Gemini 実装の Repository 一式をまとめて見せる移行用ファサード。
class GeminiService {
  GeminiService({required SettingsService settingsService, http.Client? client})
    : this.of(
        GeminiClient(apiKey: () => settingsService.apiKey, client: client),
      );

  GeminiService.of(GeminiClient client)
    : correction = GeminiCorrectionRepository(client),
      monologueReview = GeminiMonologueReviewRepository(client),
      transcription = GeminiTranscriptionRepository(client),
      tts = GeminiTtsRepository(client);

  static const modelName = GeminiClient.modelName;
  static const ttsModelName = GeminiClient.ttsModelName;

  final CorrectionRepository correction;
  final MonologueReviewRepository monologueReview;
  final TranscriptionRepository transcription;
  final TtsRepository tts;

  /// 解説を書く言語。UI 言語が日本語のみのため固定（Store 化で locale から渡す）。
  static const uiLocale = 'ja';

  Future<CorrectionResult> correctComposition({
    required LanguageProfile profile,
    required String ja,
    required String modelAnswer,
    required String spoken,
  }) => correction.correct(
    CorrectionRequest(
      uiLocale: uiLocale,
      learningLanguage: profile.code,
      source: ja,
      modelAnswer: modelAnswer,
      spoken: spoken,
    ),
  );

  Future<MonologueReviewResult> reviewMonologue({
    required LanguageProfile profile,
    required String topicJa,
    required String topicTarget,
    required int seconds,
    required String transcript,
  }) => monologueReview.review(
    MonologueReviewRequest(
      uiLocale: uiLocale,
      learningLanguage: profile.code,
      topicSource: topicJa,
      topicTarget: topicTarget,
      seconds: seconds,
      transcript: transcript,
    ),
  );
}
