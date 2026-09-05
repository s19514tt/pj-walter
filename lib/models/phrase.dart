import 'package:flutter/foundation.dart';

/// フレーズ帳の1エントリ。
@immutable
class Phrase {
  const Phrase({
    required this.id,
    required this.target,
    required this.ja,
    required this.source,
    required this.createdAt,
  });

  /// エントリのuuid
  final String id;

  /// 学習言語での表現
  final String target;

  /// 日本語訳
  final String ja;

  /// 追加元（例: `monologue`, `manual`）
  final String source;

  /// 追加日時
  final DateTime createdAt;

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
    id: json['id'] as String,
    // 'en'は学習言語が英語だけだった頃のキー名。保存済みデータのために残す。
    target: (json['target'] ?? json['en']) as String,
    ja: json['ja'] as String,
    source: json['source'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'target': target,
    'ja': ja,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Phrase &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          target == other.target &&
          ja == other.ja &&
          source == other.source &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, target, ja, source, createdAt);
}
