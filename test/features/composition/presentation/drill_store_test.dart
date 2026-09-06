// DrillStore のユニットテスト（ウィジェットを pump しない）。
//
// 録音・添削・保存はすべてフェイクに差し替え、Store の状態遷移と
// notice（画面へ渡す一回きりの出来事）を signals のまま検証する。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/core/domain/app_failure.dart';
import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/composition/data/hive_drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/composition/domain/record_drill_result.dart';
import 'package:pj_walter/features/composition/presentation/drill_store.dart';
import 'package:pj_walter/features/content/domain/sentence.dart';
import 'package:pj_walter/features/review/data/hive_srs_repository.dart';
import 'package:pj_walter/features/settings/domain/app_settings.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';

import '../../../test_support/fake_correction_repository.dart';
import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/fake_speech_input_service.dart';
import '../../../test_support/fake_tts_service.dart';
import '../../../test_support/hive_test_support.dart';

const _texts = DrillTexts(
  timeoutExplanation: 'timeout',
  skipExplanation: 'skipped',
);

Sentence _sentence(int i) => Sentence(
  id: 's700-${i.toString().padLeft(3, '0')}',
  ja: '日本語の例文$i',
  target: 'English sentence $i',
  theme: 'daily',
  tips: 'tips $i',
  level: 700,
);

