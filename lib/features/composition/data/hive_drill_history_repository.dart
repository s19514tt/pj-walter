import 'package:hive/hive.dart';
import 'package:signals_core/signals_core.dart';

import '../../../core/data/json_map.dart';
import '../domain/drill_history_repository.dart';
import '../domain/drill_result.dart';
import 'drill_result_dto.dart';

/// [DrillHistoryRepository] の Hive 実装（box `drill_results`、キーは uuid）。
class HiveDrillHistoryRepository implements DrillHistoryRepository {
  HiveDrillHistoryRepository(this._box) : _results = signal(const []) {
    _results.value = _readAll();
  }

  final Box _box;
  final Signal<List<DrillResult>> _results;

  @override
  ReadonlySignal<List<DrillResult>> get results => _results;

  @override
  Future<void> save(DrillResult result) async {
    await _box.put(result.id, DrillResultDto.fromEntity(result).toJson());
    _results.value = _readAll();
  }

  List<DrillResult> _readAll() {
    final list = _box.values
        .map(
          (e) => DrillResultDto.fromJson(jsonMapFrom(e as Object)).toEntity(),
        )
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return List.unmodifiable(list);
  }
}
