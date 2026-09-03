import 'package:flutter/foundation.dart';

/// 教材の1文（口頭作文で出題される日本語文と、学習言語の模範解答）。
@immutable
class Sentence {
  const Sentence({
    required this.id,
    required this.ja,
    required this.target,
    required this.theme,
    required this.tips,
    required this.level,
    this.reading,
  });

  /// 教材内で一意なID（例: `s700-001` / `z3-001`）
  final String id;

  /// 出題される日本語原文
  final String ja;

  /// 学習言語での模範解答
  final String target;

  /// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
  final String? reading;

  /// テーマ（`daily` / `business` / `travel`）
  final String theme;

  /// 表現のヒント・解説
  final String tips;

  /// デッキのレベル（英語なら700/800、中国語ならHSKの3/4）
  final int level;

  factory Sentence.fromJson(Map<String, dynamic> json) => Sentence(
    id: json['id'] as String,
    ja: json['ja'] as String,
    // 'en'は学習言語が英語だけだった頃のキー名。既存データのために読めるようにする。
    target: (json['target'] ?? json['en']) as String,
    theme: json['theme'] as String,
    tips: json['tips'] as String,
    level: (json['level'] as num).toInt(),
    reading: json['reading'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ja': ja,
    'target': target,
    'theme': theme,
    'tips': tips,
    'level': level,
    'reading': reading,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sentence &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ja == other.ja &&
          target == other.target &&
          theme == other.theme &&
          tips == other.tips &&
          level == other.level &&
          reading == other.reading;

  @override
  int get hashCode => Object.hash(id, ja, target, theme, tips, level, reading);
}
