import 'package:hive/hive.dart';
import 'package:signals_core/signals_core.dart';

import '../../../core/data/json_map.dart';
import '../domain/phrase.dart';
import '../domain/phrase_repository.dart';
import 'phrase_dto.dart';

/// [PhraseRepository] の Hive 実装（box `phrases`、キーは uuid）。
class HivePhraseRepository implements PhraseRepository {
  HivePhraseRepository(this._box) : _phrases = signal(const []) {
    _phrases.value = _readAll();
  }

  final Box _box;
  final Signal<List<Phrase>> _phrases;

  @override
  ReadonlySignal<List<Phrase>> get phrases => _phrases;

  @override
  Future<void> add(Phrase phrase) async {
    await _box.put(phrase.id, PhraseDto.fromEntity(phrase).toJson());
    _phrases.value = _readAll();
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
    _phrases.value = _readAll();
  }

  List<Phrase> _readAll() {
    final list = _box.values
        .map((e) => PhraseDto.fromJson(jsonMapFrom(e as Object)).toEntity())
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }
}
