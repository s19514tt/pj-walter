import 'package:json_annotation/json_annotation.dart';

import '../domain/srs_item.dart';

part 'srs_item_dto.g.dart';

/// Hive `srs_items` box の1件。
@JsonSerializable()
class SrsItemDto {
  const SrsItemDto({
    required this.sentenceId,
    required this.language,
    required this.level,
    required this.stage,
    required this.dueDate,
    required this.lapses,
    required this.lastResult,
  });

  final String sentenceId;
  final String language;
  final int level;
  final int stage;

  /// ISO 8601
  final String dueDate;
  final int lapses;
  final bool lastResult;

  factory SrsItemDto.fromJson(Map<String, dynamic> json) =>
      _$SrsItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SrsItemDtoToJson(this);

  SrsItem toEntity() => SrsItem(
    sentenceId: sentenceId,
    language: language,
    level: level,
    stage: stage,
    dueDate: DateTime.parse(dueDate),
    lapses: lapses,
    lastResult: lastResult,
  );

  static SrsItemDto fromEntity(SrsItem item) => SrsItemDto(
    sentenceId: item.sentenceId,
    language: item.language,
    level: item.level,
    stage: item.stage,
    dueDate: item.dueDate.toIso8601String(),
    lapses: item.lapses,
    lastResult: item.lastResult,
  );
}
