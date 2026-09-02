// SentenceRepositoryのアセットロード・フィルタのテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/services/sentence_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SentenceRepository repository;

  setUp(() {
    repository = SentenceRepository();
  });

  group('sentencesFor', () {
    test('各レベル400文をロードする', () async {
      final level700 = await repository.sentencesFor(level: 700);
      final level800 = await repository.sentencesFor(level: 800);

      expect(level700, hasLength(400));
      expect(level800, hasLength(400));
      expect(level700.every((s) => s.level == 700), isTrue);
      expect(level800.every((s) => s.level == 800), isTrue);
    });

    test('idが全レベルを通して一意である', () async {
      final all = [
        ...await repository.sentencesFor(level: 700),
        ...await repository.sentencesFor(level: 800),
      ];

      expect(all.map((s) => s.id).toSet(), hasLength(all.length));
    });

    test('各レベルのテーマ構成が揃っている', () async {
      for (final level in [700, 800]) {
        final sentences = await repository.sentencesFor(level: level);
        final counts = <String, int>{};
        for (final s in sentences) {
          counts[s.theme] = (counts[s.theme] ?? 0) + 1;
        }

        expect(counts, {'daily': 140, 'business': 140, 'travel': 120});
      }
    });

    test('themeを指定するとフィルタされる', () async {
      final businessOnly = await repository.sentencesFor(
        level: 700,
        theme: 'business',
      );

      expect(businessOnly, isNotEmpty);
      expect(businessOnly.every((s) => s.theme == 'business'), isTrue);
    });

    test('theme未指定なら全テーマを返す', () async {
      final all = await repository.sentencesFor(level: 700);
      final themes = all.map((s) => s.theme).toSet();

      expect(themes, {'daily', 'business', 'travel'});
    });

    test('ロード結果はキャッシュされ同一インスタンスを返す', () async {
      final first = await repository.sentencesFor(level: 700);
      final second = await repository.sentencesFor(level: 700);

      expect(identical(first, second), isTrue);
    });
  });

  group('topics', () {
    test('60題をロードする', () async {
      final all = await repository.topics();

      expect(all, hasLength(60));
    });

    test('themeを指定するとフィルタされる', () async {
      final travelOnly = await repository.topics(theme: 'travel');

      expect(travelOnly, isNotEmpty);
      expect(travelOnly.every((t) => t.theme == 'travel'), isTrue);
    });
  });
}
