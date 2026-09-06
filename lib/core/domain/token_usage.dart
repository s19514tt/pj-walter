import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_usage.freezed.dart';

/// AI API 1回の呼び出し（または複数回の合計）のトークン使用量。
///
/// 出力は返答本文（[candidatesTokens]）と思考（[thoughtsTokens]）に分かれるが、
/// 料金上はどちらも出力トークンとして課金されるため[billedOutputTokens]で
/// 合算して扱う。Gemini の `usageMetadata` からの読み取りは `GeminiClient` が行う。
@freezed
abstract class TokenUsage with _$TokenUsage {
  const TokenUsage._();

  const factory TokenUsage({
    /// 入力（プロンプト＋音声など）のトークン数
    required int promptTokens,

    /// 返答本文の出力トークン数
    required int candidatesTokens,

    /// 思考（thinking）に使われた出力トークン数
    @Default(0) int thoughtsTokens,
  }) = _TokenUsage;

  /// 使用量ゼロ
  static const zero = TokenUsage(promptTokens: 0, candidatesTokens: 0);

  /// 課金対象の出力トークン数（返答本文＋思考）
  int get billedOutputTokens => candidatesTokens + thoughtsTokens;

  /// 入力＋出力の合計トークン数
  int get totalTokens => promptTokens + billedOutputTokens;

  /// 1トークンも使っていないかどうか
  bool get isZero => totalTokens == 0;

  TokenUsage operator +(TokenUsage other) => TokenUsage(
    promptTokens: promptTokens + other.promptTokens,
    candidatesTokens: candidatesTokens + other.candidatesTokens,
    thoughtsTokens: thoughtsTokens + other.thoughtsTokens,
  );
}
