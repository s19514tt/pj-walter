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
import 'package:pj_walter/models/token_usage.dart';
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
  Future<void> start({required void Function(String text) onPartial}) async {
    startCalled = true;
    onPartial('partial text...');
  }

  @override
  Future<SpeechInputResult> stop() async {
    stopCalled = true;
    return SpeechInputResult(text: stopResult, usage: TokenUsage.zero);
  }

  @override
  void dispose() {}
}

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
          seconds: 30,
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

    // マイクをタップ -> 音声入力開始（partialがリアルタイム表示される）
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    expect(speechInputService.startCalled, isTrue);
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.text('partial text...'), findsOneWidget);

    // もう一度マイクをタップ -> 音声入力停止・文字起こし取得
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(speechInputService.stopCalled, isTrue);
    expect(find.text('this is my spoken monologue'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // 添削してもらう -> Gemini添削 -> フィードバック画面へ遷移
    //
    // GeminiService呼び出しとHistoryServiceによる実際のHive書き込み
    // （ファイルI/O）を伴うため、tester.runAsync()で実の非同期ゾーンに切り替える
    // （drill_screen_testの答え合わせテストと同じ理由）。
    await tester.runAsync(() async {
      await tester.tap(find.text('添削してもらう'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    // 画面遷移アニメーション・ScoreRingのアニメーション（いずれも有限）を
    // 流し切る。
    await tester.pumpAndSettle();

    expect(find.text('フィードバック'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(find.text('良い流れで話せています。文頭の大文字化に気をつけましょう。'), findsOneWidget);
    expect(
      find.text('This is my corrected monologue overall.'),
      findsOneWidget,
    );
    expect(find.text('This is my corrected monologue.'), findsOneWidget);
    expect(find.text('うっかり忘れていた'), findsOneWidget);

    // 履歴に保存されている
    expect(historyService.monologueHistory, hasLength(1));
    expect(historyService.monologueHistory.first.topicId, 't-001');

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

    await tester.enterText(find.byType(TextField), 'manual transcript');
    await tester.tap(find.text('添削してもらう'));
    await tester.pump();

    expect(find.text('APIキーが未設定です'), findsOneWidget);
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

    await tester.enterText(find.byType(TextField), 'manual transcript');
    await tester.tap(find.text('添削してもらう'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    expect(historyService.monologueHistory, isEmpty);
  });
}
