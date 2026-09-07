// HivePhraseRepository（フレーズ帳）のテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/review/data/hive_phrase_repository.dart';
import 'package:pj_walter/features/review/domain/phrase.dart';

import '../../../test_support/hive_test_support.dart';

Phrase _phrase(String id, DateTime createdAt) => Phrase(
  id: id,
  target: 'phrase $id',
  ja: 'フレーズ $id',
  source: 'manual',
  createdAt: createdAt,
);

void main() {
  late HivePhraseRepository repository;

  setUp(() async {
    await initTestHive();
    repository = HivePhraseRepository(await Hive.openBox('phrases'));
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  test('addで追加し新しい順に取得できる', () async {
    await repository.add(_phrase('p-1', DateTime(2026, 9, 1)));
    await repository.add(_phrase('p-2', DateTime(2026, 9, 2)));

    final phrases = repository.phrases.value;
    expect(phrases, hasLength(2));
    expect(phrases.first.id, 'p-2');
  });

  test('deleteで指定idのフレーズだけが削除される', () async {
    await repository.add(_phrase('p-10', DateTime(2026, 9, 1)));
    await repository.add(_phrase('p-11', DateTime(2026, 9, 2)));

    await repository.delete('p-10');

    expect(repository.phrases.value.map((p) => p.id), ['p-11']);
  });

  test('存在しないidをdeleteしても例外にならない', () async {
    await expectLater(repository.delete('unknown'), completes);
    expect(repository.phrases.value, isEmpty);
  });
}
