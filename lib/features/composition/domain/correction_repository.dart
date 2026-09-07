import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/token_usage.dart';
import 'drill_result.dart';

part 'correction_repository.freezed.dart';

/// 口頭作文1問の添削リクエスト。
///
/// [uiLocale]（解説を書く言語）と [learningLanguage]（採点対象の言語）を
/// 別々に持つ。UI 言語と学習言語は独立して増えるため（DESIGN.md「i18n」）。
@freezed
abstract class CorrectionRequest with _$CorrectionRequest {
  const factory CorrectionRequest({
    /// 解説（`explanation` / `comparison`）を書く言語の BCP-47 コード（例: `ja`）
    required String uiLocale,

    /// 学習言語コード（[LanguageProfile.code]。例: `en` / `zh`）
    required String learningLanguage,

    /// 出題文（[uiLocale] の言語で書かれた原文）
    required String source,

    /// 模範解答（学習言語）
    required String modelAnswer,

    /// 学習者の発話（文字起こし）
    required String spoken,
  }) = _CorrectionRequest;
}

/// 添削結果（添削＋トークン使用量）。
@freezed
abstract class CorrectionResult with _$CorrectionResult {
  const factory CorrectionResult({
    required CompositionFeedback feedback,
    required TokenUsage usage,
  }) = _CorrectionResult;
}

/// 口頭作文の添削を行う Repository。
///
/// **次フェーズでサーバ実装に差し替わる継ぎ目。** 現在の実装は
/// `GeminiCorrectionRepository`（Gemini 直叩き。プロンプトとスキーマも持つ）で、
/// 次フェーズでは Rust バックエンドの REST 呼び出しに置き換える。
/// 失敗は [AppFailure] で表す。
abstract interface class CorrectionRepository {
  Future<CorrectionResult> correct(CorrectionRequest request);
}
