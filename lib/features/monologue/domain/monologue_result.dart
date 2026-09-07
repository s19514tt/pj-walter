import 'package:freezed_annotation/freezed_annotation.dart';

part 'monologue_result.freezed.dart';

/// 独り言トレーニングの添削で指摘された1件の修正（原文→修正文＋理由）。
@freezed
abstract class Correction with _$Correction {
  const factory Correction({
    required String original,
    required String corrected,

    /// 修正の理由（`uiLocale` の言語）
    required String reason,
  }) = _Correction;
}

/// 独り言トレーニングで提案される「次回使える表現」。
@freezed
abstract class UsefulPhrase with _$UsefulPhrase {
  const factory UsefulPhrase({
    /// 学習言語での表現
    required String target,

    /// 日本語訳（`uiLocale` の言語）
    required String ja,
  }) = _UsefulPhrase;
}

/// 独り言トレーニング1回分のフィードバック。
@freezed
abstract class MonologueFeedback with _$MonologueFeedback {
  const factory MonologueFeedback({
    /// 流暢さスコア（0-100）
    required int fluencyScore,

    /// 全文を自然な学習言語の文に直したもの
    required String correctedTranscript,

    /// 個別の修正点一覧
    required List<Correction> corrections,

    /// 次回使える表現（3-5個）
    required List<UsefulPhrase> usefulPhrases,

    /// 良かった点・改善点の総評（`uiLocale` の言語）
    required String overallFeedback,
  }) = _MonologueFeedback;
}

/// 独り言トレーニング1回分の結果（発話内容＋フィードバック）。
@freezed
abstract class MonologueResult with _$MonologueResult {
  const factory MonologueResult({
    /// 結果のuuid
    required String id,

    /// 出題されたお題のid
    required String topicId,

    /// お題の学習言語コード（[LanguageProfile.code]）
    required String language,

    /// 発話時間（秒）
    required int seconds,

    /// 音声認識で得られた発話の文字起こし
    required String transcript,

    /// 実施日時
    required DateTime timestamp,

    /// フィードバック
    required MonologueFeedback feedback,
  }) = _MonologueResult;
}
