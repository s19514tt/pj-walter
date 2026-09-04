import 'package:flutter/foundation.dart';

/// 独り言トレーニングのお題。
@immutable
class Topic {
  const Topic({
    required this.id,
    required this.ja,
    required this.target,
    required this.theme,
    this.reading,
  });

  /// `t-{連番3桁}` 形式のID（例: `t-001`）
  final String id;

  /// 日本語の指示文
  final String ja;

  /// 学習言語での指示文
  final String target;

  /// [target]の発音表記（中国語のピンインなど。不要な言語ではnull）
  final String? reading;

  /// テーマ（`daily` / `business` / `travel`）
  final String theme;

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    ja: json['ja'] as String,
    // 'en'は学習言語が英語だけだった頃のキー名。既存データのために読めるようにする。
    target: (json['target'] ?? json['en']) as String,
    theme: json['theme'] as String,
    reading: json['reading'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ja': ja,
    'target': target,
    'theme': theme,
    'reading': reading,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ja == other.ja &&
          target == other.target &&
          theme == other.theme &&
          reading == other.reading;

  @override
  int get hashCode => Object.hash(id, ja, target, theme, reading);
}
