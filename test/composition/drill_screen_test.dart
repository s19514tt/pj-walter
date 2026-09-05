// DrillScreenのウィジェットテスト。
//
// SpeechInputService・TtsServiceはフェイクに差し替え、GeminiServiceは
// http.testing.MockClientを注入した実インスタンスを使う（実際の通信は行わない）。

import 'dart:convert';

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
import 'package:pj_walter/models/token_usage.dart';
import 'package:pj_walter/services/speech_input_service.dart';
import 'package:provider/provider.dart';

import '../test_support/fake_tts_service.dart';
import '../test_support/hive_test_support.dart';

/// テスト用のフェイク音声入力サービス。
///
/// [start]は常に固定のpartialテキストを1回流し、[stop]は
/// あらかじめ設定した[stopResult]（またはエラー）を[stopUsage]付きで返す。
class FakeSpeechInputService implements SpeechInputService {
  String stopResult = 'this is my spoken answer';
  Object? stopError;
  bool startCalled = false;
  bool stopCalled = false;

  /// 文字起こし1回分のトークン使用量（音声入力分は入力300・出力10）
  TokenUsage stopUsage = const TokenUsage(
    promptTokens: 300,
    candidatesTokens: 10,
  );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<void> start({
    required void Function(String text) onPartial,
    void Function(double level)? onLevel,
  }) async {
    startCalled = true;
    onPartial('partial text...');
    onLevel?.call(0.5);
  }

