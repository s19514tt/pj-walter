import 'package:signals_core/signals_core.dart';

import 'srs_item.dart';

/// スコアがこの値未満だとSRSキューに登録される（不合格ライン）。
const passingScore = 70;

/// SRS（間隔反復）復習キュー（DESIGN.md「SRS アルゴリズム」）。
///
/// [items] はアプリ寿命の signal で、更新のたびに差し替わる。
abstract interface class SrsRepository {
  /// 全アイテム（順不同）
  ReadonlySignal<List<SrsItem>> get items;

  /// 今日復習すべきアイテム（dueDate <= 今日、日単位比較）を dueDate が早い順に返す。
  ///
  /// [language]を渡すとその学習言語のアイテムだけに絞る。復習セッションは
  /// 現在の学習言語のプロンプトで採点するため、言語を混ぜると別言語の文が
  /// 誤った言語で採点されてしまう。呼び出し側は必ず言語を指定すること。
  List<SrsItem> due({String? language, DateTime? now});

  /// ドリルで不正解だった文を stage 0 で登録する（既存なら stage 0 に戻し lapses+1）。
  Future<void> registerFailure({
    required String sentenceId,
    required String language,
    required int level,
  });

  /// 復習結果を反映する。
  ///
  /// 正解ならstageを1つ進め、次回dueDateを更新する（stage5到達で卒業しキューから削除）。
  /// 不正解ならstageを0に戻し、翌日をdueDateとする。
  Future<void> applyReviewResult(String sentenceId, bool correct);
}

/// [items] から今日の復習対象を選ぶ純粋関数（[SrsRepository.due] の実装共通部）。
List<SrsItem> dueSrsItems(
  List<SrsItem> items, {
  String? language,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final list = items
      .where((item) => !_dateOnly(item.dueDate).isAfter(today))
      .where((item) => language == null || item.language == language)
      .toList();
  list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return list;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
