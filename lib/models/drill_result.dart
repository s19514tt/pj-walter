import 'package:flutter/foundation.dart';

/// 口頭英作文1問分のGemini添削結果。
///
/// JSONキーはGemini APIのレスポンススキーマ（DESIGN.md参照）に合わせて
/// スネークケースとしている。
@immutable
class CompositionFeedback {
  const CompositionFeedback({
    required this.score,
    required this.isAcceptable,
    required this.corrected,
    required this.explanationJa,
    required this.comparisonJa,
  });

  /// 伝わりやすさ・正確さの総合スコア（0-100）
  final int score;

  /// score>=70相当の合否
  final bool isAcceptable;

  /// 発話を最小修正した英文
  final String corrected;

  /// 誤りの解説（日本語）
  final String explanationJa;

  /// 模範解答との違い・どちらでも良い点の解説（日本語）
  final String comparisonJa;

  factory CompositionFeedback.fromJson(Map<String, dynamic> json) =>
      CompositionFeedback(
        score: (json['score'] as num).toInt(),
        isAcceptable: json['is_acceptable'] as bool,
        corrected: json['corrected'] as String,
        explanationJa: json['explanation_ja'] as String,
        comparisonJa: json['comparison_ja'] as String,
      );

  Map<String, dynamic> toJson() => {
    'score': score,
    'is_acceptable': isAcceptable,
    'corrected': corrected,
    'explanation_ja': explanationJa,
    'comparison_ja': comparisonJa,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompositionFeedback &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          isAcceptable == other.isAcceptable &&
          corrected == other.corrected &&
          explanationJa == other.explanationJa &&
          comparisonJa == other.comparisonJa;

  @override
  int get hashCode =>
      Object.hash(score, isAcceptable, corrected, explanationJa, comparisonJa);
}

/// 口頭英作文1問分の受験結果（発話内容＋Gemini添削結果）。
@immutable
class DrillResult {
  const DrillResult({
    required this.id,
    required this.sentenceId,
    required this.level,
    required this.spoken,
    required this.timestamp,
    required this.feedback,
  });

  /// 結果のuuid
  final String id;

  /// 出題された [Sentence] のid
  final String sentenceId;

  /// 出題文のTOEICレベル
  final int level;

  /// 音声認識で得られたユーザーの発話文
  final String spoken;

  /// 受験日時
  final DateTime timestamp;

  /// Geminiによる添削結果
  final CompositionFeedback feedback;

  factory DrillResult.fromJson(Map<String, dynamic> json) => DrillResult(
    id: json['id'] as String,
    sentenceId: json['sentenceId'] as String,
    level: (json['level'] as num).toInt(),
    spoken: json['spoken'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    feedback: CompositionFeedback.fromJson(
      Map<String, dynamic>.from(json['feedback'] as Map),
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sentenceId': sentenceId,
    'level': level,
    'spoken': spoken,
    'timestamp': timestamp.toIso8601String(),
    'feedback': feedback.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrillResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sentenceId == other.sentenceId &&
          level == other.level &&
          spoken == other.spoken &&
          timestamp == other.timestamp &&
          feedback == other.feedback;

  @override
  int get hashCode =>
      Object.hash(id, sentenceId, level, spoken, timestamp, feedback);
}
