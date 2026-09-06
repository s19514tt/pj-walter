import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/token_usage.dart';
import 'monologue_result.dart';

part 'monologue_review_repository.freezed.dart';

/// 独り言1回分のフィードバックリクエスト。
///
/// [uiLocale]（解説を書く言語）と [learningLanguage]（採点対象の言語）を別々に持つ。
@freezed
abstract class MonologueReviewRequest with _$MonologueReviewRequest {
  const factory MonologueReviewRequest({
    /// 解説（`reason` / `overall_feedback` / `ja`）を書く言語の BCP-47 コード
    required String uiLocale,

    /// 学習言語コード（[LanguageProfile.code]）
    required String learningLanguage,

    /// お題（[uiLocale] の言語）
    required String topicSource,

    /// お題（学習言語）
    required String topicTarget,

    /// 発話時間（秒）
    required int seconds,

    /// 発話の文字起こし
    required String transcript,
  }) = _MonologueReviewRequest;
}

/// フィードバック結果（フィードバック＋トークン使用量）。
@freezed
abstract class MonologueReviewResult with _$MonologueReviewResult {
  const factory MonologueReviewResult({
    required MonologueFeedback feedback,
    required TokenUsage usage,
  }) = _MonologueReviewResult;
}

/// 独り言トレーニングのフィードバックを行う Repository。
///
/// **次フェーズでサーバ実装に差し替わる継ぎ目。** 現在の実装は
/// `GeminiMonologueReviewRepository`（Gemini 直叩き。プロンプトとスキーマも持つ）。
/// 失敗は [AppFailure] で表す。
abstract interface class MonologueReviewRepository {
  Future<MonologueReviewResult> review(MonologueReviewRequest request);
}
