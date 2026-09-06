// MonologueSpeakScreen〜MonologueFeedbackScreenのウィジェットテスト。
//
// SpeechInputServiceはフェイクに差し替え、フィードバックは http.testing.MockClient
// を注入した GeminiMonologueReviewRepository を使う（実際の通信は行わない）。
// 履歴・フレーズ帳・統計は Hive 実装の Repository。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pj_walter/core/data/gemini_client.dart';
import 'package:pj_walter/features/content/domain/topic.dart';
import 'package:pj_walter/features/monologue/data/gemini_monologue_review_repository.dart';
import 'package:pj_walter/features/monologue/data/hive_monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_history_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_review_repository.dart';
import 'package:pj_walter/features/monologue/domain/record_monologue_result.dart';
import 'package:pj_walter/features/monologue/presentation/monologue_speak_screen.dart';
import 'package:pj_walter/features/review/data/hive_phrase_repository.dart';
import 'package:pj_walter/features/review/domain/phrase_repository.dart';
import 'package:pj_walter/features/settings/domain/settings_repository.dart';
import 'package:pj_walter/features/speech/speech_module.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';
import 'package:pj_walter/features/stats/domain/study_stats_repository.dart';

import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/fake_speech_input_service.dart';
import '../../../test_support/hive_test_support.dart';
import '../../../test_support/test_app.dart';

/// Gemini応答のエンベロープ。usageMetadataはトークン計測のテスト用に固定値
/// （入力100・出力20・思考5）を付ける。
Map<String, dynamic> _geminiEnvelope(Object payload) => {
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': payload is String ? payload : jsonEncode(payload)},
        ],
      },
    },
  ],
  'usageMetadata': {
    'promptTokenCount': 100,
    'candidatesTokenCount': 20,
    'thoughtsTokenCount': 5,
    'totalTokenCount': 125,
  },
};

