// DeckSelectStore / SentenceListStore / DrillSummaryStore のユニットテスト。

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/core/domain/gemini_pricing.dart';
import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/composition/domain/drill_question_selector.dart';
import 'package:pj_walter/features/composition/domain/drill_session.dart';
import 'package:pj_walter/features/composition/presentation/deck_select_store.dart';
import 'package:pj_walter/features/composition/presentation/drill_summary_store.dart';
import 'package:pj_walter/features/composition/presentation/sentence_list_store.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/settings/domain/app_settings.dart';

import '../../../test_support/fake_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeckSelectStore', () {
    test('既定は最初のレベル・全テーマで、対象文数を数える', () async {
      final store = DeckSelectStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(),
      );
      addTearDown(store.dispose);

      expect(store.profile.code, 'en');
      expect(store.level.value, 700);
      expect(store.theme.value, isNull);
      expect(store.count.value.isLoading, isTrue);
      await store.count.future;
      expect(store.count.value.value, 200);
    });

    test('レベル・テーマを変えると数え直す', () async {
      final store = DeckSelectStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(
          initial: const AppSettings(
            learningLanguage: LearningLanguage.chinese,
          ),
        ),
      );
      addTearDown(store.dispose);
      await store.count.future;
      expect(store.count.value.value, 300);

      store.selectLevel(4);
      store.selectTheme('business');
      // 依存が変わると loading に戻り、読み直す
      expect(store.count.value.isLoading, isTrue);
      await store.count.future;
      final business = store.count.value.value!;
      expect(business, greaterThan(0));
      expect(business, lessThan(300));
    });

    test('startTraining は選択中のデッキから10問を選ぶ', () async {
      final store = DeckSelectStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(),
        selector: const DrillQuestionSelector(count: 3),
      );
      addTearDown(store.dispose);
      store.selectTheme('travel');

      final selected = await store.startTraining();

      expect(selected, hasLength(3));
      expect(selected.every((s) => s.theme == 'travel'), isTrue);
    });
  });

  group('SentenceListStore', () {
    test('レベル×テーマの教材を読み込む', () async {
      final store = SentenceListStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(),
        level: 800,
        theme: 'daily',
      );
      addTearDown(store.dispose);

      final sentences = await store.sentences.future;

      expect(sentences, isNotEmpty);
      expect(sentences.every((s) => s.level == 800), isTrue);
      expect(sentences.every((s) => s.theme == 'daily'), isTrue);
    });
  });

  group('DrillSummaryStore', () {
    const entries = [
      DrillSummaryEntry(
        ja: '1',
        score: 85,
        usage: DrillQuestionUsage(
          transcription: TokenUsage(promptTokens: 600, candidatesTokens: 20),
          correction: TokenUsage(promptTokens: 400, candidatesTokens: 30),
        ),
      ),
      DrillSummaryEntry(ja: '2', score: 60),
      DrillSummaryEntry(ja: '3', score: 0),
    ];

    test('平均・正答数・復習登録数・合計使用量を集計する', () {
      final store = DrillSummaryStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(),
        level: 700,
        theme: null,
        entries: entries,
        pricing: GeminiPricing.introductory,
      );
      addTearDown(store.dispose);

      expect(store.averageScore, 48);
      expect(store.passingCount, 1);
      expect(store.srsCount, 2);
      expect(store.totalUsage.total.promptTokens, 1000);
      expect(store.pricing, GeminiPricing.introductory);
    });

    test('単価を省略すると日付から決まる', () {
      final store = DrillSummaryStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(),
        level: 700,
        theme: null,
        entries: const [],
        now: () => DateTime(2027, 3, 1),
      );
      addTearDown(store.dispose);

      expect(store.pricing, GeminiPricing.standard);
      expect(store.averageScore, 0);
    });

    test('retry は同じレベル・テーマで新しい出題文を選ぶ', () async {
      final store = DrillSummaryStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(),
        level: 700,
        theme: 'business',
        entries: entries,
        selector: const DrillQuestionSelector(count: 5),
      );
      addTearDown(store.dispose);

      final selected = await store.retry();

      expect(selected, hasLength(5));
      expect(selected.every((s) => s.theme == 'business'), isTrue);
      expect(Random, isNotNull);
    });
  });
}
