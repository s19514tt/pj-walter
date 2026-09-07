// DrillSummaryScreenのトークン使用量・コスト表示のウィジェットテスト。
// 単価はGeminiPricingを注入して固定する（日付に依存させない）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/features/composition/presentation/drill_summary_screen.dart';
import 'package:pj_walter/core/data/gemini_client.dart';
import 'package:pj_walter/core/domain/gemini_pricing.dart';
import 'package:get_it/get_it.dart';
import 'package:pj_walter/features/content/data/asset_content_repository.dart';
import 'package:pj_walter/features/content/domain/content_repository.dart';
import 'package:pj_walter/features/settings/domain/settings_repository.dart';

import '../../../test_support/fake_settings_repository.dart';
import '../../../test_support/test_app.dart';

void main() {
  late GetIt getIt;

  setUp(() {
    getIt = GetIt.asNewInstance()
      ..registerSingleton<SettingsRepository>(FakeSettingsRepository())
      ..registerSingleton<ContentRepository>(AssetContentRepository());
  });

  testWidgets('用途別・合計のトークン数と、単価から算出したコストが表示される', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const entries = [
      DrillSummaryEntry(
        ja: '例文1',
        score: 85,
        usage: DrillQuestionUsage(
          transcription: TokenUsage(promptTokens: 600, candidatesTokens: 20),
          correction: TokenUsage(
            promptTokens: 400,
            candidatesTokens: 30,
            thoughtsTokens: 10,
          ),
        ),
      ),
      // 添削のみ（文字起こし分なし）
      DrillSummaryEntry(
        ja: '例文2',
        score: 60,
        usage: DrillQuestionUsage(
          correction: TokenUsage(promptTokens: 1000, candidatesTokens: 40),
        ),
      ),
      // 時間切れ（API呼び出し無し）
      DrillSummaryEntry(ja: '例文3', score: 0),
    ];

    // 金額の文字列は浮動小数点の丸め（toStringAsFixed）に依存するため、
    // 期待値も同じ関数で組み立てる。
    const pricing = GeminiPricing.introductory;
    String cost(TokenUsage usage) => formatUsd(pricing.costUsd(usage));
    const transcription = TokenUsage(promptTokens: 600, candidatesTokens: 20);
    const correction = TokenUsage(
      promptTokens: 1400,
      candidatesTokens: 70,
      thoughtsTokens: 10,
    );
    const total = TokenUsage(
      promptTokens: 2000,
      candidatesTokens: 90,
      thoughtsTokens: 10,
    );

    await tester.pumpWidget(
      scopedApp(
        getIt: getIt,
        home: const DrillSummaryScreen(
          level: 700,
          theme: 'daily',
          entries: entries,
          pricing: pricing,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APIトークン使用量'), findsOneWidget);
    expect(find.text('入力 600 · 出力 20'), findsOneWidget);
    expect(find.text(cost(transcription)), findsWidgets);
    expect(find.text('入力 1,400 · 出力 80'), findsOneWidget);
    expect(find.text(cost(correction)), findsWidgets);
    expect(find.text('入力 2,000 · 出力 100'), findsOneWidget);
    expect(find.text(cost(total)), findsWidgets);
    expect(find.text('出力のうち思考トークン 10'), findsOneWidget);
    expect(find.textContaining('入力 \$0.75 / 出力 \$3.75'), findsOneWidget);

    // 問ごとの行: 1問目 1000/60、2問目 1000/40
    const q1 = TokenUsage(
      promptTokens: 1000,
      candidatesTokens: 50,
      thoughtsTokens: 10,
    );
    const q2 = TokenUsage(promptTokens: 1000, candidatesTokens: 40);
    expect(find.text('入力 1,000 · 出力 60 · ${cost(q1)}'), findsOneWidget);
    expect(find.text('入力 1,000 · 出力 40 · ${cost(q2)}'), findsOneWidget);
    // 3問目は使用量ゼロなので行を出さない
    expect(find.textContaining('入力 0 · 出力 0 · \$'), findsNothing);
  });

  testWidgets('読み上げはTTSモデルの単価で別行に出し、合計は用途ごとに足し合わせる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const speech = TokenUsage(promptTokens: 30, candidatesTokens: 1200);
    const correction = TokenUsage(promptTokens: 400, candidatesTokens: 30);
    const entries = [
      DrillSummaryEntry(
        ja: '例文1',
        score: 85,
        usage: DrillQuestionUsage(correction: correction, speech: speech),
      ),
    ];

    const pricing = GeminiPricing.introductory;

    await tester.pumpWidget(
      scopedApp(
        getIt: getIt,
        home: const DrillSummaryScreen(
          level: 700,
          theme: 'daily',
          entries: entries,
          pricing: pricing,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('読み上げ'), findsOneWidget);
    expect(find.text('入力 30 · 出力 1,200'), findsOneWidget);
    // 読み上げ行は音声の単価（$1.00 / $20.00）で計算する
    expect(
      find.text(formatUsd(GeminiPricing.tts.costUsd(speech))),
      findsWidgets,
    );
    // 合計は「テキスト単価×添削 ＋ 音声単価×読み上げ」。全体に片方の単価を
    // 掛けると実際の請求とずれるので、用途ごとに計算されていることを確かめる。
    final expectedTotal =
        pricing.costUsd(correction) + GeminiPricing.tts.costUsd(speech);
    expect(find.text(formatUsd(expectedTotal)), findsWidgets);
    expect(find.textContaining(GeminiClient.ttsModelName), findsOneWidget);
  });

  test('読み上げが無ければ合計コストはテキスト単価だけで決まる', () {
    const usage = DrillQuestionUsage(
      transcription: TokenUsage(promptTokens: 600, candidatesTokens: 20),
      correction: TokenUsage(promptTokens: 400, candidatesTokens: 30),
    );

    expect(
      usage.costUsd(GeminiPricing.introductory),
      GeminiPricing.introductory.costUsd(usage.total),
    );
  });
}
