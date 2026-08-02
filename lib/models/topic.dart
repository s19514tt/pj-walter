import 'package:flutter/foundation.dart';

/// 独り言英会話のお題。
@immutable
class Topic {
  const Topic({
    required this.id,
    required this.ja,
    required this.en,
    required this.theme,
  });

  /// `t-{連番3桁}` 形式のID（例: `t-001`）
  final String id;

  /// 日本語の指示文
  final String ja;

  /// 英語の指示文
  final String en;

  /// テーマ（`daily` / `business` / `travel`）
  final String theme;

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    ja: json['ja'] as String,
    en: json['en'] as String,
    theme: json['theme'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ja': ja,
    'en': en,
    'theme': theme,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ja == other.ja &&
          en == other.en &&
          theme == other.theme;

  @override
  int get hashCode => Object.hash(id, ja, en, theme);
}
