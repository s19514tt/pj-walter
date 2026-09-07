import 'package:get_it/get_it.dart';

import '../../core/data/gemini_client.dart';
import '../../core/language/learning_language.dart';
import 'data/audio_player_tts_service.dart';
import 'data/gemini_transcription_repository.dart';
import 'data/gemini_tts_repository.dart';
import 'data/recorder_speech_input_service.dart';
import 'domain/speech_input_service.dart';
import 'domain/transcription_repository.dart';
import 'domain/tts_repository.dart';
import 'domain/tts_service.dart';

/// 画面寿命の [SpeechInputService] を学習言語ごとに組み立てる関数。
///
/// 録音サービスはマイクを掴むため画面（Store）と同じ寿命で生成・破棄する。
/// `StoreFactory` がこれを呼んで Store に渡す。テストはフェイクを返す関数を登録する。
typedef SpeechInputServiceFactory =
    SpeechInputService Function(LanguageProfile profile);

/// 画面寿命の [TtsService] を学習言語ごとに組み立てる関数。
typedef TtsServiceFactory = TtsService Function(LanguageProfile profile);

/// speech feature の依存を登録する（コンポジションルートから呼ぶ）。
///
/// 次フェーズでは Gemini 実装をサーバ呼び出しの実装に差し替える。
void registerSpeech(GetIt getIt) {
  getIt.registerLazySingleton<TranscriptionRepository>(
    () => GeminiTranscriptionRepository(getIt<GeminiClient>()),
  );
  getIt.registerLazySingleton<TtsRepository>(
    () => GeminiTtsRepository(getIt<GeminiClient>()),
  );
  getIt.registerLazySingleton<SpeechInputServiceFactory>(
    () =>
        (profile) => RecorderSpeechInputService(
          transcription: getIt<TranscriptionRepository>(),
          profile: profile,
        ),
  );
  getIt.registerLazySingleton<TtsServiceFactory>(
    () =>
        (profile) => AudioPlayerTtsService(
          tts: getIt<TtsRepository>(),
          profile: profile,
        ),
  );
}
