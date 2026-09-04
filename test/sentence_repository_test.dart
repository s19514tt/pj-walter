// SentenceRepositoryのアセットロード・フィルタのテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/services/sentence_repository.dart';
import 'package:pj_walter/models/learning_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SentenceRepository repository;

  setUp(() {
    repository = SentenceRepository();
  });

  group('sentencesFor', () {
    test('各レベル200文をロードする', () async {
      final level700 = await repository.sentencesFor(
        profile: LanguageProfile.english,
        level: 700,
      );
      final level800 = await repository.sentencesFor(
        profile: LanguageProfile.english,
        level: 800,
      );

      expect(level700, hasLength(200));
      expect(level800, hasLength(200));
      expect(level700.every((s) => s.level == 700), isTrue);
      expect(level800.every((s) => s.level == 800), isTrue);
    });

    test('themeを指定するとフィルタされる', () async {
      final businessOnly = await repository.sentencesFor(
        profile: LanguageProfile.english,

        level: 700,
        theme: 'business',
      );

      expect(businessOnly, isNotEmpty);
      expect(businessOnly.every((s) => s.theme == 'business'), isTrue);
    });

    test('theme未指定なら全テーマを返す', () async {
      final all = await repository.sentencesFor(
        profile: LanguageProfile.english,
        level: 700,
      );
      final themes = all.map((s) => s.theme).toSet();

      expect(themes, {'daily', 'business', 'travel'});
    });

    test('ロード結果はキャッシュされ同一インスタンスを返す', () async {
      final first = await repository.sentencesFor(
        profile: LanguageProfile.english,
        level: 700,
      );
      final second = await repository.sentencesFor(
        profile: LanguageProfile.english,
        level: 700,
      );

      expect(identical(first, second), isTrue);
    });
  });

  group('topics', () {
    test('60題をロードする', () async {
      final all = await repository.topics(profile: LanguageProfile.english);

      expect(all, hasLength(60));
    });

    test('themeを指定するとフィルタされる', () async {
      final travelOnly = await repository.topics(
        profile: LanguageProfile.english,
        theme: 'travel',
      );

      expect(travelOnly, isNotEmpty);
      expect(travelOnly.every((t) => t.theme == 'travel'), isTrue);
    });
  });
}
