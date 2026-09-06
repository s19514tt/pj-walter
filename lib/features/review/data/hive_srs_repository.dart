import 'package:hive/hive.dart';
import 'package:signals_core/signals_core.dart';

import '../../../core/data/json_map.dart';
import '../domain/srs_item.dart';
import '../domain/srs_repository.dart';
import 'srs_item_dto.dart';

/// SRSの段階(stage)ごとの復習間隔（日数）。stage5は卒業（キューから除外）。
const _srsIntervalDays = {0: 1, 1: 3, 2: 7, 3: 14, 4: 30};

/// 卒業（キューから除外）とみなすstage
const _graduationStage = 5;

/// [SrsRepository] の Hive 実装（box `srs_items`、キーは sentenceId）。
class HiveSrsRepository implements SrsRepository {
  HiveSrsRepository(this._box, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _items = signal(const []) {
    _items.value = _readAll();
  }

  final Box _box;
  final DateTime Function() _now;
  final Signal<List<SrsItem>> _items;

  @override
  ReadonlySignal<List<SrsItem>> get items => _items;

  @override
  List<SrsItem> due({String? language, DateTime? now}) =>
      dueSrsItems(_items.value, language: language, now: now ?? _now());

  @override
  Future<void> registerFailure({
    required String sentenceId,
    required String language,
    required int level,
  }) async {
    final existing = _read(sentenceId);
    final item = SrsItem(
      sentenceId: sentenceId,
      language: language,
      level: level,
      stage: 0,
      dueDate: _addDays(_dateOnly(_now()), _srsIntervalDays[0]!),
      lapses: existing == null ? 0 : existing.lapses + 1,
      lastResult: false,
    );
    await _put(item);
  }

  @override
  Future<void> applyReviewResult(String sentenceId, bool correct) async {
    final item = _read(sentenceId);
    if (item == null) return;

    if (correct) {
      final nextStage = item.stage + 1;
      if (nextStage >= _graduationStage) {
        await _box.delete(sentenceId);
        _items.value = _readAll();
        return;
      }
      await _put(
        item.copyWith(
          stage: nextStage,
          dueDate: _addDays(_dateOnly(_now()), _srsIntervalDays[nextStage]!),
          lastResult: true,
        ),
      );
    } else {
      await _put(
        item.copyWith(
          stage: 0,
          dueDate: _addDays(_dateOnly(_now()), _srsIntervalDays[0]!),
          lastResult: false,
        ),
      );
    }
  }

  Future<void> _put(SrsItem item) async {
    await _box.put(item.sentenceId, SrsItemDto.fromEntity(item).toJson());
    _items.value = _readAll();
  }

  SrsItem? _read(String sentenceId) {
    final raw = _box.get(sentenceId);
    if (raw == null) return null;
    return SrsItemDto.fromJson(jsonMapFrom(raw as Object)).toEntity();
  }

  List<SrsItem> _readAll() => List.unmodifiable(
    _box.values.map(
      (e) => SrsItemDto.fromJson(jsonMapFrom(e as Object)).toEntity(),
    ),
  );

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);
}
