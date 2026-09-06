import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/token_usage.dart';

part 'transcription_repository.freezed.dart';

/// 文字起こしのリクエスト。
@freezed
abstract class TranscriptionRequest with _$TranscriptionRequest {
  const factory TranscriptionRequest({
    /// 学習言語コード（[LanguageProfile.code]）。聞き取る言語と、読み表記を
    /// 併記するかどうか（中国語）がこれで決まる
    required String learningLanguage,

    /// 音声データ（WAV 推奨、16kHz mono）
    required List<int> audioBytes,

    /// [audioBytes] の MIME タイプ（例: `audio/wav`）
    required String mimeType,
  }) = _TranscriptionRequest;
}

/// 文字起こし結果。
///
/// [reading]は中国語のときだけ入る「聞こえたままの声調付きピンイン」
/// （DESIGN.md「中国語の文字起こし」参照）。英語では常に null。
@freezed
abstract class TranscriptionResult with _$TranscriptionResult {
  const factory TranscriptionResult({
    required String text,
    required TokenUsage usage,
    String? reading,
  }) = _TranscriptionResult;
}

/// 録音済み音声の文字起こしを行う Repository。
///
/// **次フェーズでサーバ実装に差し替わる継ぎ目。** 現在の実装は
/// `GeminiTranscriptionRepository`（Gemini 直叩き）。
/// 失敗は [AppFailure]（[FailureKind.noSpeech] / [FailureKind.emptyResponse] 等）で表す。
abstract interface class TranscriptionRepository {
  Future<TranscriptionResult> transcribe(TranscriptionRequest request);
}
