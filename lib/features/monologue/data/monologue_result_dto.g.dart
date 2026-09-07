// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monologue_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CorrectionDto _$CorrectionDtoFromJson(Map<String, dynamic> json) =>
    CorrectionDto(
      original: json['original'] as String,
      corrected: json['corrected'] as String,
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$CorrectionDtoToJson(CorrectionDto instance) =>
    <String, dynamic>{
      'original': instance.original,
      'corrected': instance.corrected,
      'reason': instance.reason,
    };

UsefulPhraseDto _$UsefulPhraseDtoFromJson(Map<String, dynamic> json) =>
    UsefulPhraseDto(target: json['target'] as String, ja: json['ja'] as String);

Map<String, dynamic> _$UsefulPhraseDtoToJson(UsefulPhraseDto instance) =>
    <String, dynamic>{'target': instance.target, 'ja': instance.ja};

MonologueFeedbackDto _$MonologueFeedbackDtoFromJson(
  Map<String, dynamic> json,
) => MonologueFeedbackDto(
  fluencyScore: (json['fluency_score'] as num).toInt(),
  correctedTranscript: json['corrected_transcript'] as String,
  corrections: (json['corrections'] as List<dynamic>)
      .map((e) => CorrectionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  usefulPhrases: (json['useful_phrases'] as List<dynamic>)
      .map((e) => UsefulPhraseDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  overallFeedback: json['overall_feedback'] as String,
);

Map<String, dynamic> _$MonologueFeedbackDtoToJson(
  MonologueFeedbackDto instance,
) => <String, dynamic>{
  'fluency_score': instance.fluencyScore,
  'corrected_transcript': instance.correctedTranscript,
  'corrections': instance.corrections.map((e) => e.toJson()).toList(),
  'useful_phrases': instance.usefulPhrases.map((e) => e.toJson()).toList(),
  'overall_feedback': instance.overallFeedback,
};

MonologueResultDto _$MonologueResultDtoFromJson(Map<String, dynamic> json) =>
    MonologueResultDto(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      language: json['language'] as String,
      seconds: (json['seconds'] as num).toInt(),
      transcript: json['transcript'] as String,
      timestamp: json['timestamp'] as String,
      feedback: MonologueFeedbackDto.fromJson(
        json['feedback'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$MonologueResultDtoToJson(MonologueResultDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'topicId': instance.topicId,
      'language': instance.language,
      'seconds': instance.seconds,
      'transcript': instance.transcript,
      'timestamp': instance.timestamp,
      'feedback': instance.feedback.toJson(),
    };
