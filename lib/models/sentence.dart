import 'package:flutter/foundation.dart';

/// 教材の1文（口頭英作文で出題される日本語文と模範英訳）。
@immutable
class Sentence {
  const Sentence({
    required this.id,
    required this.ja,
    required this.en,
    required this.theme,
    required this.tips,
    required this.level,
  });

  /// `s{level}-{連番3桁}` 形式のID（例: `s700-001`）
  final String id;

  /// 出題される日本語原文
  final String ja;

  /// 模範解答の英文
  final String en;

  /// テーマ（`daily` / `business` / `travel`）
  final String theme;

  /// 表現のヒント・解説
  final String tips;

  /// TOEICレベル（700 / 800 など）
  final int level;

  factory Sentence.fromJson(Map<String, dynamic> json) => Sentence(
    id: json['id'] as String,
    ja: json['ja'] as String,
    en: json['en'] as String,
    theme: json['theme'] as String,
    tips: json['tips'] as String,
    level: (json['level'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ja': ja,
    'en': en,
    'theme': theme,
    'tips': tips,
    'level': level,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sentence &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ja == other.ja &&
          en == other.en &&
          theme == other.theme &&
          tips == other.tips &&
          level == other.level;

  @override
  int get hashCode => Object.hash(id, ja, en, theme, tips, level);
}
