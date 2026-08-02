import 'package:flutter/foundation.dart';

/// SRS（間隔反復）復習キューの1アイテム。
///
/// stageは0〜5。5に到達すると「卒業」としてキューから除外（削除）される。
@immutable
class SrsItem {
  const SrsItem({
    required this.sentenceId,
    required this.level,
    required this.stage,
    required this.dueDate,
    required this.lapses,
    required this.lastResult,
  });

  /// 対象の[Sentence]のid（Hive boxのキーとしても使う）
  final String sentenceId;

  /// 対象文のTOEICレベル
  final int level;

  /// 復習段階（0〜4。5で卒業）
  final int stage;

  /// 次回復習予定日（時刻は無視し日単位で比較する）
  final DateTime dueDate;

  /// 失敗（不正解）した回数
  final int lapses;

  /// 直近の復習結果（正解=true）
  final bool lastResult;

  /// 一部のフィールドを変更した新しいインスタンスを返す。
  SrsItem copyWith({
    int? stage,
    DateTime? dueDate,
    int? lapses,
    bool? lastResult,
  }) => SrsItem(
    sentenceId: sentenceId,
    level: level,
    stage: stage ?? this.stage,
    dueDate: dueDate ?? this.dueDate,
    lapses: lapses ?? this.lapses,
    lastResult: lastResult ?? this.lastResult,
  );

  factory SrsItem.fromJson(Map<String, dynamic> json) => SrsItem(
    sentenceId: json['sentenceId'] as String,
    level: (json['level'] as num).toInt(),
    stage: (json['stage'] as num).toInt(),
    dueDate: DateTime.parse(json['dueDate'] as String),
    lapses: (json['lapses'] as num).toInt(),
    lastResult: json['lastResult'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'sentenceId': sentenceId,
    'level': level,
    'stage': stage,
    'dueDate': dueDate.toIso8601String(),
    'lapses': lapses,
    'lastResult': lastResult,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SrsItem &&
          runtimeType == other.runtimeType &&
          sentenceId == other.sentenceId &&
          level == other.level &&
          stage == other.stage &&
          dueDate == other.dueDate &&
          lapses == other.lapses &&
          lastResult == other.lastResult;

  @override
  int get hashCode =>
      Object.hash(sentenceId, level, stage, dueDate, lapses, lastResult);
}
