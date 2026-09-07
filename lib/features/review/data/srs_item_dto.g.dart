// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsItemDto _$SrsItemDtoFromJson(Map<String, dynamic> json) => SrsItemDto(
  sentenceId: json['sentenceId'] as String,
  language: json['language'] as String,
  level: (json['level'] as num).toInt(),
  stage: (json['stage'] as num).toInt(),
  dueDate: json['dueDate'] as String,
  lapses: (json['lapses'] as num).toInt(),
  lastResult: json['lastResult'] as bool,
);

Map<String, dynamic> _$SrsItemDtoToJson(SrsItemDto instance) =>
    <String, dynamic>{
      'sentenceId': instance.sentenceId,
      'language': instance.language,
      'level': instance.level,
      'stage': instance.stage,
      'dueDate': instance.dueDate,
      'lapses': instance.lapses,
      'lastResult': instance.lastResult,
    };
