// 中国語（HSK3/HSK4）教材アセットと、学習言語の切り替えに関するテスト。
//
// 教材の語彙がHSKの級内に収まっているかの検証はDart側では行わない
// （公式語彙リストをアプリに同梱していないため）。ここでは教材の構造・
// 必須フィールド・言語切り替えの配線が壊れていないことを担保する。

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/models/learning_language.dart';
import 'package:pj_walter/models/srs_item.dart';
import 'package:pj_walter/services/history_service.dart';
import 'package:pj_walter/services/sentence_repository.dart';
import 'package:pj_walter/services/settings_service.dart';

import 'test_support/hive_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SentenceRepository repository;

  setUp(() async {
    await initTestHive();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    repository = SentenceRepository();
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('中国語教材', () {
    test('HSK3・HSK4のデッキがロードでき、レベルが一致する', () async {
      final hsk3 = await repository.sentencesFor(
        profile: LanguageProfile.chinese,
        level: 3,
      );
      final hsk4 = await repository.sentencesFor(
        profile: LanguageProfile.chinese,
        level: 4,
      );

      expect(hsk3, isNotEmpty);
      expect(hsk4, isNotEmpty);
      expect(hsk3.every((s) => s.level == 3), isTrue);
      expect(hsk4.every((s) => s.level == 4), isTrue);
    });

    test('全ての文が日本語・中国語・ピンイン・解説を持つ', () async {
      for (final level in [3, 4]) {
        final sentences = await repository.sentencesFor(
          profile: LanguageProfile.chinese,
          level: level,
        );
        for (final sentence in sentences) {
          expect(sentence.ja, isNotEmpty, reason: sentence.id);
          expect(sentence.target, isNotEmpty, reason: sentence.id);
          expect(sentence.tips, isNotEmpty, reason: sentence.id);
          expect(sentence.reading, isNotNull, reason: sentence.id);
          expect(sentence.reading, isNotEmpty, reason: sentence.id);
        }
      }
    });

    test('IDが教材全体で一意である', () async {
      final ids = <String>[];
      for (final level in [3, 4]) {
        final sentences = await repository.sentencesFor(
          profile: LanguageProfile.chinese,
          level: level,
        );
        ids.addAll(sentences.map((s) => s.id));
      }

      expect(ids.toSet().length, ids.length);
    });

    test('IDが英語教材のIDと衝突しない（SRSキューが混ざらない）', () async {
      final chinese = [
        for (final level in [3, 4])
          ...await repository.sentencesFor(
            profile: LanguageProfile.chinese,
            level: level,
          ),
      ].map((s) => s.id).toSet();
      final english = [
        for (final level in [700, 800])
          ...await repository.sentencesFor(
            profile: LanguageProfile.english,
            level: level,
          ),
      ].map((s) => s.id).toSet();

      expect(chinese.intersection(english), isEmpty);
    });

    test('テーマが3分類のいずれかに収まっている', () async {
      const themes = {'daily', 'business', 'travel'};
      for (final level in [3, 4]) {
        final sentences = await repository.sentencesFor(
          profile: LanguageProfile.chinese,
          level: level,
        );
        for (final sentence in sentences) {
          expect(themes, contains(sentence.theme), reason: sentence.id);
        }
      }
    });

    test('テーマで絞り込める', () async {
      final all = await repository.sentencesFor(
        profile: LanguageProfile.chinese,
        level: 3,
      );
      final businessOnly = await repository.sentencesFor(
        profile: LanguageProfile.chinese,
        level: 3,
        theme: 'business',
      );

      expect(businessOnly, isNotEmpty);
      expect(businessOnly.length, lessThan(all.length));
      expect(businessOnly.every((s) => s.theme == 'business'), isTrue);
    });

    test('独り言のお題がロードでき、中国語文とピンインを持つ', () async {
      final topics = await repository.topics(profile: LanguageProfile.chinese);

      expect(topics, isNotEmpty);
      for (final topic in topics) {
        expect(topic.ja, isNotEmpty, reason: topic.id);
        expect(topic.target, isNotEmpty, reason: topic.id);
        expect(topic.reading, isNotEmpty, reason: topic.id);
      }
    });

    test('その言語に無いレベルを要求すると例外になる', () async {
      expect(
        () => repository.sentencesFor(
          profile: LanguageProfile.chinese,
          level: 700,
        ),
        throwsArgumentError,
      );
    });
  });

  group('LanguageProfile', () {
    test('英語と中国語で音声認識ロケールとアセットの場所が分かれている', () {
      expect(LanguageProfile.english.sttLocaleId, 'en_US');
      expect(LanguageProfile.chinese.sttLocaleId, 'zh_CN');
      expect(
        LanguageProfile.english.sentencesAssetPath(700),
        'assets/data/en/sentences_700.json',
      );
      expect(
        LanguageProfile.chinese.sentencesAssetPath(3),
        'assets/data/zh/sentences_3.json',
      );
    });

    test('中国語だけ発音表記のラベルを持ち、分かち書きしない扱いになる', () {
      expect(LanguageProfile.english.readingLabel, isNull);
      expect(LanguageProfile.english.wordSeparated, isTrue);
      expect(LanguageProfile.chinese.readingLabel, 'ピンイン');
      expect(LanguageProfile.chinese.wordSeparated, isFalse);
    });
  });

  group('SettingsService の学習言語', () {
    test('既定は英語で、切り替えると永続化される', () async {
      final box = await Hive.openBox('settings');
      final settings = SettingsService(settingsBox: box);
      await settings.init();

      expect(settings.learningLanguage, LearningLanguage.english);
      expect(settings.languageProfile.code, 'en');

      await settings.setLearningLanguage(LearningLanguage.chinese);
      expect(settings.languageProfile.compositionTitle, '口頭中国語作文');

      // 別インスタンスで読み直しても保持されている
      final reopened = SettingsService(settingsBox: box);
      await reopened.init();
      expect(reopened.learningLanguage, LearningLanguage.chinese);
    });
  });

  group('復習キューの言語分離', () {
    test('dueSrsItemsは指定した学習言語のアイテムだけを返す', () async {
      final history = HistoryService(
        drillResultsBox: await Hive.openBox('drill_results'),
        monologueResultsBox: await Hive.openBox('monologue_results'),
        srsItemsBox: await Hive.openBox('srs_items'),
        phrasesBox: await Hive.openBox('phrases'),
        dailyStatsBox: await Hive.openBox('daily_stats'),
      );
      final today = DateTime.now();
      final due = DateTime(today.year, today.month, today.day);
      for (final item in [
        SrsItem(
          sentenceId: 's700-001',
          language: 'en',
          level: 700,
          stage: 0,
          dueDate: due,
          lapses: 0,
          lastResult: false,
        ),
        SrsItem(
          sentenceId: 'z3-001',
          language: 'zh',
          level: 3,
          stage: 0,
          dueDate: due,
          lapses: 0,
          lastResult: false,
        ),
      ]) {
        await Hive.box('srs_items').put(item.sentenceId, item.toJson());
      }

      expect(history.dueSrsItems().length, 2);
      expect(history.dueSrsItems(language: 'zh').map((i) => i.sentenceId), [
        'z3-001',
      ]);
      expect(history.dueSrsItems(language: 'en').map((i) => i.sentenceId), [
        's700-001',
      ]);
    });

    test('languageが無い保存済みアイテムは英語として扱われる', () {
      final restored = SrsItem.fromJson({
        'sentenceId': 's700-001',
        'level': 700,
        'stage': 0,
        'dueDate': DateTime(2026, 1, 1).toIso8601String(),
        'lapses': 0,
        'lastResult': false,
      });

      expect(restored.language, 'en');
    });
  });
}
