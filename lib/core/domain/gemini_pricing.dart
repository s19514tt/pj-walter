import 'token_usage.dart';

/// 単価の適用区分（表示名は ARB の `pricingTierLabel`）。
enum PricingTier {
  /// 2026年12月31日までの導入価格
  introductory,

  /// 2027年1月1日以降の標準価格
  standard,

  /// 読み上げ（TTS）モデル
  tts,
}

/// `gemini-3.8-flash` の従量課金単価（USD / 100万トークン、Standardティア）。
///
/// 出典: https://ai.google.dev/gemini-api/docs/pricing （2026-09-03 確認）
/// - 2026年12月31日まで: 入力 $0.75 / 出力 $3.75（導入価格）
/// - 2027年1月1日から: 入力 $1.50 / 出力 $7.50（標準価格）
/// 出力単価は思考（thinking）トークンにも適用される。音声入力にも入力単価が
/// そのまま適用される（このモデルでは音声の別単価は設定されていない）。
/// コンテキストキャッシュ・Batch API は使っていないため考慮しない。
class GeminiPricing {
  const GeminiPricing({
    required this.inputUsdPerMillion,
    required this.outputUsdPerMillion,
    required this.tier,
  });

  /// 導入価格（2026年12月31日まで）
  static const introductory = GeminiPricing(
    inputUsdPerMillion: 0.75,
    outputUsdPerMillion: 3.75,
    tier: PricingTier.introductory,
  );

  /// 読み上げ（TTS）モデル`gemini-3.1-flash-tts-preview`の単価。
  ///
  /// 出典: https://ai.google.dev/gemini-api/docs/pricing （2026-09-05 確認）
  /// 入力（テキスト）$1.00 / 出力（音声）$20.00 per 1M tokens。
  /// 導入価格の設定は無く、日付による切り替えもない。
  /// 音声出力はテキスト出力よりかなり高いため、同じ文の読み上げは
  /// `AudioPlayerTtsService`がキャッシュしてAPIの再呼び出しを避けている。
  static const tts = GeminiPricing(
    inputUsdPerMillion: 1.00,
    outputUsdPerMillion: 20.00,
    tier: PricingTier.tts,
  );

  /// 標準価格（2027年1月1日以降）
  static const standard = GeminiPricing(
    inputUsdPerMillion: 1.50,
    outputUsdPerMillion: 7.50,
    tier: PricingTier.standard,
  );

  /// 導入価格が適用される最終日（この日まで含む、ローカル日付）
  static final introductoryUntil = DateTime(2026, 12, 31);

  /// 入力トークンの単価（USD / 100万トークン）
  final double inputUsdPerMillion;

  /// 出力トークン（思考トークン含む）の単価（USD / 100万トークン）
  final double outputUsdPerMillion;

  /// 適用区分（UI 表示用）
  final PricingTier tier;

  /// [date]時点で適用される単価を返す。
  static GeminiPricing forDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.isAfter(introductoryUntil) ? standard : introductory;
  }

  /// [usage]の料金（USD）を計算する。
  double costUsd(TokenUsage usage) =>
      usage.promptTokens * inputUsdPerMillion / 1000000 +
      usage.billedOutputTokens * outputUsdPerMillion / 1000000;

  /// 入力単価の短い表記（例: `$0.75`）
  String get inputRateLabel => '\$${_trim(inputUsdPerMillion)}';

  /// 出力単価の短い表記（例: `$3.75`）
  String get outputRateLabel => '\$${_trim(outputUsdPerMillion)}';

  static String _trim(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}

/// USD金額を表示用に整形する（小数4桁固定、例: `$0.0032`）。
///
/// 1セッションの料金は数セント以下になるため、2桁では常に `$0.00` に
/// なってしまう。4桁で固定して比較しやすくする。
String formatUsd(double usd) => '\$${usd.toStringAsFixed(4)}';
