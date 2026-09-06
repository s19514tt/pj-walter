import 'package:json_annotation/json_annotation.dart';

import '../domain/sentence.dart';

part 'sentence_dto.g.dart';

/// 教材JSON（`assets/data/{言語}/sentences_{level}.json`）の1文。
///
/// `level` はファイル側の共通値なので、読み込み側が [toEntity] に渡す。
@JsonSerializable()
class SentenceDto {
  const SentenceDto({
    required this.id,
    required this.ja,
    required this.target,
    required this.theme,
    required this.tips,
    this.reading,
  });

  final String id;
  final String ja;
  final String target;
  final String theme;
  final String tips;
  final String? reading;

  factory SentenceDto.fromJson(Map<String, dynamic> json) =>
      _$SentenceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SentenceDtoToJson(this);

  Sentence toEntity({required int level}) => Sentence(
    id: id,
    ja: ja,
    target: target,
    theme: theme,
    tips: tips,
    level: level,
    reading: reading,
  );
}
