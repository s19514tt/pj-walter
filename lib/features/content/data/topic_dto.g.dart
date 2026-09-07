// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopicDto _$TopicDtoFromJson(Map<String, dynamic> json) => TopicDto(
  id: json['id'] as String,
  ja: json['ja'] as String,
  target: json['target'] as String,
  theme: json['theme'] as String,
  reading: json['reading'] as String?,
);

Map<String, dynamic> _$TopicDtoToJson(TopicDto instance) => <String, dynamic>{
  'id': instance.id,
  'ja': instance.ja,
  'target': instance.target,
  'theme': instance.theme,
  'reading': instance.reading,
};
