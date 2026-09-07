import 'package:json_annotation/json_annotation.dart';

import '../domain/drill_result.dart';
import '../domain/tone_note.dart';

part 'drill_result_dto.g.dart';

/// 添削応答の語区切り1件（`{hanzi, pinyin}`）。
@JsonSerializable()
class WordUnitDto {
  const WordUnitDto({required this.hanzi, this.pinyin});

  final String hanzi;
  final String? pinyin;

  factory WordUnitDto.fromJson(Map<String, dynamic> json) =>
      _$WordUnitDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WordUnitDtoToJson(this);

  WordUnit toEntity() => WordUnit(text: hanzi, reading: pinyin);

  static WordUnitDto fromEntity(WordUnit unit) =>
      WordUnitDto(hanzi: unit.text, pinyin: unit.reading);
}

/// 口頭作文の添削結果。**添削 API の応答スキーマそのもの**（DESIGN.md「Gemini API契約」）で、
/// Hive の `drill_results` にもこの形で保存する。
///
/// キーはスネークケース。解説文のキーに言語名は付けない（`explanation` / `comparison`。
/// 何語で書くかはリクエストの `uiLocale` が決める）。
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class CompositionFeedbackDto {
  const CompositionFeedbackDto({
    required this.score,
    required this.isAcceptable,
    required this.corrected,
    required this.explanation,
    required this.comparison,
    this.correctedReading,
    this.correctedWords,
    this.spokenWords,
  });

  final int score;
  final bool isAcceptable;
  final String corrected;
  final String explanation;
  final String comparison;
  final String? correctedReading;

  /// 修正版の語区切り（語ごとのピンイン付き）
  final List<WordUnitDto>? correctedWords;

  /// 発話の語区切り（文字列だけ）
  final List<String>? spokenWords;

  factory CompositionFeedbackDto.fromJson(Map<String, dynamic> json) =>
      _$CompositionFeedbackDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CompositionFeedbackDtoToJson(this);

  CompositionFeedback toEntity() {
    final words = correctedWords?.map((w) => w.toEntity()).toList();
    return CompositionFeedback(
      score: score,
      isAcceptable: isAcceptable,
      corrected: corrected,
      explanation: explanation,
      comparison: comparison,
      // 文全体の読みが無ければ語ごとのピンインを繋ぐ（語区切りが使えないときの
      // フォールバックとして残している）
      correctedReading: correctedReading ?? _joinReadings(words),
      correctedWords: _nullIfEmpty(words),
      spokenWords: _nullIfEmpty(spokenWords?.map((w) => WordUnit(text: w))),
    );
  }

  static CompositionFeedbackDto fromEntity(CompositionFeedback feedback) =>
      CompositionFeedbackDto(
        score: feedback.score,
        isAcceptable: feedback.isAcceptable,
        corrected: feedback.corrected,
        explanation: feedback.explanation,
        comparison: feedback.comparison,
        correctedReading: feedback.correctedReading,
        correctedWords: feedback.correctedWords
            ?.map(WordUnitDto.fromEntity)
            .toList(),
        spokenWords: feedback.spokenWords?.map((w) => w.text).toList(),
      );

  static List<WordUnit>? _nullIfEmpty(Iterable<WordUnit>? words) {
    if (words == null) return null;
    final list = words.toList();
    return list.isEmpty ? null : list;
  }

  /// 語ごとのピンインを1つの文字列に繋ぐ（ピンインの無い語＝句読点は飛ばす）。
  static String? _joinReadings(List<WordUnit>? words) {
    if (words == null) return null;
    final readings = [
      for (final word in words)
        if (word.reading != null && word.reading!.trim().isNotEmpty)
          word.reading!.trim(),
    ];
    return readings.isEmpty ? null : readings.join(' ');
  }
}

/// 声調の気づき1件の保存形式。
@JsonSerializable(includeIfNull: false)
class ToneNoteDto {
  const ToneNoteDto({
    required this.index,
    required this.spokenIndex,
    required this.expected,
    required this.actual,
    required this.expectedTone,
    required this.actualTone,
    this.hanzi,
  });

  final int index;
  final int spokenIndex;
  final String expected;
  final String actual;
  final int expectedTone;
  final int actualTone;
  final String? hanzi;

  factory ToneNoteDto.fromJson(Map<String, dynamic> json) =>
      _$ToneNoteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ToneNoteDtoToJson(this);

  ToneNote toEntity() => ToneNote(
    index: index,
    spokenIndex: spokenIndex,
    expected: expected,
    actual: actual,
    expectedTone: expectedTone,
    actualTone: actualTone,
    hanzi: hanzi,
  );

  static ToneNoteDto fromEntity(ToneNote note) => ToneNoteDto(
    index: note.index,
    spokenIndex: note.spokenIndex,
    expected: note.expected,
    actual: note.actual,
    expectedTone: note.expectedTone,
    actualTone: note.actualTone,
    hanzi: note.hanzi,
  );
}

/// Hive `drill_results` box の1件。
@JsonSerializable(includeIfNull: false)
class DrillResultDto {
  const DrillResultDto({
    required this.id,
    required this.sentenceId,
    required this.language,
    required this.level,
    required this.spoken,
    required this.timestamp,
    required this.feedback,
    this.toneNotes,
  });

  final String id;
  final String sentenceId;
  final String language;
  final int level;
  final String spoken;

  /// ISO 8601
  final String timestamp;
  final CompositionFeedbackDto feedback;
  final List<ToneNoteDto>? toneNotes;

  factory DrillResultDto.fromJson(Map<String, dynamic> json) =>
      _$DrillResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DrillResultDtoToJson(this);

  DrillResult toEntity() => DrillResult(
    id: id,
    sentenceId: sentenceId,
    language: language,
    level: level,
    spoken: spoken,
    timestamp: DateTime.parse(timestamp),
    feedback: feedback.toEntity(),
    toneNotes: toneNotes?.map((n) => n.toEntity()).toList(),
  );

  static DrillResultDto fromEntity(DrillResult result) => DrillResultDto(
    id: result.id,
    sentenceId: result.sentenceId,
    language: result.language,
    level: result.level,
    spoken: result.spoken,
    timestamp: result.timestamp.toIso8601String(),
    feedback: CompositionFeedbackDto.fromEntity(result.feedback),
    toneNotes: result.toneNotes?.map(ToneNoteDto.fromEntity).toList(),
  );
}
