import 'package:json_annotation/json_annotation.dart';

import '../domain/topic.dart';

part 'topic_dto.g.dart';

/// お題JSON（`assets/data/{言語}/topics.json`）の1件。
@JsonSerializable()
class TopicDto {
  const TopicDto({
    required this.id,
    required this.ja,
    required this.target,
    required this.theme,
    this.reading,
  });

  final String id;
  final String ja;
  final String target;
  final String theme;
  final String? reading;

  factory TopicDto.fromJson(Map<String, dynamic> json) =>
      _$TopicDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TopicDtoToJson(this);

  Topic toEntity() =>
      Topic(id: id, ja: ja, target: target, theme: theme, reading: reading);
}