  @override
  Future<SpeechInputResult> stop() async {
    stopCalled = true;
    final error = stopError;
    if (error != null) throw error;
    return SpeechInputResult(text: stopResult, usage: stopUsage);
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

Sentence _sentence(int i) => Sentence(
  id: 's700-${i.toString().padLeft(3, '0')}',
  ja: '日本語の例文$i',
  target: 'English sentence $i',
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
          ttsService: FakeTtsService(),
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

    // 1問目: 日本語文が表示され、録音はまだ始まっていない（待機状態）
    expect(find.text('日本語の例文1'), findsOneWidget);
    expect(find.text('口頭英作文'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(speechInputService.startCalled, isFalse);

    // 答える（録音開始）→「採点する」1タップで段階表示の結果画面に遷移し、
    // 文字起こし→採点と埋まっていく
    await tester.tap(find.text('答える'));
    await tester.pump();
    expect(speechInputService.startCalled, isTrue);

    //
    // 答え合わせは(1)MockClient経由のGemini応答と(2)HistoryServiceによる実際の
    // Hive書き込み（ファイルI/O）を伴う。ファイルI/Oは通常のtestWidgetsの
    // FakeAsyncゾーンでは完了しないため、tester.runAsync()で実の非同期ゾーンに
    // 切り替える（widget_test.dartのHive初期化と同じ理由）。
    // また、ローディング中インジケーター（回転し続けるアニメーション）を表示するため
    // pumpAndSettle()は永久に収束しない。固定回数のpump()で応答を処理してから、
    // ScoreRing・カード出現アニメーション（いずれも有限）をpumpAndSettle()で流し切る。
    await tester.runAsync(() async {
      await tester.tap(find.text('採点する'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    // runAsync()の外（通常のFakeAsyncゾーン）でpumpし、状態変化をフレームに反映する。
    await tester.pump();
    await tester.pumpAndSettle();

    // 添削結果が表示される
    expect(find.text('85'), findsOneWidget);
    expect(find.text('合格'), findsOneWidget);
    expect(find.text('Corrected answer 1'), findsOneWidget);
    expect(find.text('this is my spoken answer'), findsOneWidget);

    // 履歴に保存されている
    expect(historyService.drillHistory, hasLength(1));
    expect(historyService.drillHistory.first.sentenceId, 's700-001');

    // 次の問題へ -> 2問目
    //
    // 2問目では録音が自動開始され、カウントダウンリングのアニメーションが
    // 録音中ずっと繰り返されるため、pumpAndSettle()は収束しない。
    // 固定回数のpump()で2問目の表示を反映する。
    await tester.tap(find.text('次の問題へ'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('日本語の例文2'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    // 2問目もpreから。答える（録音開始）→採点する
    await tester.tap(find.text('答える'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('採点する'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Corrected answer 2'), findsOneWidget);

    // 結果を見る -> まとめ画面
    await tester.tap(find.text('結果を見る'));
    await tester.pumpAndSettle();

    expect(find.text('結果まとめ'), findsOneWidget);
    expect(find.textContaining('平均スコア'), findsOneWidget);
    // 平均スコア表示＋各問のスコア表示（Q1・Q2とも85点）で計3箇所
    expect(find.text('85'), findsNWidgets(3));
    expect(find.textContaining('日本語の例文1'), findsOneWidget);
    expect(find.textContaining('日本語の例文2'), findsOneWidget);
    expect(historyService.drillHistory, hasLength(2));

    // トークン使用量: 2問とも音声入力なので
    //   文字起こし = フェイクの (300 / 10) × 2 = 600 / 20
    //   添削     = MockClientの (100 / 20+思考5) × 2 = 200 / 50
    expect(find.text('APIトークン使用量'), findsOneWidget);
    expect(find.text('入力 600 · 出力 20'), findsOneWidget);
    expect(find.text('入力 200 · 出力 50'), findsOneWidget);
    expect(find.text('入力 800 · 出力 70'), findsOneWidget);
    expect(find.text('出力のうち思考トークン 10'), findsOneWidget);
    // 問ごとの行（コストは単価の適用日に依存するため数値は見ない）
    expect(find.textContaining('入力 400 · 出力 35 · \$'), findsNWidgets(2));
  });

  testWidgets('録音はボタンを押すまで始まらず、カウントダウンは表示と同時に始まる', (tester) async {
    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('この検証では通信しない');
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

    // pre: 録音は始まっておらず、主ボタンは「答える」だけ
    expect(speechInputService.startCalled, isFalse);
    expect(find.text('聞き取り前'), findsOneWidget);
    expect(find.text('答える'), findsOneWidget);
    expect(find.text('採点する'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    // 答える → 録音中表示になり、主ボタンが採点するに切り替わる
    await tester.tap(find.text('答える'));
    await tester.pump();
    expect(speechInputService.startCalled, isTrue);
    expect(find.text('聞き取り中'), findsOneWidget);
    expect(find.text('採点する'), findsOneWidget);
    expect(find.text('答える'), findsNothing);
  });

  testWidgets('録音中に答え合わせを押すと聞き取り終了→文字起こし→採点まで一気に走る', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      return _jsonResponse(
        _geminiEnvelope({
          'score': 90,
          'is_acceptable': true,
          'corrected': 'One-press corrected answer',
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
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        geminiService: geminiService,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    // 答える（録音開始）→そのまま「採点する」を押す
    await tester.tap(find.text('答える'));
    await tester.pump();
    expect(speechInputService.startCalled, isTrue);
    expect(speechInputService.stopCalled, isFalse);
    await tester.runAsync(() async {
      await tester.tap(find.text('採点する'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    // 停止（文字起こし）→採点まで1タップで完了し、文字起こしが回答として使われる
    expect(speechInputService.stopCalled, isTrue);
    expect(find.text('One-press corrected answer'), findsOneWidget);
    expect(find.text('this is my spoken answer'), findsOneWidget);
    expect(historyService.drillHistory, hasLength(1));
    expect(
      historyService.drillHistory.first.spoken,
      'this is my spoken answer',
    );
  });

  testWidgets('GeminiExceptionが発生するとSnackBarとリトライボタンが表示される', (tester) async {
    // 録音自動開始でpartial表示の行が加わり、デフォルトのビューポートでは
    // TextFieldがListViewの構築範囲外になるため、縦に広げる。
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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

    await tester.tap(find.text('答える'));
    await tester.pump();
    await tester.tap(find.text('採点する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    // 段階表示のstage 1（文字起こしは表示済み・採点はスケルトン）に留まる
    expect(find.text('this is my spoken answer'), findsOneWidget);
    expect(find.text('AI採点中'), findsWidgets);
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
    // 録音は自動開始されるため、時間切れ時の自動停止で文字起こしが空
    // （何も話さなかった）ケースを再現する。
    final speechInputService = FakeSpeechInputService()..stopResult = '';

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
      // カウントダウンは画面表示と同時に始まる。何もせず時間切れを待つ
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

  testWidgets('セッション中に戻ると中断確認ダイアログが出る', (tester) async {
    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('この検証では通信しない');
    });
    final geminiService = GeminiService(
      settingsService: settings,
      client: client,
    );
    final speechInputService = FakeSpeechInputService();

    // 戻るボタンを出すため、1枚下に画面がある状態でDrillScreenをpushする。
    // pushした先からproviderを参照できるよう、MultiProviderはMaterialAppの外側に置く。
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<HistoryService>.value(value: historyService),
          Provider<GeminiService>.value(value: geminiService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DrillScreen(
                        sentences: sentences,
                        level: 700,
                        theme: 'daily',
                        speechInputService: speechInputService,
                        ttsService: FakeTtsService(),
                      ),
                    ),
                  ),
                  child: const Text('開く'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('答える'), findsOneWidget);

    // 戻る → 確認ダイアログが出て、「続ける」なら画面に留まる
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(find.text('トレーニングを中断しますか？'), findsOneWidget);
    await tester.tap(find.text('続ける'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('答える'), findsOneWidget);

    // もう一度戻る → 「中断する」で前の画面へ戻る
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.tap(find.text('中断する'));
    await tester.pump();
    // ダイアログクローズ＋ルートのポップ遷移を流し切る
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('答える'), findsNothing);
    expect(find.text('開く'), findsOneWidget);
  });
}
