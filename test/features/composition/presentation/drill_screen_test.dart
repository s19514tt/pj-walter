// DrillScreenのウィジェットテスト。
//
// SpeechInputService・TtsServiceはフェイクに差し替え、添削は
// http.testing.MockClientを注入した GeminiCorrectionRepository を使う
// （実際の通信は行わない）。履歴・SRS・統計は Hive 実装の Repository。

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pj_walter/core/data/gemini_client.dart';
import 'package:pj_walter/core/language/learning_language.dart';
import 'package:pj_walter/features/composition/data/gemini_correction_repository.dart';
import 'package:pj_walter/features/composition/data/hive_drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/correction_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_history_repository.dart';
import 'package:pj_walter/features/composition/domain/record_drill_result.dart';
import 'package:pj_walter/features/composition/presentation/drill_screen.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/content/domain/content_repository.dart';
import 'package:pj_walter/features/content/domain/sentence.dart';
import 'package:pj_walter/features/review/data/hive_srs_repository.dart';
import 'package:pj_walter/features/review/domain/srs_repository.dart';
import 'package:pj_walter/features/settings/domain/settings_repository.dart';
import 'package:pj_walter/features/speech/speech_module.dart';
import 'package:pj_walter/features/stats/data/hive_study_stats_repository.dart';
import 'package:pj_walter/features/stats/domain/study_stats_repository.dart';

import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/fake_speech_input_service.dart';
import '../../../test_support/fake_tts_service.dart';
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

Sentence _sentence(int i) => Sentence(
  id: 's700-${i.toString().padLeft(3, '0')}',
  ja: '日本語の例文$i',
  target: 'English sentence $i',
  theme: 'daily',
  tips: 'tips $i',
  level: 700,
);

