// DrillScreenのウィジェットテスト。
//
// SpeechInputServiceはフェイクに差し替え、GeminiServiceはhttp.testing.MockClient
// を注入した実インスタンスを使う（実際の通信は行わない）。
// 発音評価はGeminiPronunciationAssessor（実装）経由で同じMockClientに届くため、
// リクエストボディに音声（inline_data）が含まれるかどうかで応答を振り分ける。

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/screens/composition/drill_screen.dart';
import 'package:pj_walter/services/gemini_service.dart';
import 'package:pj_walter/services/history_service.dart';
import 'package:pj_walter/services/settings_service.dart';
import 'package:pj_walter/services/speech_input_service.dart';
import 'package:provider/provider.dart';

import '../test_support/hive_test_support.dart';

/// テスト用のフェイク音声入力サービス。
///
/// [start]は常に固定のpartialテキストを1回流し、[stop]は
/// あらかじめ設定した[stopResult]（またはエラー）をダミー録音データ付きで返す。
class FakeSpeechInputService implements SpeechInputService {
  String stopResult = 'this is my spoken answer';
  Object? stopError;
  bool startCalled = false;
  bool stopCalled = false;
  static final dummyAudio = Uint8List.fromList([1, 2, 3, 4]);

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
    final error = stopError;
    if (error != null) throw error;
    return SpeechInputResult(
      text: stopResult,
      audioBytes: dummyAudio,
      mimeType: 'audio/wav',
    );
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

/// 発音評価のリクエスト（音声inline_data付き）かどうか。
bool _isPronunciationRequest(http.Request request) =>
    request.body.contains('inline_data');

Map<String, dynamic> _pronunciationPayload() => {
  'score': 78,
  'words': [
    {'word': 'recognized', 'score': 60, 'issue_ja': 'r が l に聞こえます'},
    {'word': 'by', 'score': 95, 'issue_ja': ''},
    {'word': 'mic', 'score': 90, 'issue_ja': ''},
  ],
  'advice_ja': 'r の発音を意識しましょう。リズムは良好です。',
};

Sentence _sentence(int i) => Sentence(
  id: 's700-${i.toString().padLeft(3, '0')}',
  ja: '日本語の例文$i',
  en: 'English sentence $i',
  theme: 'daily',
  tips: 'tips $i',
  level: 700,
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

  Widget buildApp({
    required List<Sentence> sentences,
    required GeminiService geminiService,
    required FakeSpeechInputService speechInputService,
    int questionSeconds = 30,
  }) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<HistoryService>.value(value: historyService),
          Provider<GeminiService>.value(value: geminiService),
        ],
        child: DrillScreen(
          sentences: sentences,
          level: 700,
          theme: 'daily',
          speechInputService: speechInputService,
          questionSeconds: questionSeconds,
        ),
      ),
    );
  }

  testWidgets('答え合わせ→添削結果表示→次へ→2問目→まとめ画面 の基本フロー', (tester) async {
    // 添削結果画面はスコア・バッジ・5セクションを縦に並べるため、デフォルトの
    // テストビューポートでは「次へ」ボタンがスクロール範囲外になり
    // SliverListにより未構築のままになる。ビューポートを縦に広げて回避する。
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sentences = [_sentence(1), _sentence(2)];
    var callCount = 0;
    final client = MockClient((request) async {
      callCount++;
      return _jsonResponse(
        _geminiEnvelope({
          'score': 85,
          'is_acceptable': true,
          'corrected': 'Corrected answer $callCount',
          'explanation_ja': '解説$callCount',
          'comparison_ja': '比較$callCount',
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
        sentences: sentences,
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    // 1問目: 日本語文が表示されている
    expect(find.text('日本語の例文1'), findsOneWidget);
    expect(find.text('口頭英作文 (1/2)'), findsOneWidget);

    // 手入力で回答を入力し、答え合わせ
    //
    // 答え合わせは(1)MockClient経由のGemini応答と(2)HistoryServiceによる実際の
    // Hive書き込み（ファイルI/O）を伴う。ファイルI/Oは通常のtestWidgetsの
    // FakeAsyncゾーンでは完了しないため、tester.runAsync()で実の非同期ゾーンに
    // 切り替える（widget_test.dartのHive初期化と同じ理由）。
    // また、ローディング中インジケーター（回転し続けるアニメーション）を表示するため
    // pumpAndSettle()は永久に収束しない。固定回数のpump()で応答を処理してから、
    // ScoreRing・カード出現アニメーション（いずれも有限）をpumpAndSettle()で流し切る。
    await tester.enterText(find.byType(TextField), 'my first answer');
    await tester.runAsync(() async {
      await tester.tap(find.text('答え合わせ'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    // runAsync()の外（通常のFakeAsyncゾーン）でpumpし、状態変化をフレームに反映する。
    await tester.pump();
    await tester.pumpAndSettle();

    // 添削結果が表示される
    expect(find.text('85'), findsOneWidget);
    expect(find.text('合格 🎉'), findsOneWidget);
    expect(find.text('Corrected answer 1'), findsOneWidget);
    expect(find.text('my first answer'), findsOneWidget);

    // 履歴に保存されている
    expect(historyService.drillHistory, hasLength(1));
    expect(historyService.drillHistory.first.sentenceId, 's700-001');

    // 次へ -> 2問目
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('日本語の例文2'), findsOneWidget);
    expect(find.text('口頭英作文 (2/2)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'my second answer');
    await tester.runAsync(() async {
      await tester.tap(find.text('答え合わせ'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Corrected answer 2'), findsOneWidget);

    // 次へ -> まとめ画面
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('結果まとめ'), findsOneWidget);
    expect(find.text('平均スコア'), findsOneWidget);
    // 平均スコア表示＋各問のスコア表示（Q1・Q2とも85点）で計3箇所
    expect(find.text('85'), findsNWidgets(3));
    expect(find.textContaining('日本語の例文1'), findsOneWidget);
    expect(find.textContaining('日本語の例文2'), findsOneWidget);
    expect(historyService.drillHistory, hasLength(2));
  });

  testWidgets('マイクボタンで音声入力を開始・停止しTextFieldに反映される', (tester) async {
    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('この検証では通信しない');
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService()
      ..stopResult = 'recognized by mic';

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    // マイクタップで録音開始
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    expect(speechInputService.startCalled, isTrue);
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.text('partial text...'), findsOneWidget);

    // もう一度タップで停止（停止中は回転インジケーターが出るためpumpAndSettleは使わない）
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(speechInputService.stopCalled, isTrue);
    expect(find.text('recognized by mic'), findsOneWidget);
  });

  testWidgets('GeminiExceptionが発生するとSnackBarとリトライボタンが表示される', (tester) async {
    final sentences = [_sentence(1)];
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
        sentences: sentences,
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'an answer');
    await tester.tap(find.text('答え合わせ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    // 添削結果はまだ表示されず、履歴も保存されていない
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(historyService.drillHistory, isEmpty);
  });

  testWidgets('制限時間が0になり回答が空だと時間切れとして自動保存される', (tester) async {
    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('時間切れの採点はローカルで完結するため通信しない');
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService();

    // pumpWidgetから制限時間経過までをtester.runAsync()内（実のZone）で行う。
    // DrillScreenの内部タイマーは初期化時のZoneに束縛されるため、ここで
    // 実行することで実時間で動く本物のTimerになり、Hive書き込み
    // （実ファイルI/O）も通常どおり完了する
    // （fake_asyncゾーンで開始した実I/Oは完了通知が届かず、テスト終了時に
    // 後始末がハングするため）。
    await tester.runAsync(() async {
      await tester.pumpWidget(
        buildApp(
          sentences: sentences,
          geminiService: geminiService,
          speechInputService: speechInputService,
          // 制限時間を2秒に短縮し、実時間での待ち時間を最小限にする
          // （本番はDrillScreenのデフォルト30秒のまま）。
          questionSeconds: 2,
        ),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 2200));
    });
    await tester.pump();
    // 残りの有限アニメーション（ScoreRing・カード出現）を流し切る。
    await tester.pump(const Duration(milliseconds: 900));

    // 時間切れの添削結果（模範解答が主役、修正版・あなたの発話は非表示）が表示される
    const timeoutMessage = '時間切れで回答できませんでした。模範解答を確認して復習しましょう。';
    expect(find.text(timeoutMessage), findsOneWidget);
    expect(find.text('要復習'), findsOneWidget);
    expect(find.text('あなたの発話'), findsNothing);
    expect(find.text('修正版'), findsNothing);
    expect(find.text('English sentence 1'), findsOneWidget);

    // スコア0で履歴・SRSキューに保存されている
    expect(historyService.drillHistory, hasLength(1));
    expect(historyService.drillHistory.first.feedback.score, 0);
    expect(historyService.drillHistory.first.spoken, isEmpty);
    expect(historyService.allSrsItems, hasLength(1));
  });

  testWidgets('音声入力で回答すると添削と並列で発音評価が行われ、カードと履歴に反映される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sentences = [_sentence(1)];
    var pronunciationCalls = 0;
    var correctionCalls = 0;
    final client = MockClient((request) async {
      if (_isPronunciationRequest(request)) {
        pronunciationCalls++;
        expect(request.body, contains('audio/wav'));
        expect(request.body, contains('"thinkingLevel":"medium"'));
        return _jsonResponse(_geminiEnvelope(_pronunciationPayload()), 200);
      }
      correctionCalls++;
      return _jsonResponse(
        _geminiEnvelope({
          'score': 85,
          'is_acceptable': true,
          'corrected': 'Recognized by mic.',
          'explanation_ja': '解説',
          'comparison_ja': '比較',
        }),
        200,
      );
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService()
      ..stopResult = 'recognized by mic';

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    // マイクで回答（フェイクは録音データ付きで文字起こしを返す）
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('recognized by mic'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('答え合わせ'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(correctionCalls, 1);
    expect(pronunciationCalls, 1);

    // 発音カード: 見出し・総合スコア・指摘のある単語・アドバイス
    expect(find.text('発音'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('r が l に聞こえます'), findsOneWidget);
    expect(find.text('r の発音を意識しましょう。リズムは良好です。'), findsOneWidget);

    // 履歴に発音評価が保存されている
    final saved = historyService.drillHistory.single;
    expect(saved.pronunciation?.score, 78);
    expect(saved.pronunciation?.words, hasLength(3));
  });

  testWidgets('発音評価が失敗しても添削結果は表示され、発音カードは出ない', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      if (_isPronunciationRequest(request)) {
        return http.Response('server error', 500);
      }
      return _jsonResponse(
        _geminiEnvelope({
          'score': 85,
          'is_acceptable': true,
          'corrected': 'Recognized by mic.',
          'explanation_ja': '解説',
          'comparison_ja': '比較',
        }),
        200,
      );
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService()
      ..stopResult = 'recognized by mic';

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.runAsync(() async {
      await tester.tap(find.text('答え合わせ'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('85'), findsOneWidget);
    expect(find.text('合格 🎉'), findsOneWidget);
    expect(find.text('発音'), findsNothing);
    expect(find.textContaining('発音評価を取得できませんでした'), findsOneWidget);
    expect(historyService.drillHistory.single.pronunciation, isNull);
  });

  testWidgets('手入力で回答した場合は発音評価を呼ばない', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      if (_isPronunciationRequest(request)) {
        fail('手入力回答では発音評価を呼んではいけない');
      }
      return _jsonResponse(
        _geminiEnvelope({
          'score': 85,
          'is_acceptable': true,
          'corrected': 'Typed answer.',
          'explanation_ja': '解説',
          'comparison_ja': '比較',
        }),
        200,
      );
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        geminiService: geminiService,
        speechInputService: FakeSpeechInputService(),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'typed answer');
    await tester.runAsync(() async {
      await tester.tap(find.text('答え合わせ'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('85'), findsOneWidget);
    expect(find.text('発音'), findsNothing);
    expect(historyService.drillHistory.single.pronunciation, isNull);
  });
}
