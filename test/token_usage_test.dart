// TokenUsage（usageMetadataの読み取り・合算）とGeminiPricing（単価の日付切替・
// 料金計算）のユニットテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/token_usage.dart';
import 'package:pj_walter/services/gemini_pricing.dart';

void main() {
  group('TokenUsage', () {
    test('usageMetadataから読み取り、欠けたキーは0にする', () {
      final usage = TokenUsage.fromUsageMetadata({
        'promptTokenCount': 120,
        'candidatesTokenCount': 30,
        'totalTokenCount': 150,
      });
      expect(usage.promptTokens, 120);
      expect(usage.candidatesTokens, 30);
      expect(usage.thoughtsTokens, 0);
      expect(usage.billedOutputTokens, 30);
      expect(usage.totalTokens, 150);
      expect(usage.isZero, isFalse);
    });

    test('nullならzero', () {
      expect(TokenUsage.fromUsageMetadata(null), TokenUsage.zero);
      expect(TokenUsage.zero.isZero, isTrue);
    });

    test('思考トークンは出力に含めて合算する', () {
      const a = TokenUsage(
        promptTokens: 100,
        candidatesTokens: 20,
        thoughtsTokens: 5,
      );
      const b = TokenUsage(promptTokens: 50, candidatesTokens: 10);
      final sum = a + b;
      expect(sum.promptTokens, 150);
      expect(sum.candidatesTokens, 30);
      expect(sum.thoughtsTokens, 5);
      expect(sum.billedOutputTokens, 35);
      expect(sum.totalTokens, 185);
    });
  });

  group('GeminiPricing', () {
    test('2026年12月31日までは導入価格、2027年1月1日から標準価格', () {
      expect(
        GeminiPricing.forDate(DateTime(2026, 9, 3)),
        GeminiPricing.introductory,
      );
      expect(
        GeminiPricing.forDate(DateTime(2026, 12, 31, 23, 59)),
        GeminiPricing.introductory,
      );
      expect(
        GeminiPricing.forDate(DateTime(2027, 1, 1)),
        GeminiPricing.standard,
      );
    });

    test('入力・出力（思考込み）に単価を掛けてUSDを算出する', () {
      // 入力1,000,000 → $0.75、出力(20+5)=25 → 25 * 3.75 / 1e6
      const usage = TokenUsage(
        promptTokens: 1000000,
        candidatesTokens: 20,
        thoughtsTokens: 5,
      );
      final cost = GeminiPricing.introductory.costUsd(usage);
      expect(cost, closeTo(0.75 + 25 * 3.75 / 1000000, 1e-12));

      final standardCost = GeminiPricing.standard.costUsd(usage);
      expect(standardCost, closeTo(1.5 + 25 * 7.5 / 1000000, 1e-12));
    });

    test('単価の説明と金額の整形', () {
      expect(
        GeminiPricing.introductory.rateDescription,
        '入力 \$0.75 / 出力 \$3.75 per 1M tokens',
      );
      expect(
        GeminiPricing.standard.rateDescription,
        '入力 \$1.5 / 出力 \$7.5 per 1M tokens',
      );
      expect(formatUsd(0.00016875), '\$0.0002');
      expect(formatUsd(0), '\$0.0000');
      expect(formatUsd(1.23456), '\$1.2346');
    });
  });
}
