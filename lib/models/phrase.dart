import 'package:flutter/foundation.dart';

/// フレーズ帳の1エントリ。
@immutable
class Phrase {
  const Phrase({
    required this.id,
    required this.en,
    required this.ja,
    required this.source,
    required this.createdAt,
  });

  /// エントリのuuid
  final String id;

  /// 英語表現
  final String en;

  /// 日本語訳
  final String ja;

  /// 追加元（例: `monologue`, `manual`）
  final String source;

  /// 追加日時
  final DateTime createdAt;

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
    id: json['id'] as String,
    en: json['en'] as String,
    ja: json['ja'] as String,
    source: json['source'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'en': en,
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
          en == other.en &&
          ja == other.ja &&
          source == other.source &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, en, ja, source, createdAt);
}
