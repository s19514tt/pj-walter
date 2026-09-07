// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drill_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WordUnitDto _$WordUnitDtoFromJson(Map<String, dynamic> json) => WordUnitDto(
  hanzi: json['hanzi'] as String,
  pinyin: json['pinyin'] as String?,
);

Map<String, dynamic> _$WordUnitDtoToJson(WordUnitDto instance) =>
    <String, dynamic>{'hanzi': instance.hanzi, 'pinyin': instance.pinyin};

CompositionFeedbackDto _$CompositionFeedbackDtoFromJson(
  Map<String, dynamic> json,
) => CompositionFeedbackDto(
  score: (json['score'] as num).toInt(),
  isAcceptable: json['is_acceptable'] as bool,
  corrected: json['corrected'] as String,
  explanation: json['explanation'] as String,
  comparison: json['comparison'] as String,
  correctedReading: json['corrected_reading'] as String?,
  correctedWords: (json['corrected_words'] as List<dynamic>?)
      ?.map((e) => WordUnitDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  spokenWords: (json['spoken_words'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$CompositionFeedbackDtoToJson(
  CompositionFeedbackDto instance,
) => <String, dynamic>{
  'score': instance.score,
  'is_acceptable': instance.isAcceptable,
  'corrected': instance.corrected,
  'explanation': instance.explanation,
  'comparison': instance.comparison,
  'corrected_reading': ?instance.correctedReading,
  'corrected_words': ?instance.correctedWords?.map((e) => e.toJson()).toList(),
  'spoken_words': ?instance.spokenWords,
};

ToneNoteDto _$ToneNoteDtoFromJson(Map<String, dynamic> json) => ToneNoteDto(
  index: (json['index'] as num).toInt(),
  spokenIndex: (json['spokenIndex'] as num).toInt(),
  expected: json['expected'] as String,
  actual: json['actual'] as String,
  expectedTone: (json['expectedTone'] as num).toInt(),
  actualTone: (json['actualTone'] as num).toInt(),
  hanzi: json['hanzi'] as String?,
);

Map<String, dynamic> _$ToneNoteDtoToJson(ToneNoteDto instance) =>
    <String, dynamic>{
      'index': instance.index,
      'spokenIndex': instance.spokenIndex,
      'expected': instance.expected,
      'actual': instance.actual,
      'expectedTone': instance.expectedTone,
      'actualTone': instance.actualTone,
      'hanzi': ?instance.hanzi,
    };

DrillResultDto _$DrillResultDtoFromJson(Map<String, dynamic> json) =>
    DrillResultDto(
      id: json['id'] as String,
      sentenceId: json['sentenceId'] as String,
      language: json['language'] as String,
      level: (json['level'] as num).toInt(),
      spoken: json['spoken'] as String,
      timestamp: json['timestamp'] as String,
      feedback: CompositionFeedbackDto.fromJson(
        json['feedback'] as Map<String, dynamic>,
      ),
      toneNotes: (json['toneNotes'] as List<dynamic>?)
          ?.map((e) => ToneNoteDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DrillResultDtoToJson(DrillResultDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sentenceId': instance.sentenceId,
      'language': instance.language,
      'level': instance.level,
      'spoken': instance.spoken,
      'timestamp': instance.timestamp,
      'feedback': instance.feedback.toJson(),
      'toneNotes': ?instance.toneNotes?.map((e) => e.toJson()).toList(),
    };
