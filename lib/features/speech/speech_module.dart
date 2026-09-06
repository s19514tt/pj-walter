import 'package:get_it/get_it.dart';

import '../../core/data/gemini_client.dart';
import 'data/gemini_transcription_repository.dart';
import 'data/gemini_tts_repository.dart';
import 'domain/transcription_repository.dart';
import 'domain/tts_repository.dart';

/// speech feature の依存を登録する（コンポジションルートから呼ぶ）。
///
/// 次フェーズでは Gemini 実装をサーバ呼び出しの実装に差し替える。
/// 録音・再生のサービス（`RecorderSpeechInputService` / `AudioPlayerTtsService`）は
/// 画面寿命なので登録せず、`StoreFactory` が Store と一緒に組み立てる。
void registerSpeech(GetIt getIt) {
  getIt.registerLazySingleton<TranscriptionRepository>(
    () => GeminiTranscriptionRepository(getIt<GeminiClient>()),
  );
  getIt.registerLazySingleton<TtsRepository>(
    () => GeminiTtsRepository(getIt<GeminiClient>()),
  );
}
