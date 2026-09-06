// ReviewStore のユニットテスト（ウィジェットを pump しない）。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/review/data/hive_phrase_repository.dart';
import 'package:pj_walter/features/review/data/hive_srs_repository.dart';
import 'package:pj_walter/features/review/domain/load_review_session.dart';
import 'package:pj_walter/features/review/domain/phrase.dart';
import 'package:pj_walter/features/review/presentation/review_store.dart';
import 'package:pj_walter/features/settings/domain/app_settings.dart';

import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/hive_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 9, 6, 12);
  late HiveSrsRepository srs;
  late HivePhraseRepository phrases;
  late FakeSettingsRepository settings;

  setUp(() async {
    await initTestHive();
    // 登録日を前日にして、登録直後の dueDate（翌日）を「今日」にする
    srs = HiveSrsRepository(
      await Hive.openBox('srs_items'),
      now: () => DateTime(2026, 9, 5),
    );
    phrases = HivePhraseRepository(await Hive.openBox('phrases'));
    settings = FakeSettingsRepository();
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  ReviewStore build() => ReviewStore(
    srs: srs,
    phrases: phrases,
    settings: settings,
    loadReviewSession: LoadReviewSession(content: AssetContentRepository()),
    now: () => today,
  );

  test('今日の復習は現在の学習言語だけ、復習予定は全言語を数える', () async {
    await srs.registerFailure(
      sentenceId: 's700-001',
      language: 'en',
      level: 700,
    );
    await srs.registerFailure(sentenceId: 'z3-001', language: 'zh', level: 3);
    final store = build();
    addTearDown(store.dispose);

    expect(store.dueItems.value.map((i) => i.sentenceId), ['s700-001']);
    expect(store.upcoming.value.total, 2);
    expect(store.upcoming.value.stageCounts, [2, 0, 0, 0, 0]);
    expect(store.upcoming.value.remaining, 0);

    // 学習言語を切り替えると today の対象も切り替わる（Repository の signal から派生）
    await settings.setLearningLanguage(LearningLanguage.chinese);
    expect(store.dueItems.value.map((i) => i.sentenceId), ['z3-001']);

    // SRS が更新されると復習予定も追従する
    await srs.applyReviewResult('s700-001', true);
    // SRS 側の時計は 9/5 なので次回は 9/8、Store の今日（9/6）からは 2 日後
    expect(store.upcoming.value.stageCounts, [1, 1, 0, 0, 0]);
    expect(store.daysUntil(store.upcoming.value.shown.last.dueDate), 2);
  });

  test('復習予定は上限件数まで表示し、残りは件数だけ持つ', () async {
    for (var i = 0; i < upcomingListLimit + 2; i++) {
      await srs.registerFailure(
        sentenceId: 's700-$i',
        language: 'en',
        level: 700,
      );
    }
    final store = build();
    addTearDown(store.dispose);

    expect(store.upcoming.value.shown, hasLength(upcomingListLimit));
    expect(store.upcoming.value.remaining, 2);
  });

  test('フレーズ帳は学習言語・日本語のどちらでも検索でき、削除が反映される', () async {
    await phrases.add(
      Phrase(
        id: 'p-1',
        target: 'break the ice',
        ja: '緊張をほぐす',
        source: 'manual',
        createdAt: DateTime(2026, 8, 1),
      ),
    );
    await phrases.add(
      Phrase(
        id: 'p-2',
        target: 'slip my mind',
        ja: 'うっかり忘れる',
        source: 'manual',
        createdAt: DateTime(2026, 8, 2),
      ),
    );
    final store = build();
    addTearDown(store.dispose);

    expect(store.phraseCount.value, 2);
    expect(store.filteredPhrases.value.map((p) => p.id), ['p-2', 'p-1']);

    store.setQuery('BREAK');
    expect(store.filteredPhrases.value.map((p) => p.id), ['p-1']);
    store.setQuery('うっかり');
    expect(store.filteredPhrases.value.map((p) => p.id), ['p-2']);
    store.setQuery('zzz');
    expect(store.filteredPhrases.value, isEmpty);

    store.setQuery('');
    await store.deletePhrase('p-1');
    expect(store.filteredPhrases.value.map((p) => p.id), ['p-2']);
    expect(store.phraseCount.value, 1);
  });

  test('loadReviewSentences は教材に解決し、解決中フラグを立てる', () async {
    await srs.registerFailure(
      sentenceId: 's700-001',
      language: 'en',
      level: 700,
    );
    await srs.registerFailure(
      sentenceId: 'missing',
      language: 'en',
      level: 700,
    );
    final store = build();
    addTearDown(store.dispose);

    final future = store.loadReviewSentences();
    expect(store.startingReview.value, isTrue);
    final sentences = await future;

    expect(store.startingReview.value, isFalse);
    // 教材に無い ID は飛ばす
    expect(sentences.map((s) => s.id), ['s700-001']);
  });

  test('中国語設定でもデッキ・言語が正しく引ける', () async {
    settings = FakeSettingsRepository(
      initial: const AppSettings(learningLanguage: LearningLanguage.chinese),
    );
    final store = build();
    addTearDown(store.dispose);
    expect(store.profile.value.code, 'zh');
  });
}
