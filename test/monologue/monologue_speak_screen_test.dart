// MonologueSpeakScreen〜MonologueFeedbackScreenのウィジェットテスト。
//
// SpeechInputServiceはフェイクに差し替え、GeminiServiceはhttp.testing.MockClient
// を注入した実インスタンスを使う（実際の通信は行わない）。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pj_walter/models/topic.dart';
import 'package:pj_walter/screens/monologue/monologue_speak_screen.dart';
import 'package:pj_walter/services/gemini_service.dart';
import 'package:pj_walter/services/history_service.dart';
import 'package:pj_walter/services/settings_service.dart';
import 'package:pj_walter/services/speech_input_service.dart';
import 'package:provider/provider.dart';

import '../test_support/hive_test_support.dart';

/// テスト用のフェイク音声入力サービス。
///
/// [start]は常に固定のpartialテキストを1回流し、[stop]はあらかじめ設定した
/// [stopResult]を返す。
class FakeSpeechInputService implements SpeechInputService {
  String stopResult = 'this is my spoken monologue';
  bool startCalled = false;
  bool stopCalled = false;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<void> start({
    required void Function(String text) onPartial,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    startCalled = true;
    onPartial('partial text...');
  }

  @override
  Future<String> stop() async {
    stopCalled = true;
    return stopResult;
  }

  @override
  void dispose() {}
}

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
};

http.Response _jsonResponse(Object payload, int statusCode) => http.Response(
  jsonEncode(payload),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _topic = Topic(
  id: 't-001',
  ja: '今日の朝ごはんについて話してください',
  en: 'Talk about what you had for breakfast today',
  theme: 'daily',
);

void main() {
  late SettingsService settings;
  late HistoryService historyService;

  setUp(() async {
    await initTestHive();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    final settingsBox = await Hive.openBox('settings');
    settings = SettingsService(settingsBox: settingsBox);
    await settings.init();
    await settings.setApiKey('test-api-key');

    historyService = HistoryService(
      drillResultsBox: await Hive.openBox('drill_results'),
      monologueResultsBox: await Hive.openBox('monologue_results'),
      srsItemsBox: await Hive.openBox('srs_items'),
      phrasesBox: await Hive.openBox('phrases'),
      dailyStatsBox: await Hive.openBox('daily_stats'),
    );
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  // MultiProviderはMaterialApp自体を包む（main.dartの実際の構成と同じ）。
  // MonologueSpeakScreenはGemini添削後にpushReplacementで別ルート
  // （MonologueFeedbackScreen）へ遷移するため、providerをhome配下ではなく
  // Navigatorの祖先に置かないと遷移後の画面からcontext.read()できない。
  Widget buildApp({
    required GeminiService geminiService,
    required FakeSpeechInputService speechInputService,
    int seconds = 30,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        ChangeNotifierProvider<HistoryService>.value(value: historyService),
        Provider<GeminiService>.value(value: geminiService),
      ],
      child: MaterialApp(
        home: MonologueSpeakScreen(
          topic: _topic,
          seconds: seconds,
          speechInputService: speechInputService,
        ),
      ),
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
              'reason_ja': '文頭は大文字にします',
            },
          ],
          'useful_phrases': [
            {'en': 'It slipped my mind.', 'ja': 'うっかり忘れていた'},
          ],
          'overall_feedback_ja': '良い流れで話せています。文頭の大文字化に気をつけましょう。',
        }),
        200,
      );
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    // お題・残り時間が表示されている
    expect(find.text(_topic.ja), findsOneWidget);
    expect(find.text(_topic.en), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);

    // ボタン操作なしで音声入力が自動開始されている。
    // 操作ボタンは「停止して添削」1つだけ。編集用の入力欄・録り直し導線は無い
    expect(speechInputService.startCalled, isTrue);
    expect(find.text('聞き取り中'), findsOneWidget);
    expect(find.text('停止して添削'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('録り直す'), findsNothing);

    // 「停止して添削」1タップ＝聞き取り終了→文字起こし→添削→フィードバック画面へ
    //
    // GeminiService呼び出しとHistoryServiceによる実際のHive書き込み
    // （ファイルI/O）を伴うため、tester.runAsync()で実の非同期ゾーンに切り替える
    // （drill_screen_testの答え合わせテストと同じ理由）。
    await tester.runAsync(() async {
      await tester.tap(find.text('停止して添削'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
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
    expect(historyService.monologueHistory, hasLength(1));
    expect(historyService.monologueHistory.first.topicId, 't-001');
    expect(
      historyService.monologueHistory.first.transcript,
      'this is my spoken monologue',
    );

    // ＋追加 -> チェック・追加済み表示に変わる
    expect(historyService.phrases, isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.text('＋追加'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(historyService.phrases, hasLength(1));
    expect(historyService.phrases.first.en, 'It slipped my mind.');
    expect(historyService.phrases.first.source, 't-001');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('追加済み'), findsOneWidget);
    expect(find.text('＋追加'), findsNothing);
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
          'overall_feedback_ja': '一気に添削しました。',
        }),
        200,
      );
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    // 自動開始された録音中のまま「停止して添削」を押す
    expect(speechInputService.startCalled, isTrue);
    expect(speechInputService.stopCalled, isFalse);
    await tester.runAsync(() async {
      await tester.tap(find.text('停止して添削'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    // 停止（文字起こし）→添削→フィードバック画面遷移まで1タップで完了する
    expect(speechInputService.stopCalled, isTrue);
    expect(find.text('フィードバック'), findsOneWidget);
    expect(find.text('75'), findsOneWidget);
    expect(historyService.monologueHistory, hasLength(1));
    expect(
      historyService.monologueHistory.first.transcript,
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
          'overall_feedback_ja': '時間切れでも添削しました。',
        }),
        200,
      );
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService();

    // pumpWidgetから制限時間経過までをtester.runAsync()内（実のZone）で行う
    // （drill_screen_testの時間切れテストと同じ理由。実時間で動く本物のTimerに
    // なり、Hive書き込みも通常どおり完了する）。
    await tester.runAsync(() async {
      await tester.pumpWidget(
        buildApp(
          geminiService: geminiService,
          speechInputService: speechInputService,
          // 制限時間を2秒に短縮し、実時間での待ち時間を最小限にする
          seconds: 2,
        ),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 3000));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    // ボタン操作なしで、聞き取り終了（文字起こし）→添削→画面遷移まで完了している
    expect(speechInputService.stopCalled, isTrue);
    expect(find.text('フィードバック'), findsOneWidget);
    expect(find.text('時間切れでも添削しました。'), findsOneWidget);
    expect(historyService.monologueHistory, hasLength(1));
    expect(
      historyService.monologueHistory.first.transcript,
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
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    // 録音中に「停止して添削」を押してもキー未設定ならダイアログを出し、
    // 録音は止めない（キー設定後にそのまま続行できる）
    await tester.tap(find.text('停止して添削'));
    await tester.pump();

    expect(find.text('APIキーが未設定です'), findsOneWidget);
    expect(speechInputService.stopCalled, isFalse);
    expect(historyService.monologueHistory, isEmpty);
  });

  testWidgets('GeminiExceptionが発生するとSnackBarとリトライボタンが表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = MockClient((request) async {
      return http.Response('server error', 500);
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('停止して添削'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    // 録り直し導線が出ている
    expect(find.text('録り直す'), findsOneWidget);
    expect(historyService.monologueHistory, isEmpty);
  });
}