http.Response _jsonResponse(Object payload, int statusCode) => http.Response(
  jsonEncode(payload),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _topic = Topic(
  id: 't-001',
  ja: '今日の朝ごはんについて話してください',
  target: 'Talk about what you had for breakfast today',
  theme: 'daily',
);

void main() {
  late GetIt getIt;
  late FakeSettingsRepository settings;
  late MonologueHistoryRepository monologueHistory;
  late PhraseRepository phrases;

  setUp(() async {
    await initTestHive();
    getIt = GetIt.asNewInstance()..allowReassignment = true;
    settings = FakeSettingsRepository(apiKey: 'test-api-key');
    monologueHistory = HiveMonologueHistoryRepository(
      await Hive.openBox('monologue_results'),
    );
    phrases = HivePhraseRepository(await Hive.openBox('phrases'));
    final stats = HiveStudyStatsRepository(await Hive.openBox('daily_stats'));
    getIt
      ..registerSingleton<SettingsRepository>(settings)
      ..registerSingleton<MonologueHistoryRepository>(monologueHistory)
      ..registerSingleton<PhraseRepository>(phrases)
      ..registerSingleton<StudyStatsRepository>(stats)
      ..registerSingleton<RecordMonologueResult>(
        RecordMonologueResult(history: monologueHistory, stats: stats),
      );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  /// [client] をフィードバック API の応答に使い、[speechInputService] を録音に使う
  /// 配線で [MonologueSpeakScreen] を組み立てる。
  Widget buildApp({
    required http.Client client,
    required FakeSpeechInputService speechInputService,
    int seconds = 30,
  }) {
    getIt
      ..registerSingleton<MonologueReviewRepository>(
        GeminiMonologueReviewRepository(
          GeminiClient(apiKey: () => settings.apiKey.peek(), client: client),
        ),
      )
      ..registerSingleton<SpeechInputServiceFactory>((_) => speechInputService);
    return scopedApp(
      getIt: getIt,
      home: MonologueSpeakScreen(topic: _topic, seconds: seconds),
    );
  }

  testWidgets('スピーキング→添削→フィードバック表示→フレーズ追加 の基本フロー', (tester) async {
    // フィードバック画面は多数のカードを縦に並べるため、デフォルトの
    // テストビューポートでは末尾のボタンがスクロール範囲外になる。
    // ビューポートを縦に広げて回避する（drill_screen_testと同じ理由）。
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = MockClient((request) async {
      return _jsonResponse(
        _geminiEnvelope({
          'fluency_score': 82,
          'corrected_transcript': 'This is my corrected monologue overall.',
          'corrections': [
            {
              'original': 'this is my spoken monologue',
              'corrected': 'This is my corrected monologue.',
              'reason': '文頭は大文字にします',
            },
          ],
          'useful_phrases': [
            {'target': 'It slipped my mind.', 'ja': 'うっかり忘れていた'},
          ],
          'overall_feedback': '良い流れで話せています。文頭の大文字化に気をつけましょう。',
        }),
        200,
      );
    });
    final speechInputService = FakeSpeechInputService(
      stopResult: 'this is my spoken monologue',
    );

    await tester.pumpWidget(
      buildApp(client: client, speechInputService: speechInputService),
    );
    await tester.pump();

    // お題・残り時間が表示されている
    expect(find.text(_topic.ja), findsOneWidget);
    expect(find.text(_topic.target), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);

    // pre: 録音は始まっておらず、主ボタンは「話しはじめる」だけ
    expect(speechInputService.startCalled, isFalse);
    expect(find.text('聞き取り前'), findsOneWidget);
    expect(find.text('話しはじめる'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // 話しはじめる → 録音中表示・フィードバックを見るボタンに切り替わる
    await tester.tap(find.text('話しはじめる'));
    await tester.pump();
    expect(speechInputService.startCalled, isTrue);
    expect(find.text('聞き取り中'), findsOneWidget);
    expect(find.text('フィードバックを見る'), findsOneWidget);

    // 「フィードバックを見る」1タップ＝聞き取り終了→文字起こし→添削→フィードバック画面へ
    //
    // GeminiService呼び出しとHistoryServiceによる実際のHive書き込み
    // （ファイルI/O）を伴うため、tester.runAsync()で実の非同期ゾーンに切り替える
    // （drill_screen_testの答え合わせテストと同じ理由）。
    await tester.runAsync(() async {
      await tester.tap(find.text('フィードバックを見る'));
      // 遷移フレームを描画し、フィードバック画面のpostFrameで始まる
      // パイプライン（文字起こし→添削→Hive保存）を実ゾーンで走らせる
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    // 画面遷移アニメーション・ScoreRingのアニメーション（いずれも有限）を
    // 流し切る。
    await tester.pumpAndSettle();
    expect(speechInputService.stopCalled, isTrue);

    expect(find.text('フィードバック'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(find.text('良い流れで話せています。文頭の大文字化に気をつけましょう。'), findsOneWidget);
    expect(
      find.text('This is my corrected monologue overall.'),
      findsOneWidget,
    );
    expect(find.text('This is my corrected monologue.'), findsOneWidget);
    expect(find.text('うっかり忘れていた'), findsOneWidget);

    // 履歴に保存されている（回答は文字起こし結果）
    expect(monologueHistory.results.value, hasLength(1));
    expect(monologueHistory.results.value.first.topicId, 't-001');
    expect(
      monologueHistory.results.value.first.transcript,
      'this is my spoken monologue',
    );

    // ＋保存 -> 保存済表示に変わる
    expect(phrases.phrases.value, isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.text('＋保存'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(phrases.phrases.value, hasLength(1));
    expect(phrases.phrases.value.first.target, 'It slipped my mind.');
    expect(phrases.phrases.value.first.source, 't-001');
    expect(find.text('保存済'), findsOneWidget);
    expect(find.text('＋保存'), findsNothing);
  });

  testWidgets('録音中に添削してもらうを押すと聞き取り終了→文字起こし→添削まで一気に走る', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = MockClient((request) async {
      return _jsonResponse(
        _geminiEnvelope({
          'fluency_score': 75,
          'corrected_transcript': 'One-press corrected monologue.',
          'corrections': <Map<String, dynamic>>[],
          'useful_phrases': <Map<String, dynamic>>[],
          'overall_feedback': '一気に添削しました。',
        }),
        200,
      );
    });
    final speechInputService = FakeSpeechInputService(
      stopResult: 'this is my spoken monologue',
    );

    await tester.pumpWidget(
      buildApp(client: client, speechInputService: speechInputService),
    );
    await tester.pump();

    // 話しはじめる（録音開始）→そのまま「フィードバックを見る」を押す
    await tester.tap(find.text('話しはじめる'));
    await tester.pump();
    expect(speechInputService.startCalled, isTrue);
    expect(speechInputService.stopCalled, isFalse);
    await tester.runAsync(() async {
      await tester.tap(find.text('フィードバックを見る'));
      // 遷移フレーム＋パイプライン（実ゾーン）
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    // 停止（文字起こし）→添削→フィードバック画面遷移まで1タップで完了する
    expect(speechInputService.stopCalled, isTrue);
    expect(find.text('フィードバック'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(monologueHistory.results.value, hasLength(1));
    expect(
      monologueHistory.results.value.first.transcript,
      'this is my spoken monologue',
    );
  });

  testWidgets('時間切れでも文字起こし→添削まで自動で実行される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = MockClient((request) async {
      return _jsonResponse(
        _geminiEnvelope({
          'fluency_score': 70,
          'corrected_transcript': 'Timeout corrected monologue.',
          'corrections': <Map<String, dynamic>>[],
          'useful_phrases': <Map<String, dynamic>>[],
          'overall_feedback': '時間切れでも添削しました。',
        }),
        200,
      );
    });
    final speechInputService = FakeSpeechInputService(
      stopResult: 'this is my spoken monologue',
    );

    // pumpWidgetから制限時間経過までをtester.runAsync()内（実のZone）で行う
    // （drill_screen_testの時間切れテストと同じ理由。実時間で動く本物のTimerに
    // なり、Hive書き込みも通常どおり完了する）。
    await tester.runAsync(() async {
      await tester.pumpWidget(
        buildApp(
          client: client,
          speechInputService: speechInputService,
          // 制限時間を2秒に短縮し、実時間での待ち時間を最小限にする
          seconds: 2,
        ),
      );
      await tester.pump();
      // カウントダウンは画面表示と同時に始まっている。録音を開始して時間切れを待つ
      await tester.tap(find.text('話しはじめる'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      // 時間切れ→フィードバック画面へ遷移。遷移フレームを描画して
      // パイプライン（文字起こし→添削→Hive保存）を実ゾーンで走らせる
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    // ボタン操作なしで、聞き取り終了（文字起こし）→添削→画面遷移まで完了している
    expect(speechInputService.stopCalled, isTrue);
    expect(find.text('フィードバック'), findsOneWidget);
    expect(find.text('時間切れでも添削しました。'), findsOneWidget);
    expect(monologueHistory.results.value, hasLength(1));
    expect(
      monologueHistory.results.value.first.transcript,
      'this is my spoken monologue',
    );
  });

  testWidgets('APIキー未設定で添削してもらうを押すと設定誘導ダイアログが出る', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await settings.deleteApiKey();
    final client = MockClient((request) async {
      fail('APIキー未設定時は通信しない');
    });
    final speechInputService = FakeSpeechInputService(
      stopResult: 'this is my spoken monologue',
    );

    await tester.pumpWidget(
      buildApp(client: client, speechInputService: speechInputService),
    );
    await tester.pump();

    // 録音中に「フィードバックを見る」を押してもキー未設定ならダイアログを出し、
    // 録音は止めない（キー設定後にそのまま続行できる）
    await tester.tap(find.text('話しはじめる'));
    await tester.pump();
    await tester.tap(find.text('フィードバックを見る'));
    await tester.pump();

    expect(find.text('APIキーが未設定です'), findsOneWidget);
    expect(speechInputService.stopCalled, isFalse);
    expect(monologueHistory.results.value, isEmpty);
  });

  testWidgets('GeminiExceptionが発生するとSnackBarとリトライボタンが表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = MockClient((request) async {
      return http.Response('server error', 500);
    });
    final speechInputService = FakeSpeechInputService(
      stopResult: 'this is my spoken monologue',
    );

    await tester.pumpWidget(
      buildApp(client: client, speechInputService: speechInputService),
    );
    await tester.pump();

    await tester.tap(find.text('話しはじめる'));
    await tester.pump();
    await tester.tap(find.text('フィードバックを見る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 画面遷移（旧ルートが残っている間はSnackBarが両Scaffoldに出る）を流し切る
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    // 段階表示のstage 1（文字起こしは表示済み・添削はスケルトン）に留まる
    expect(find.text('this is my spoken monologue'), findsOneWidget);
    expect(monologueHistory.results.value, isEmpty);
  });
}
