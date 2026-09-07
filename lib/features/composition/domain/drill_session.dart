import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/gemini_pricing.dart';
import '../../../core/domain/token_usage.dart';

part 'drill_session.freezed.dart';

/// ドリル1問分のAI API呼び出しで消費したトークン（用途別）。
@freezed
abstract class DrillQuestionUsage with _$DrillQuestionUsage {
  const DrillQuestionUsage._();

  const factory DrillQuestionUsage({
    /// 音声の文字起こし（やり直した分も含む合計）
    @Default(TokenUsage.zero) TokenUsage transcription,

    /// 添削
    @Default(TokenUsage.zero) TokenUsage correction,

    /// 添削結果の読み上げ（TTSモデル。単価が別なので分けて持つ）
    @Default(TokenUsage.zero) TokenUsage speech,
  }) = _DrillQuestionUsage;

  /// 使用量ゼロ（時間切れなど、API呼び出しが無かった問）
  static const zero = DrillQuestionUsage();

  /// 用途を問わない合計
  TokenUsage get total => transcription + correction + speech;

  /// [textPricing]（文字起こし・添削）と[GeminiPricing.tts]（読み上げ）を
  /// 用途ごとに使い分けた概算コスト（USD）。
  ///
  /// 読み上げは別モデル・別単価なので、合計トークンに単価を1つ掛けると
  /// 実際の請求とずれる。必ず用途ごとに計算して足し合わせる。
  double costUsd(GeminiPricing textPricing) =>
      textPricing.costUsd(transcription) +
      textPricing.costUsd(correction) +
      GeminiPricing.tts.costUsd(speech);

  DrillQuestionUsage operator +(DrillQuestionUsage other) => DrillQuestionUsage(
    transcription: transcription + other.transcription,
    correction: correction + other.correction,
    speech: speech + other.speech,
  );
}

/// ドリル1問分の結果概要（まとめ画面表示用）。
@freezed
abstract class DrillSummaryEntry with _$DrillSummaryEntry {
  const factory DrillSummaryEntry({
    /// 出題された日本語文
    required String ja,

    /// その問のスコア
    required int score,

    /// その問で消費したトークン
    @Default(DrillQuestionUsage.zero) DrillQuestionUsage usage,
  }) = _DrillSummaryEntry;
}
