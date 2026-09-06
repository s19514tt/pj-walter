import 'package:signals_core/signals_core.dart';

import 'monologue_result.dart';

/// 独り言の結果履歴。[results] はアプリ寿命の signal（新しい順）。
abstract interface class MonologueHistoryRepository {
  ReadonlySignal<List<MonologueResult>> get results;

  Future<void> save(MonologueResult result);
}
