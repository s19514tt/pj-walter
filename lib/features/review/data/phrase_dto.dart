import 'package:json_annotation/json_annotation.dart';

import '../domain/phrase.dart';

part 'phrase_dto.g.dart';

/// Hive `phrases` box の1件。
@JsonSerializable()
class PhraseDto {
  const PhraseDto({
    required this.id,
    required this.target,
    required this.ja,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String target;
  final String ja;
  final String source;

  /// ISO 8601
  final String createdAt;

  factory PhraseDto.fromJson(Map<String, dynamic> json) =>
      _$PhraseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PhraseDtoToJson(this);

  Phrase toEntity() => Phrase(
    id: id,
    target: target,
    ja: ja,
    source: source,
    createdAt: DateTime.parse(createdAt),
  );

  static PhraseDto fromEntity(Phrase phrase) => PhraseDto(
    id: phrase.id,
    target: phrase.target,
    ja: phrase.ja,
    source: phrase.source,
    createdAt: phrase.createdAt.toIso8601String(),
  );
}
