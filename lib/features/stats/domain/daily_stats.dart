import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_stats.freezed.dart';

/// 1日（×学習言語）の学習量。
@freezed
abstract class DailyStats with _$DailyStats {
  const DailyStats._();

  const factory DailyStats({
    /// 口頭作文の回答数
    @Default(0) int drillCount,

    /// 独り言の実施回数
    @Default(0) int monologueCount,

    /// 学習秒数（独り言の発話時間の合計）
    @Default(0) int studySeconds,
  }) = _DailyStats;

  static const zero = DailyStats();

  /// その日に何か学習したかどうか（ストリーク・カレンダーの判定）
  bool get isStudyDay => drillCount + monologueCount > 0;

  DailyStats operator +(DailyStats other) => DailyStats(
    drillCount: drillCount + other.drillCount,
    monologueCount: monologueCount + other.monologueCount,
    studySeconds: studySeconds + other.studySeconds,
  );
}
