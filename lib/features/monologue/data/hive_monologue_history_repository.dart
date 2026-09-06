import 'package:hive/hive.dart';
import 'package:signals_core/signals_core.dart';

import '../../../core/data/json_map.dart';
import '../domain/monologue_history_repository.dart';
import '../domain/monologue_result.dart';
import 'monologue_result_dto.dart';

/// [MonologueHistoryRepository] の Hive 実装（box `monologue_results`、キーは uuid）。
class HiveMonologueHistoryRepository implements MonologueHistoryRepository {
  HiveMonologueHistoryRepository(this._box) : _results = signal(const []) {
    _results.value = _readAll();
  }

  final Box _box;
  final Signal<List<MonologueResult>> _results;

  @override
  ReadonlySignal<List<MonologueResult>> get results => _results;

  @override
  Future<void> save(MonologueResult result) async {
    await _box.put(result.id, MonologueResultDto.fromEntity(result).toJson());
    _results.value = _readAll();
  }

  List<MonologueResult> _readAll() {
    final list = _box.values
        .map(
          (e) =>
              MonologueResultDto.fromJson(jsonMapFrom(e as Object)).toEntity(),
        )
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }
}
