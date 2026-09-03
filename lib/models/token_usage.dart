import 'package:flutter/foundation.dart';

/// Gemini API 1回の呼び出し（または複数回の合計）のトークン使用量。
///
/// レスポンスの`usageMetadata`から作る。出力は`candidatesTokenCount`（返答本文）と
/// `thoughtsTokenCount`（思考）に分かれるが、料金上はどちらも出力トークンとして
/// 課金されるため[billedOutputTokens]で合算して扱う。
@immutable
class TokenUsage {
  const TokenUsage({
    required this.promptTokens,
    required this.candidatesTokens,
    this.thoughtsTokens = 0,
  });

  /// 使用量ゼロ
  static const zero = TokenUsage(promptTokens: 0, candidatesTokens: 0);

  /// 入力（プロンプト＋音声など）のトークン数
  final int promptTokens;

  /// 返答本文の出力トークン数
  final int candidatesTokens;

  /// 思考（thinking）に使われた出力トークン数
  final int thoughtsTokens;

  /// 課金対象の出力トークン数（返答本文＋思考）
  int get billedOutputTokens => candidatesTokens + thoughtsTokens;

  /// 入力＋出力の合計トークン数
  int get totalTokens => promptTokens + billedOutputTokens;

  /// 1トークンも使っていないかどうか
  bool get isZero => totalTokens == 0;

  /// Gemini APIレスポンスの`usageMetadata`から生成する。
  ///
  /// 欠けているキーは0として扱う（`usageMetadata`自体が無い場合は[zero]相当）。
  factory TokenUsage.fromUsageMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return zero;
    int read(String key) => (metadata[key] as num?)?.toInt() ?? 0;
    return TokenUsage(
      promptTokens: read('promptTokenCount'),
      candidatesTokens: read('candidatesTokenCount'),
      thoughtsTokens: read('thoughtsTokenCount'),
    );
  }

  TokenUsage operator +(TokenUsage other) => TokenUsage(
    promptTokens: promptTokens + other.promptTokens,
    candidatesTokens: candidatesTokens + other.candidatesTokens,
    thoughtsTokens: thoughtsTokens + other.thoughtsTokens,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenUsage &&
          runtimeType == other.runtimeType &&
          promptTokens == other.promptTokens &&
          candidatesTokens == other.candidatesTokens &&
          thoughtsTokens == other.thoughtsTokens;

  @override
  int get hashCode =>
      Object.hash(promptTokens, candidatesTokens, thoughtsTokens);

  @override
  String toString() =>
      'TokenUsage(prompt: $promptTokens, candidates: $candidatesTokens, '
      'thoughts: $thoughtsTokens)';
}