void main() {
  late GetIt getIt;
  late FakeSettingsRepository settings;
  late DrillHistoryRepository drillHistory;
  late SrsRepository srs;

  setUp(() async {
    await initTestHive();
    getIt = GetIt.asNewInstance()..allowReassignment = true;
    settings = FakeSettingsRepository(apiKey: 'test-api-key');
    drillHistory = HiveDrillHistoryRepository(
      await Hive.openBox('drill_results'),
    );
    srs = HiveSrsRepository(await Hive.openBox('srs_items'));
    final stats = HiveStudyStatsRepository(await Hive.openBox('daily_stats'));
    getIt
      ..registerSingleton<SettingsRepository>(settings)
      ..registerSingleton<ContentRepository>(AssetContentRepository())
      ..registerSingleton<DrillHistoryRepository>(drillHistory)
      ..registerSingleton<SrsRepository>(srs)
      ..registerSingleton<StudyStatsRepository>(stats)
      ..registerSingleton<RecordDrillResult>(
        RecordDrillResult(history: drillHistory, srs: srs, stats: stats),
      )
      ..registerSingleton<TtsServiceFactory>((_) => FakeTtsService());
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  /// [client] を添削 API の応答に使い、[speechInputService] を録音に使う配線で
  /// [DrillScreen] を組み立てる。
  Widget buildApp({
    required List<Sentence> sentences,
    required http.Client client,
    required FakeSpeechInputService speechInputService,
    int questionSeconds = 30,
  }) {
    getIt
      ..registerSingleton<CorrectionRepository>(
        GeminiCorrectionRepository(
          GeminiClient(apiKey: () => settings.apiKey.peek(), client: client),
        ),
      )
      ..registerSingleton<SpeechInputServiceFactory>((_) => speechInputService);
    return scopedApp(
      getIt: getIt,
      home: DrillScreen(
        sentences: sentences,
        level: 700,
        theme: 'daily',
        questionSeconds: questionSeconds,
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
          'explanation': '解説$callCount',
          'comparison': '比較$callCount',
        }),
        200,
      );
    });
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        client: client,
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
    expect(drillHistory.results.value, hasLength(1));
    expect(drillHistory.results.value.first.sentenceId, 's700-001');

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
    expect(drillHistory.results.value, hasLength(2));

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
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        client: client,
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
          'explanation': '解説',
          'comparison': '比較',
        }),
        200,
      );
    });
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        client: client,
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
    expect(drillHistory.results.value, hasLength(1));
    expect(drillHistory.results.value.first.spoken, 'this is my spoken answer');
  });

  testWidgets('中国語モードでは文字起こしのピンインから声調の気づきを表示し、履歴にも保存する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Hiveへの書き込み（ファイルI/O）はFakeAsyncゾーンでは完了しないため
    // runAsync()で実の非同期ゾーンに切り替えて行う。
    await tester.runAsync(
      () => settings.setLearningLanguage(LearningLanguage.chinese),
    );
    const sentences = [
      Sentence(
        id: 'z3-001',
        ja: '水がほしい。',
        target: '我要水。',
        theme: 'daily',
        tips: '',
        level: 3,
        reading: 'Wǒ yào shuǐ',
      ),
    ];
    final client = MockClient((request) async {
      return _jsonResponse(
        _geminiEnvelope({
          'score': 90,
          'is_acceptable': true,
          'corrected': '我要水。',
          'corrected_reading': 'wǒ yào shuǐ',
          'explanation': '解説',
          'comparison': '比較',
        }),
        200,
      );
    });
    final speechInputService = FakeSpeechInputService()
      ..stopResult = '我要睡'
      ..stopReading = 'wǒ yào shuì';

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        client: client,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('答える'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('採点する'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    // 中国語モードのタイトル
    expect(find.text('口頭中国語作文'), findsOneWidget);
    // 添削結果に加えて「気づいた点」カードが出る（スコアは添削の値のまま）
    expect(find.text('90'), findsOneWidget);
    expect(find.text('気づいた点'), findsOneWidget);
    expect(find.text('3声 → 4声'), findsOneWidget);
    // 漢字ごとのルビ: あなたの発話は聞こえた読み、修正版・模範解答は標準ピンイン
    expect(find.text('shuì'), findsWidgets);
    expect(find.text('shuǐ'), findsWidgets);
    expect(find.text('赤字のルビは上＝実際の声調（参考値）／下＝期待された声調'), findsOneWidget);
    // 履歴にも声調の気づきが保存される
    final saved = drillHistory.results.value.single;
    expect(saved.language, 'zh');
    expect(saved.toneNotes, hasLength(1));
    expect(saved.toneNotes!.single.expected, 'shuǐ');
    expect(saved.toneNotes!.single.actual, 'shuì');
  });

  testWidgets('英語モードでは文字起こしにピンインが無く、履歴の声調の気づきはnullのまま', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = MockClient((request) async {
      return _jsonResponse(
        _geminiEnvelope({
          'score': 90,
          'is_acceptable': true,
          'corrected': 'ok',
          'explanation': '解説',
          'comparison': '比較',
        }),
        200,
      );
    });
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        sentences: [_sentence(1)],
        client: client,
        speechInputService: speechInputService,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('答える'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('採点する'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('気づいた点'), findsNothing);
    expect(drillHistory.results.value.single.toneNotes, isNull);
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
    final speechInputService = FakeSpeechInputService();

    await tester.pumpWidget(
      buildApp(
        sentences: sentences,
        client: client,
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
    expect(drillHistory.results.value, isEmpty);
  });

  testWidgets('制限時間が0になり回答が空だと時間切れとして自動保存される', (tester) async {
    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('時間切れの採点はローカルで完結するため通信しない');
    });
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
          client: client,
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
    expect(drillHistory.results.value, hasLength(1));
    expect(drillHistory.results.value.first.feedback.score, 0);
    expect(drillHistory.results.value.first.spoken, isEmpty);
    expect(srs.items.value, hasLength(1));
  });

  testWidgets('わからないので飛ばすと確認ダイアログを経て未採点の結果になる', (tester) async {
    // 未採点カード＋模範解答・解説まで一度に構築させるためビューポートを縦に広げる
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('飛ばした問題は採点しないため通信しない');
    });
    final speechInputService = FakeSpeechInputService();

    // 時間切れのテストと同じ理由で、Hiveの実ファイルI/Oを伴う操作は
    // tester.runAsync()内（実のZone）で行う。
    await tester.runAsync(() async {
      await tester.pumpWidget(
        buildApp(
          sentences: sentences,
          client: client,
          speechInputService: speechInputService,
        ),
      );
      await tester.pump();

      // 「続ける」を選んだら出題画面のまま。何も保存されない
      await tester.tap(find.text('わからないので飛ばす'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('この問題を飛ばしますか？'), findsOneWidget);
      await tester.tap(find.text('続ける'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('答える'), findsOneWidget);
      expect(drillHistory.results.value, isEmpty);

      // 「飛ばす」を選ぶと未採点の結果画面へ進む
      await tester.tap(find.text('わからないので飛ばす'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('飛ばす'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    // 残りの有限アニメーション（カード出現）を流し切る
    await tester.pump(const Duration(milliseconds: 900));

    // 未採点表示＋模範解答・解説。スコアも差分カードも出さない
    expect(find.text('未採点'), findsOneWidget);
    expect(find.text('この問題は飛ばしました'), findsOneWidget);
    expect(
      find.text('わからないので飛ばした問題です。模範解答を声に出して真似るところから始めましょう。'),
      findsOneWidget,
    );
    expect(find.text('English sentence 1'), findsOneWidget);
    expect(find.text('修正版'), findsNothing);
    expect(find.text('要復習'), findsNothing);
    // 録音は一度も始まっていない
    expect(speechInputService.startCalled, isFalse);

    // スコア0で履歴に残り、SRS復習キューにも登録される
    expect(drillHistory.results.value, hasLength(1));
    expect(drillHistory.results.value.first.feedback.score, 0);
    expect(drillHistory.results.value.first.spoken, isEmpty);
    expect(srs.items.value, hasLength(1));
  });

  testWidgets('録音中に飛ばすと文字起こしせずに録音を破棄する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('飛ばした問題は文字起こしも採点もしないため通信しない');
    });
    final speechInputService = FakeSpeechInputService();

    await tester.runAsync(() async {
      await tester.pumpWidget(
        buildApp(
          sentences: sentences,
          client: client,
          speechInputService: speechInputService,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('答える'));
      await tester.pump();
      expect(speechInputService.startCalled, isTrue);

      await tester.tap(find.text('わからないので飛ばす'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('飛ばす'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    // stop()（＝Geminiへ送る文字起こし）ではなくcancel()で捨てている
    expect(speechInputService.cancelCalled, isTrue);
    expect(speechInputService.stopCalled, isFalse);
    expect(find.text('未採点'), findsOneWidget);
    expect(drillHistory.results.value, hasLength(1));
  });

  testWidgets('飛ばす導線はhoverで背景を敷かず、文字と下線だけ濃くなる', (tester) async {
    final client = MockClient((request) async {
      fail('この検証では通信しない');
    });

    await tester.pumpWidget(
      buildApp(
        sentences: [_sentence(1)],
        client: client,
        speechInputService: FakeSpeechInputService(),
      ),
    );
    await tester.pump();

    final label = find.text('わからないので飛ばす');
    // 下線は下ボーダーで引いているので、文字を包むContainerの装飾から色を読む。
    Color underlineColor() {
      final decorated = tester.widget<Container>(
        find.ancestor(of: label, matching: find.byType(Container)).first,
      );
      final border = (decorated.decoration! as BoxDecoration).border!;
      return border.bottom.color;
    }

    expect(tester.widget<Text>(label).style!.color, const Color(0xFF5F6368));
    expect(underlineColor(), const Color(0xFFB9BDC4));

    // ボタンのoverlayは全state透明（テーマ既定のhighlightへフォールバックさせない）
    final style = tester
        .widget<TextButton>(
          find.ancestor(of: label, matching: find.byType(TextButton)),
        )
        .style!;
    for (final state in [
      WidgetState.hovered,
      WidgetState.focused,
      WidgetState.pressed,
    ]) {
      expect(style.overlayColor!.resolve({state}), Colors.transparent);
    }

    // マウスを載せると文字・下線だけが濃くなる
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(label));
    await tester.pump();

    expect(tester.widget<Text>(label).style!.color, const Color(0xFF212121));
    expect(underlineColor(), const Color(0xFF757575));
  });

  testWidgets('セッション中に戻ると中断確認ダイアログが出る', (tester) async {
    final sentences = [_sentence(1)];
    final client = MockClient((request) async {
      fail('この検証では通信しない');
    });
    final speechInputService = FakeSpeechInputService();

    // 戻るボタンを出すため、1枚下に画面がある状態でDrillScreenをpushする。
    getIt
      ..registerSingleton<CorrectionRepository>(
        GeminiCorrectionRepository(
          GeminiClient(apiKey: () => settings.apiKey.peek(), client: client),
        ),
      )
      ..registerSingleton<SpeechInputServiceFactory>((_) => speechInputService);
    await tester.pumpWidget(
      scopedApp(
        getIt: getIt,
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
                    ),
                  ),
                ),
                child: const Text('開く'),
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