void main() {
  late HiveDrillHistoryRepository history;
  late HiveSrsRepository srs;
  late RecordDrillResult record;
  late FakeSettingsRepository settings;
  late FakeSpeechInputService speech;
  late FakeTtsService tts;
  late FakeCorrectionRepository correction;
  final notices = <DrillNotice>[];

  setUp(() async {
    await initTestHive();
    history = HiveDrillHistoryRepository(await Hive.openBox('drill_results'));
    srs = HiveSrsRepository(await Hive.openBox('srs_items'));
    record = RecordDrillResult(
      history: history,
      srs: srs,
      stats: HiveStudyStatsRepository(await Hive.openBox('daily_stats')),
    );
    settings = FakeSettingsRepository(apiKey: 'key');
    speech = FakeSpeechInputService();
    tts = FakeTtsService();
    correction = FakeCorrectionRepository();
    notices.clear();
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  DrillStore build({
    List<Sentence>? sentences,
    bool isReview = false,
    int questionSeconds = 30,
  }) {
    final store = DrillStore(
      sentences: sentences ?? [_sentence(1), _sentence(2)],
      level: 700,
      theme: 'daily',
      isReview: isReview,
      uiLocale: 'ja',
      texts: _texts,
      speechInput: speech,
      tts: tts,
      correction: correction,
      recordResult: record,
      settings: settings,
      questionSeconds: questionSeconds,
    );
    store.notice.subscribe((n) {
      if (n != null) notices.add(n);
    });
    return store;
  }

  test('初期状態: 1問目・pre・カウントダウン満タン', () {
    final store = build();
    addTearDown(store.dispose);

    expect(store.index.value, 0);
    expect(store.current.value.id, 's700-001');
    expect(store.isLast.value, isFalse);
    expect(store.recording.value, isFalse);
    expect(store.resultMode.value, isFalse);
    expect(store.secondsLeft.value, 30);
    expect(store.progress.value, 1.0);
    expect(store.urgent.value, isFalse);
    expect(speech.startCalled, isFalse);
  });

  test('答える→採点する で文字起こし→添削→保存し、usageを問に積んで次へ進む', () async {
    final store = build();
    addTearDown(store.dispose);

    await store.startRecording();
    expect(speech.startCalled, isTrue);
    expect(store.recording.value, isTrue);

    await store.submit();

    expect(store.resultMode.value, isTrue);
    expect(store.stagedSpoken.value, 'this is my spoken answer');
    expect(store.feedback.value?.score, 85);
    expect(store.grading.value, isFalse);
    expect(correction.requests.single.uiLocale, 'ja');
    expect(correction.requests.single.learningLanguage, 'en');
    expect(correction.requests.single.source, '日本語の例文1');
    expect(history.results.value.single.sentenceId, 's700-001');
    // スコア85は合格なので SRS には登録されない
    expect(srs.items.value, isEmpty);

    store.addSpeechUsage(
      const TokenUsage(promptTokens: 5, candidatesTokens: 50),
    );
    store.next();

    expect(store.index.value, 1);
    expect(store.resultMode.value, isFalse);
    expect(store.feedback.value, isNull);
    expect(store.isLast.value, isTrue);

    // 2問目も採点して終える → まとめ用の entries が notice で渡る
    await store.startRecording();
    await store.submit();
    store.next();

    final finished = notices.whereType<DrillSessionFinishedNotice>().single;
    expect(finished.entries, hasLength(2));
    expect(finished.entries.first.usage.transcription.promptTokens, 300);
    expect(finished.entries.first.usage.correction.thoughtsTokens, 5);
    expect(finished.entries.first.usage.speech.candidatesTokens, 50);
    expect(finished.entries.last.usage.speech, TokenUsage.zero);
  });

  test('APIキー未設定なら採点せず notice を出す', () async {
    settings = FakeSettingsRepository();
    final store = build();
    addTearDown(store.dispose);

    await store.startRecording();
    await store.submit();

    expect(notices.single, isA<DrillApiKeyMissingNotice>());
    expect(store.resultMode.value, isFalse);
    expect(store.recording.value, isTrue);
    expect(speech.stopCalled, isFalse);
  });

  test('文字起こしが空なら pre に戻して録り直しを促す', () async {
    speech.stopResult = '   ';
    final store = build();
    addTearDown(store.dispose);

    await store.startRecording();
    await store.submit();

    expect(notices.single, isA<DrillEmptyTranscriptNotice>());
    expect(store.resultMode.value, isFalse);
    expect(store.secondsLeft.value, 30);
    expect(correction.requests, isEmpty);
  });

  test('添削に失敗すると stage 1 に留まり、再試行できる notice を出す', () async {
    correction.error = const AppFailure(FailureKind.serverError);
    final store = build();
    addTearDown(store.dispose);

    await store.startRecording();
    await store.submit();

    final failure = notices.single as DrillFailureNotice;
    expect(failure.failure.kind, FailureKind.serverError);
    expect(failure.retryable, isTrue);
    expect(store.resultMode.value, isTrue);
    expect(store.stagedSpoken.value, isNotNull);
    expect(store.feedback.value, isNull);
    expect(history.results.value, isEmpty);

    // 再試行で成功する
    correction.error = null;
    await store.submit();
    expect(store.feedback.value?.score, 85);
    expect(history.results.value, hasLength(1));
  });

  test('飛ばすと録音を破棄し、未採点（スコア0）で保存して SRS に登録する', () async {
    final store = build();
    addTearDown(store.dispose);

    await store.startRecording();
    await store.skip();

    expect(speech.cancelCalled, isTrue);
    expect(speech.stopCalled, isFalse);
    expect(store.skipped.value, isTrue);
    expect(store.feedback.value?.isUnanswered, isTrue);
    expect(store.feedback.value?.explanation, 'skipped');
    expect(history.results.value.single.feedback.score, 0);
    expect(srs.items.value.single.sentenceId, 's700-001');
  });

  test('preのまま時間切れになると時間切れとして自動保存される', () async {
    // Timer.periodic（1秒刻み）を実時間で待つ。制限時間1秒なので最初の tick で時間切れになる
    final store = build(questionSeconds: 1);
    addTearDown(store.dispose);
    expect(store.secondsLeft.value, 1);

    await Future<void>.delayed(const Duration(milliseconds: 1300));

    expect(store.secondsLeft.value, 0);
    expect(store.resultMode.value, isTrue);
    expect(store.feedback.value?.explanation, 'timeout');
    expect(store.skipped.value, isFalse);
    expect(history.results.value.single.feedback.score, 0);
  });

  test('中国語では文字起こしのピンインから声調の気づきを保存する', () async {
    settings = FakeSettingsRepository(
      initial: const AppSettings(learningLanguage: LearningLanguage.chinese),
      apiKey: 'key',
    );
    speech
      ..stopResult = '我要睡'
      ..stopReading = 'wǒ yào shuì';
    correction.feedback = const CompositionFeedback(
      score: 90,
      isAcceptable: true,
      corrected: '我要水。',
      explanation: '',
      comparison: '',
    );
    final store = build(
      sentences: const [
        Sentence(
          id: 'z3-001',
          ja: '水がほしい。',
          target: '我要水。',
          theme: 'daily',
          tips: '',
          level: 3,
          reading: 'Wǒ yào shuǐ',
        ),
      ],
    );
    addTearDown(store.dispose);

    await store.startRecording();
    await store.submit();

    expect(store.stagedReading.value, 'wǒ yào shuì');
    expect(correction.requests.single.learningLanguage, 'zh');
    final saved = history.results.value.single;
    expect(saved.language, 'zh');
    expect(saved.toneNotes, hasLength(1));
    expect(saved.toneNotes!.single.actualTone, 4);
  });

  test('復習モードでは applyReviewResult で SRS を進める', () async {
    await srs.registerFailure(
      sentenceId: 's700-001',
      language: 'en',
      level: 700,
    );
    final store = build(sentences: [_sentence(1)], isReview: true);
    addTearDown(store.dispose);

    await store.startRecording();
    await store.submit();

    expect(srs.items.value.single.stage, 1);
  });

  test('もう一度で pre に戻り、次の問でカウントダウンが再開する', () async {
    final store = build();
    addTearDown(store.dispose);
    await store.startRecording();
    await store.submit();

    store.retryCurrent();

    expect(store.resultMode.value, isFalse);
    expect(store.feedback.value, isNull);
    expect(store.secondsLeft.value, 30);
  });

  test('dispose で録音・読み上げサービスを解放する', () {
    final store = build();
    store.dispose();

    expect(speech.disposeCount, 1);
    expect(tts.disposeCount, 1);
    expect(store.disposed, isTrue);
  });
}
