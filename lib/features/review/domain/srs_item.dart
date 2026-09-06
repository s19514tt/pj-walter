import 'package:freezed_annotation/freezed_annotation.dart';

part 'srs_item.freezed.dart';

/// SRS（間隔反復）復習キューの1アイテム。
///
/// stageは0〜5。5に到達すると「卒業」としてキューから除外（削除）される。
@freezed
abstract class SrsItem with _$SrsItem {
  const factory SrsItem({
    /// 対象の[Sentence]のid（Hive boxのキーとしても使う）
    required String sentenceId,

    /// 対象文の学習言語コード（[LanguageProfile.code]）
    required String language,

    /// 対象文のデッキレベル
    required int level,

    /// 復習段階（0〜4。5で卒業）
    required int stage,

    /// 次回復習予定日（時刻は無視し日単位で比較する）
    required DateTime dueDate,

    /// 失敗（不正解）した回数
    required int lapses,

    /// 直近の復習結果（正解=true）
    required bool lastResult,
  }) = _SrsItem;
}
