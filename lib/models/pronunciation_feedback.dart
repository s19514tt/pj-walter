import 'package:flutter/foundation.dart';

/// 発音評価における単語1つ分の結果。
///
/// JSONキーはGemini APIのレスポンススキーマ（DESIGN.md参照）に合わせて
/// スネークケースとしている。
@immutable
class WordPronunciation {
  const WordPronunciation({
    required this.word,
    required this.score,
    required this.issueJa,
  });

  /// 評価対象の単語（発話の文字起こしと同じ表記）
  final String word;

  /// その単語の発音スコア（0-100）
  final int score;

  /// 発音上の問題点（日本語）。問題がなければ空文字
  final String issueJa;

  /// 問題点の指摘があるかどうか
  bool get hasIssue => issueJa.isNotEmpty;

  factory WordPronunciation.fromJson(Map<String, dynamic> json) =>
      WordPronunciation(
        word: json['word'] as String,
        score: (json['score'] as num).toInt(),
        issueJa: (json['issue_ja'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
    'word': word,
    'score': score,
    'issue_ja': issueJa,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordPronunciation &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          score == other.score &&
          issueJa == other.issueJa;

  @override
  int get hashCode => Object.hash(word, score, issueJa);
}

/// 口頭英作文1問分の発音評価結果（Gemini音声マルチモーダルによる採点）。
@immutable
class PronunciationFeedback {
  const PronunciationFeedback({
    required this.score,
    required this.words,
    required this.adviceJa,
  });

  /// 発音の総合スコア（0-100）。明瞭さ・個々の音・強勢・リズムを総合した値
  final int score;

  /// 単語ごとの評価（発話の語順どおり）
  final List<WordPronunciation> words;

  /// 次に意識すべきポイントのアドバイス（日本語、2〜3文）
  final String adviceJa;

  /// 指摘のある単語だけを返す。
  List<WordPronunciation> get problemWords =>
      words.where((w) => w.hasIssue).toList();

  factory PronunciationFeedback.fromJson(Map<String, dynamic> json) =>
      PronunciationFeedback(
        score: (json['score'] as num).toInt(),
        words: [
          for (final item in (json['words'] as List? ?? const []))
            WordPronunciation.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        adviceJa: json['advice_ja'] as String,
      );

  Map<String, dynamic> toJson() => {
    'score': score,
    'words': [for (final w in words) w.toJson()],
    'advice_ja': adviceJa,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PronunciationFeedback &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          listEquals(words, other.words) &&
          adviceJa == other.adviceJa;

  @override
  int get hashCode => Object.hash(score, Object.hashAll(words), adviceJa);
}
