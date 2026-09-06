import 'package:json_annotation/json_annotation.dart';

import '../domain/monologue_result.dart';

part 'monologue_result_dto.g.dart';

/// 修正1件（フィードバック API の応答スキーマ）。
@JsonSerializable()
class CorrectionDto {
  const CorrectionDto({
    required this.original,
    required this.corrected,
    required this.reason,
  });

  final String original;
  final String corrected;
  final String reason;

  factory CorrectionDto.fromJson(Map<String, dynamic> json) =>
      _$CorrectionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CorrectionDtoToJson(this);

  Correction toEntity() =>
      Correction(original: original, corrected: corrected, reason: reason);

  static CorrectionDto fromEntity(Correction c) => CorrectionDto(
    original: c.original,
    corrected: c.corrected,
    reason: c.reason,
  );
}

/// 次回使える表現1件（フィードバック API の応答スキーマ）。
@JsonSerializable()
class UsefulPhraseDto {
  const UsefulPhraseDto({required this.target, required this.ja});

  final String target;
  final String ja;

  factory UsefulPhraseDto.fromJson(Map<String, dynamic> json) =>
      _$UsefulPhraseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UsefulPhraseDtoToJson(this);

  UsefulPhrase toEntity() => UsefulPhrase(target: target, ja: ja);

  static UsefulPhraseDto fromEntity(UsefulPhrase p) =>
      UsefulPhraseDto(target: p.target, ja: p.ja);
}

/// 独り言のフィードバック。**フィードバック API の応答スキーマそのもの**で、
/// Hive の `monologue_results` にもこの形で保存する。
@JsonSerializable(fieldRename: FieldRename.snake)
class MonologueFeedbackDto {
  const MonologueFeedbackDto({
    required this.fluencyScore,
    required this.correctedTranscript,
    required this.corrections,
    required this.usefulPhrases,
    required this.overallFeedback,
  });

  final int fluencyScore;
  final String correctedTranscript;
  final List<CorrectionDto> corrections;
  final List<UsefulPhraseDto> usefulPhrases;
  final String overallFeedback;

  factory MonologueFeedbackDto.fromJson(Map<String, dynamic> json) =>
      _$MonologueFeedbackDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MonologueFeedbackDtoToJson(this);

  MonologueFeedback toEntity() => MonologueFeedback(
    fluencyScore: fluencyScore,
    correctedTranscript: correctedTranscript,
    corrections: corrections.map((c) => c.toEntity()).toList(),
    usefulPhrases: usefulPhrases.map((p) => p.toEntity()).toList(),
    overallFeedback: overallFeedback,
  );

  static MonologueFeedbackDto fromEntity(MonologueFeedback f) =>
      MonologueFeedbackDto(
        fluencyScore: f.fluencyScore,
        correctedTranscript: f.correctedTranscript,
        corrections: f.corrections.map(CorrectionDto.fromEntity).toList(),
        usefulPhrases: f.usefulPhrases.map(UsefulPhraseDto.fromEntity).toList(),
        overallFeedback: f.overallFeedback,
      );
}

/// Hive `monologue_results` box の1件。
@JsonSerializable()
class MonologueResultDto {
  const MonologueResultDto({
    required this.id,
    required this.topicId,
    required this.language,
    required this.seconds,
    required this.transcript,
    required this.timestamp,
    required this.feedback,
  });

  final String id;
  final String topicId;
  final String language;
  final int seconds;
  final String transcript;

  /// ISO 8601
  final String timestamp;
  final MonologueFeedbackDto feedback;

  factory MonologueResultDto.fromJson(Map<String, dynamic> json) =>
      _$MonologueResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MonologueResultDtoToJson(this);

  MonologueResult toEntity() => MonologueResult(
    id: id,
    topicId: topicId,
    language: language,
    seconds: seconds,
    transcript: transcript,
    timestamp: DateTime.parse(timestamp),
    feedback: feedback.toEntity(),
  );

  static MonologueResultDto fromEntity(MonologueResult r) => MonologueResultDto(
    id: r.id,
    topicId: r.topicId,
    language: r.language,
    seconds: r.seconds,
    transcript: r.transcript,
    timestamp: r.timestamp.toIso8601String(),
    feedback: MonologueFeedbackDto.fromEntity(r.feedback),
  );
}
