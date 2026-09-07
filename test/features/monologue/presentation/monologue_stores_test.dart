// TopicSelectStore / MonologueSpeakStore / MonologueFeedbackStore のユニットテスト。

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/core/domain/app_failure.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/content/domain/topic.dart';
import 'package:pj_walter/features/monologue/data/hive_monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_result.dart';
import 'package:pj_walter/features/monologue/domain/record_monologue_result.dart';
import 'package:pj_walter/features/monologue/presentation/monologue_feedback_store.dart';
import 'package:pj_walter/features/monologue/presentation/monologue_speak_store.dart';
import 'package:pj_walter/features/monologue/presentation/topic_select_store.dart';
import 'package:pj_walter/features/review/data/hive_phrase_repository.dart';
import 'package:pj_walter/features/settings/domain/app_settings.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';

import '../../../test_support/fake_monologue_review_repository.dart';
import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/fake_speech_input_service.dart';
import '../../../test_support/hive_test_support.dart';

const _topic = Topic(
  id: 't-001',
  ja: '今日の朝ごはんについて話してください',
  target: 'Talk about what you had for breakfast today',
  theme: 'daily',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TopicSelectStore', () {
    test('発話時間の既定は設定値、テーマ変更でお題を読み直す', () async {
      final store = TopicSelectStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(
          initial: const AppSettings(monologueSeconds: 120),
        ),
      );
      addTearDown(store.dispose);

      expect(store.seconds.value, 120);
      expect(store.theme.value, isNull);
      final all = await store.topics.future;
      expect(all, hasLength(60));

      store.selectTheme('travel');
      expect(store.topics.value.isLoading, isTrue);
      final travel = await store.topics.future;
      expect(travel, isNotEmpty);
      expect(travel.every((t) => t.theme == 'travel'), isTrue);

      store.selectSeconds(30);
      expect(store.seconds.value, 30);
    });

    test('設定の秒数が選択肢に無ければ1分にする', () {
      final store = TopicSelectStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(
          initial: const AppSettings(monologueSeconds: 45),
        ),
      );
      addTearDown(store.dispose);

      expect(store.seconds.value, 60);
    });

    test('pickRandom は現在のテーマから1題選ぶ', () async {
      final store = TopicSelectStore(
        content: AssetContentRepository(),
        settings: FakeSettingsRepository(),
        random: Random(1),
      );
      addTearDown(store.dispose);
      store.selectTheme('business');

      final topic = await store.pickRandom();

      expect(topic, isNotNull);
      expect(topic!.theme, 'business');
    });
  });

  group('MonologueSpeakStore', () {
    late FakeSpeechInputService speech;
    final notices = <MonologueSpeakNotice>[];

    setUp(() {
      speech = FakeSpeechInputService();
      notices.clear();
    });

    MonologueSpeakStore build({String? apiKey = 'key', int seconds = 30}) {
      final store = MonologueSpeakStore(
        topic: _topic,
        seconds: seconds,
        speechInput: speech,
        settings: FakeSettingsRepository(apiKey: apiKey),
      );
      store.notice.subscribe((n) {
        if (n != null) notices.add(n);
      });
      return store;
    }

    test('話しはじめる→フィードバックを見る で録音サービスを引き渡す', () async {
      final store = build();

      expect(store.recording.value, isFalse);
      expect(store.ratio.value, 1.0);
      await store.startRecording();
      expect(speech.startCalled, isTrue);
      expect(store.recording.value, isTrue);

      store.submit();

      final handOff = notices.single as MonologueHandOffNotice;
      expect(handOff.speechInput, same(speech));
      // 引き渡した後は Store の dispose で録音サービスを破棄しない
      store.dispose();
      expect(speech.disposeCount, 0);
    });

    test('APIキー未設定なら引き渡さず notice を出す', () async {
      final store = build(apiKey: null);
      addTearDown(store.dispose);

      await store.startRecording();
      store.submit();

      expect(notices.single, isA<MonologueApiKeyMissingNotice>());
      expect(store.recording.value, isTrue);
    });

    test('pre のまま時間切れになると仕切り直す', () async {
      final store = build(seconds: 1);
      addTearDown(store.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 1300));

      expect(notices.single, isA<MonologueTimeUpNotice>());
      expect(store.secondsLeft.value, 1);
    });

    test('録音中の時間切れは submit と同じ', () async {
      final store = build(seconds: 1);
      addTearDown(store.dispose);
      await store.startRecording();

      await Future<void>.delayed(const Duration(milliseconds: 1300));

      expect(notices.single, isA<MonologueHandOffNotice>());
    });

    test('引き渡す前に dispose すると録音サービスを破棄する', () {
      build().dispose();
      expect(speech.disposeCount, 1);
    });
  });

  group('MonologueFeedbackStore', () {
    late HiveMonologueHistoryRepository history;
    late HivePhraseRepository phrases;
    late RecordMonologueResult record;
    late FakeMonologueReviewRepository review;
    final notices = <MonologueFeedbackNotice>[];

    setUp(() async {
      await initTestHive();
      history = HiveMonologueHistoryRepository(
        await Hive.openBox('monologue_results'),
      );
      phrases = HivePhraseRepository(await Hive.openBox('phrases'));
      record = RecordMonologueResult(
        history: history,
        stats: HiveStudyStatsRepository(await Hive.openBox('daily_stats')),
      );
      review = FakeMonologueReviewRepository();
      notices.clear();
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    MonologueFeedbackStore build({
      FakeSpeechInputService? speech,
      MonologueResult? initialResult,
    }) {
      final store = MonologueFeedbackStore(
        topic: _topic,
        seconds: 60,
        uiLocale: 'ja',
        review: review,
        recordResult: record,
        phrases: phrases,
        settings: FakeSettingsRepository(),
        initialResult: initialResult,
        speechInput: speech,
      );
      store.notice.subscribe((n) {
        if (n != null) notices.add(n);
      });
      return store;
    }

    test('停止→文字起こし→添削→保存 と段階が進み、フレーズを保存できる', () async {
      final speech = FakeSpeechInputService(stopResult: ' my monologue ');
      final store = build(speech: speech);
      addTearDown(store.dispose);

      expect(store.transcript.value, isNull);
      await store.start();

      expect(speech.stopCalled, isTrue);
      expect(store.transcript.value, 'my monologue');
      expect(store.result.value?.feedback.fluencyScore, 82);
      expect(store.grading.value, isFalse);
      expect(review.requests.single.uiLocale, 'ja');
      expect(review.requests.single.learningLanguage, 'en');
      expect(review.requests.single.seconds, 60);
      expect(history.results.value.single.transcript, 'my monologue');

      await store.addPhrase(1);
      await store.addPhrase(1);

      expect(store.addedPhraseIndices.value, {1});
      expect(phrases.phrases.value.single.target, 'Long story short.');
      expect(phrases.phrases.value.single.source, 't-001');
      expect(notices, isEmpty);
    });

    test('文字起こしに失敗すると戻る notice を出す', () async {
      final speech = FakeSpeechInputService()
        ..stopError = const AppFailure(FailureKind.noSpeech);
      final store = build(speech: speech);
      addTearDown(store.dispose);

      await store.start();

      final notice = notices.single as MonologueTranscriptionFailedNotice;
      expect(notice.failure?.kind, FailureKind.noSpeech);
      expect(store.transcript.value, isNull);
    });

    test('文字起こしが空でも戻る notice を出す（failure は null）', () async {
      final store = build(speech: FakeSpeechInputService(stopResult: '  '));
      addTearDown(store.dispose);

      await store.start();

      final notice = notices.single as MonologueTranscriptionFailedNotice;
      expect(notice.failure, isNull);
      expect(review.requests, isEmpty);
    });

    test('添削に失敗すると stage 1 に留まり、grade で再試行できる', () async {
      review.error = const AppFailure(FailureKind.serverError);
      final store = build(speech: FakeSpeechInputService());
      addTearDown(store.dispose);

      await store.start();

      expect(notices.single, isA<MonologueGradingFailedNotice>());
      expect(store.transcript.value, isNotNull);
      expect(store.result.value, isNull);
      expect(history.results.value, isEmpty);

      review.error = null;
      await store.grade();
      expect(store.result.value, isNotNull);
      expect(history.results.value, hasLength(1));
    });

    test('完成済みの結果を渡すと最初から stage 2 で、start は何もしない', () async {
      final result = MonologueResult(
        id: 'm-1',
        topicId: 't-001',
        language: 'en',
        seconds: 60,
        transcript: 'done',
        timestamp: DateTime(2026, 9, 6),
        feedback: review.feedback,
      );
      final store = build(initialResult: result);
      addTearDown(store.dispose);

      await store.start();

      expect(store.result.value, result);
      expect(review.requests, isEmpty);
    });

    test('dispose で受け取った録音サービスを破棄する', () {
      final speech = FakeSpeechInputService();
      build(speech: speech).dispose();
      expect(speech.disposeCount, 1);
    });
  });
}
