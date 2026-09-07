// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentence_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SentenceDto _$SentenceDtoFromJson(Map<String, dynamic> json) => SentenceDto(
  id: json['id'] as String,
  ja: json['ja'] as String,
  target: json['target'] as String,
  theme: json['theme'] as String,
  tips: json['tips'] as String,
  reading: json['reading'] as String?,
);

Map<String, dynamic> _$SentenceDtoToJson(SentenceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ja': instance.ja,
      'target': instance.target,
      'theme': instance.theme,
      'tips': instance.tips,
      'reading': instance.reading,
    };
