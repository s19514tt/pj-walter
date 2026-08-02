import 'package:flutter/foundation.dart';

/// 独り言英会話の添削で指摘された1件の修正（原文→修正文＋理由）。
@immutable
class Correction {
  const Correction({
    required this.original,
    required this.corrected,
    required this.reasonJa,
  });

  final String original;
  final String corrected;
  final String reasonJa;

  factory Correction.fromJson(Map<String, dynamic> json) => Correction(
    original: json['original'] as String,
    corrected: json['corrected'] as String,
    reasonJa: json['reason_ja'] as String,
  );

  Map<String, dynamic> toJson() => {
    'original': original,
    'corrected': corrected,
    'reason_ja': reasonJa,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Correction &&
          runtimeType == other.runtimeType &&
          original == other.original &&
          corrected == other.corrected &&
          reasonJa == other.reasonJa;

  @override
  int get hashCode => Object.hash(original, corrected, reasonJa);
}

/// 独り言英会話で提案される「次回使える表現」。
@immutable
class UsefulPhrase {
  const UsefulPhrase({required this.en, required this.ja});

  final String en;
  final String ja;

  factory UsefulPhrase.fromJson(Map<String, dynamic> json) =>
      UsefulPhrase(en: json['en'] as String, ja: json['ja'] as String);

  Map<String, dynamic> toJson() => {'en': en, 'ja': ja};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsefulPhrase &&
          runtimeType == other.runtimeType &&
          en == other.en &&
          ja == other.ja;

  @override
  int get hashCode => Object.hash(en, ja);
}

/// 独り言英会話1回分のGeminiフィードバック。
///
/// JSONキーはGemini APIのレスポンススキーマ（DESIGN.md参照）に合わせて
/// スネークケースとしている。
@immutable
class MonologueFeedback {
  const MonologueFeedback({
    required this.fluencyScore,
    required this.correctedTranscript,
    required this.corrections,
    required this.usefulPhrases,
    required this.overallFeedbackJa,
  });

  /// 流暢さスコア（0-100）
  final int fluencyScore;

  /// 全文を自然な英語に直したもの
  final String correctedTranscript;

  /// 個別の修正点一覧
  final List<Correction> corrections;

  /// 次回使える表現（3-5個）
  final List<UsefulPhrase> usefulPhrases;

  /// 良かった点・改善点の総評（日本語）
  final String overallFeedbackJa;

  factory MonologueFeedback.fromJson(
    Map<String, dynamic> json,
  ) => MonologueFeedback(
    fluencyScore: (json['fluency_score'] as num).toInt(),
    correctedTranscript: json['corrected_transcript'] as String,
    corrections: (json['corrections'] as List)
        .map((e) => Correction.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    usefulPhrases: (json['useful_phrases'] as List)
        .map((e) => UsefulPhrase.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    overallFeedbackJa: json['overall_feedback_ja'] as String,
  );

  Map<String, dynamic> toJson() => {
    'fluency_score': fluencyScore,
    'corrected_transcript': correctedTranscript,
    'corrections': corrections.map((e) => e.toJson()).toList(),
    'useful_phrases': usefulPhrases.map((e) => e.toJson()).toList(),
    'overall_feedback_ja': overallFeedbackJa,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonologueFeedback &&
          runtimeType == other.runtimeType &&
          fluencyScore == other.fluencyScore &&
          correctedTranscript == other.correctedTranscript &&
          listEquals(corrections, other.corrections) &&
          listEquals(usefulPhrases, other.usefulPhrases) &&
          overallFeedbackJa == other.overallFeedbackJa;

  @override
  int get hashCode => Object.hash(
    fluencyScore,
    correctedTranscript,
    Object.hashAll(corrections),
    Object.hashAll(usefulPhrases),
    overallFeedbackJa,
  );
}

/// 独り言英会話1回分の結果（発話内容＋Geminiフィードバック）。
@immutable
class MonologueResult {
  const MonologueResult({
    required this.id,
    required this.topicId,
    required this.seconds,
    required this.transcript,
    required this.timestamp,
    required this.feedback,
  });

  /// 結果のuuid
  final String id;

  /// 出題されたお題のid
  final String topicId;

  /// 発話時間（秒）
  final int seconds;

  /// 音声認識で得られた発話の文字起こし
  final String transcript;

  /// 実施日時
  final DateTime timestamp;

  /// Geminiによるフィードバック
  final MonologueFeedback feedback;

  factory MonologueResult.fromJson(Map<String, dynamic> json) =>
      MonologueResult(
        id: json['id'] as String,
        topicId: json['topicId'] as String,
        seconds: (json['seconds'] as num).toInt(),
        transcript: json['transcript'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        feedback: MonologueFeedback.fromJson(
          Map<String, dynamic>.from(json['feedback'] as Map),
        ),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'topicId': topicId,
    'seconds': seconds,
    'transcript': transcript,
    'timestamp': timestamp.toIso8601String(),
    'feedback': feedback.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonologueResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          topicId == other.topicId &&
          seconds == other.seconds &&
          transcript == other.transcript &&
          timestamp == other.timestamp &&
          feedback == other.feedback;

  @override
  int get hashCode =>
      Object.hash(id, topicId, seconds, transcript, timestamp, feedback);
}
