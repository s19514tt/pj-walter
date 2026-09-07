import 'package:signals_core/signals_core.dart';

import 'phrase.dart';

/// フレーズ帳。[phrases] はアプリ寿命の signal（新しい順）。
abstract interface class PhraseRepository {
  ReadonlySignal<List<Phrase>> get phrases;

  Future<void> add(Phrase phrase);

  Future<void> delete(String id);
}
