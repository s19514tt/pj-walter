// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phrase_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhraseDto _$PhraseDtoFromJson(Map<String, dynamic> json) => PhraseDto(
  id: json['id'] as String,
  target: json['target'] as String,
  ja: json['ja'] as String,
  source: json['source'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$PhraseDtoToJson(PhraseDto instance) => <String, dynamic>{
  'id': instance.id,
  'target': instance.target,
  'ja': instance.ja,
  'source': instance.source,
  'createdAt': instance.createdAt,
};
