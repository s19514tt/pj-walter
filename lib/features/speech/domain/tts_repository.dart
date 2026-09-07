import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/token_usage.dart';

part 'tts_repository.freezed.dart';

/// 読み上げ音声の生成リクエスト。
@freezed
abstract class TtsRequest with _$TtsRequest {
  const factory TtsRequest({
    /// 学習言語コード（[LanguageProfile.code]）。読み上げの声・指示文がこれで決まる
    required String learningLanguage,

    /// 読み上げる文
    required String text,
  }) = _TtsRequest;
}

/// 生成された音声（再生可能な WAV）とトークン使用量。
@freezed
abstract class TtsResult with _$TtsResult {
  const factory TtsResult({
    required Uint8List wavBytes,
    required TokenUsage usage,
  }) = _TtsResult;
}

/// 学習言語の文の読み上げ音声を生成する Repository。
///
/// **次フェーズでサーバ実装に差し替わる継ぎ目。** 現在の実装は
/// `GeminiTtsRepository`（Gemini TTS 直叩き）。再生は `TtsService` が担う。
/// 失敗は [AppFailure]（[FailureKind.noAudio] 等）で表す。
abstract interface class TtsRepository {
  Future<TtsResult> synthesize(TtsRequest request);
}
