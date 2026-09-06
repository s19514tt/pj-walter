import 'package:flutter/foundation.dart';

import 'tone_note.dart';

/// 語区切り1件（中国語の添削応答が返す「単語」）。
///
/// 差分表示のハイライトを1文字ずつではなく単語ずつの箱にするために使う。
/// [reading]は修正版のみ（その語のピンイン）で、発話側は null。
@immutable
class WordUnit {
  const WordUnit({required this.text, this.reading});

  /// 語の表記（句読点だけの語もある）
  final String text;

  /// その語の標準的なピンイン（音節ごとに半角スペース区切り）。発話側は null
  final String? reading;

  factory WordUnit.fromJson(Map<String, dynamic> json) => WordUnit(
    text: json['hanzi'] as String,
    reading: json['pinyin'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'hanzi': text,
    if (reading != null) 'pinyin': reading,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordUnit && text == other.text && reading == other.reading;

  @override
  int get hashCode => Object.hash(text, reading);

  @override
  String toString() => 'WordUnit($text${reading == null ? '' : ' / $reading'})';
}

/// 口頭英作文1問分のGemini添削結果。
///
/// JSONキーはGemini APIのレスポンススキーマ（DESIGN.md参照）に合わせて
/// スネークケースとしている。
@immutable
class CompositionFeedback {
  const CompositionFeedback({
    required this.score,
    required this.isAcceptable,
    required this.corrected,
    required this.explanationJa,
    required this.comparisonJa,
    this.correctedReading,
    this.correctedWords,
    this.spokenWords,
  });

  /// 伝わりやすさ・正確さの総合スコア（0-100）
  final int score;

  /// score>=70相当の合否
  final bool isAcceptable;

  /// 発話を最小修正した英文
  final String corrected;

  /// 誤りの解説（日本語）
  final String explanationJa;

  /// 模範解答との違い・どちらでも良い点の解説（日本語）
  final String comparisonJa;

  /// [corrected]の標準的なピンイン（中国語のみ。修正版のルビ表示に使う）。
  /// 英語や旧データでは null。[correctedWords]があるときはそれを繋いだもの。
  final String? correctedReading;

  /// [corrected]の語区切り＋語ごとのピンイン（中国語のみ。英語や旧データでは null）。
  ///
  /// 差分のハイライトを単語ずつの箱にするのと、ルビを語ごとに割り当てるのに使う
  /// （語ごとなら音節数が合わない語だけルビを落とせる）。
  final List<WordUnit>? correctedWords;

  /// 生徒の発話（文字起こし）の語区切り（中国語のみ。ピンインは持たない）。
  final List<WordUnit>? spokenWords;

  factory CompositionFeedback.fromJson(Map<String, dynamic> json) =>
      CompositionFeedback(
        score: (json['score'] as num).toInt(),
        isAcceptable: json['is_acceptable'] as bool,
        corrected: json['corrected'] as String,
        explanationJa: json['explanation_ja'] as String,
        comparisonJa: json['comparison_ja'] as String,
        correctedReading:
            json['corrected_reading'] as String? ??
            _joinReadings(_wordUnits(json['corrected_words'])),
        correctedWords: _wordUnits(json['corrected_words']),
        spokenWords: _wordUnits(json['spoken_words']),
      );

  /// 語区切りの配列を読む。修正版は`{hanzi, pinyin}`のオブジェクト、
  /// 発話側は文字列だけの配列で返る（どちらの形も読めるようにしておく）。
  static List<WordUnit>? _wordUnits(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    return [
      for (final e in raw)
        if (e is String)
          WordUnit(text: e)
        else
          WordUnit.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
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

  Map<String, dynamic> toJson() => {
    'score': score,
    'is_acceptable': isAcceptable,
    'corrected': corrected,
    'explanation_ja': explanationJa,
    'comparison_ja': comparisonJa,
    'corrected_reading': correctedReading,
    'corrected_words': correctedWords?.map((w) => w.toJson()).toList(),
    'spoken_words': spokenWords?.map((w) => w.text).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompositionFeedback &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          isAcceptable == other.isAcceptable &&
          corrected == other.corrected &&
          explanationJa == other.explanationJa &&
          comparisonJa == other.comparisonJa &&
          correctedReading == other.correctedReading &&
          listEquals(correctedWords, other.correctedWords) &&
          listEquals(spokenWords, other.spokenWords);

  @override
  int get hashCode => Object.hash(
    score,
    isAcceptable,
    corrected,
    explanationJa,
    comparisonJa,
    correctedReading,
    correctedWords == null ? null : Object.hashAll(correctedWords!),
    spokenWords == null ? null : Object.hashAll(spokenWords!),
  );
}

/// 口頭英作文1問分の受験結果（発話内容＋Gemini添削結果）。
@immutable
class DrillResult {
  const DrillResult({
    required this.id,
    required this.sentenceId,
    required this.language,
    required this.level,
    required this.spoken,
    required this.timestamp,
    required this.feedback,
    this.toneNotes,
  });

  /// 結果のuuid
  final String id;

  /// 出題された [Sentence] のid
  final String sentenceId;

  /// 出題文の学習言語コード（[LanguageProfile.code]）
  final String language;

  /// 出題文のTOEICレベル
  final int level;

  /// 音声認識で得られたユーザーの発話文
  final String spoken;

  /// 受験日時
  final DateTime timestamp;

  /// Geminiによる添削結果
  final CompositionFeedback feedback;

  /// 声調の「気づいた点」（中国語のみ。DESIGN.md「声調フィードバック」参照）。
  ///
  /// null は判定していない（英語・模範解答にピンインが無い・音節列が模範解答と
  /// 一致しなかった）。空リストは判定したが指摘なし。中国語対応より前に保存された
  /// 結果もキーが無いため null で読める。スコアには一切影響しない。
  final List<ToneNote>? toneNotes;

  factory DrillResult.fromJson(Map<String, dynamic> json) => DrillResult(
    id: json['id'] as String,
    sentenceId: json['sentenceId'] as String,
    // languageが無いのは中国語対応より前に保存された結果。英語とみなす。
    language: (json['language'] as String?) ?? 'en',
    level: (json['level'] as num).toInt(),
    spoken: json['spoken'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    feedback: CompositionFeedback.fromJson(
      Map<String, dynamic>.from(json['feedback'] as Map),
    ),
    toneNotes: (json['toneNotes'] as List?)
        ?.map((e) => ToneNote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sentenceId': sentenceId,
    'language': language,
    'level': level,
    'spoken': spoken,
    'timestamp': timestamp.toIso8601String(),
    'feedback': feedback.toJson(),
    'toneNotes': toneNotes?.map((note) => note.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrillResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sentenceId == other.sentenceId &&
          language == other.language &&
          level == other.level &&
          spoken == other.spoken &&
          timestamp == other.timestamp &&
          feedback == other.feedback &&
          listEquals(toneNotes, other.toneNotes);

  @override
  int get hashCode => Object.hash(
    id,
    sentenceId,
    language,
    level,
    spoken,
    timestamp,
    feedback,
    toneNotes == null ? null : Object.hashAll(toneNotes!),
  );
}
