import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/features/composition/domain/correction_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';

/// 固定の添削結果（またはエラー）を返す [CorrectionRepository]。
class FakeCorrectionRepository implements CorrectionRepository {
  FakeCorrectionRepository({
    this.feedback = const CompositionFeedback(
      score: 85,
      isAcceptable: true,
      corrected: 'Corrected answer',
      explanation: '解説',
      comparison: '比較',
    ),
    this.usage = const TokenUsage(
      promptTokens: 100,
      candidatesTokens: 20,
      thoughtsTokens: 5,
    ),
  });

  CompositionFeedback feedback;
  TokenUsage usage;

  /// 次の呼び出しで投げる例外。null なら正常に返す
  Object? error;

  /// 受け取ったリクエスト（呼ばれた順）
  final requests = <CorrectionRequest>[];

  @override
  Future<CorrectionResult> correct(CorrectionRequest request) async {
    requests.add(request);
    final error = this.error;
    if (error != null) throw error;
    return CorrectionResult(feedback: feedback, usage: usage);
  }
}
