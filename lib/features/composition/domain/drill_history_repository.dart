import 'package:signals_core/signals_core.dart';

import 'drill_result.dart';

/// 口頭作文の結果履歴。
///
/// [results] はアプリ寿命の signal で、保存のたびに更新される（新しい順）。
/// Store はこれを `computed` で派生させ、コピーを持たない。
abstract interface class DrillHistoryRepository {
  /// 結果の一覧（新しい順）
  ReadonlySignal<List<DrillResult>> get results;

  Future<void> save(DrillResult result);
}
