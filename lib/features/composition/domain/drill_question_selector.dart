import 'dart:math';

import '../../content/domain/sentence.dart';

/// 口頭英作文ドリル1セッション分の出題文選択ロジック。
///
/// [ContentRepository]が返すリストはunmodifiableなため、シャッフル前に
/// 必ずコピーを作成する（呼び出し元のリストを破壊しないため）。
class DrillQuestionSelector {
  const DrillQuestionSelector({this.count = 10});

  /// 1セッションあたりの最大出題数
  final int count;

  /// [sentences]から出題文を重複なくランダムに選ぶ。
  ///
  /// [sentences]の件数が[count]未満の場合は全件をシャッフルして返す。
  /// テストで再現性を持たせるため[random]を注入できる。
  List<Sentence> select(List<Sentence> sentences, {Random? random}) {
    final shuffled = [...sentences]..shuffle(random);
    if (shuffled.length <= count) return shuffled;
    return shuffled.sublist(0, count);
  }
}
