import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/features/monologue/domain/monologue_result.dart';
import 'package:pj_walter/features/monologue/domain/monologue_review_repository.dart';

/// 固定のフィードバック（またはエラー）を返す [MonologueReviewRepository]。
class FakeMonologueReviewRepository implements MonologueReviewRepository {
  FakeMonologueReviewRepository({
    this.feedback = const MonologueFeedback(
      fluencyScore: 82,
      correctedTranscript: 'Corrected monologue.',
      corrections: [
        Correction(original: 'i eat', corrected: 'I ate', reason: '過去形'),
      ],
      usefulPhrases: [
        UsefulPhrase(target: 'It slipped my mind.', ja: 'うっかり忘れていた'),
        UsefulPhrase(target: 'Long story short.', ja: '手短に言うと'),
      ],
      overallFeedback: '総評',
    ),
  });

  MonologueFeedback feedback;

  /// 次の呼び出しで投げる例外。null なら正常に返す
  Object? error;

  /// 受け取ったリクエスト（呼ばれた順）
  final requests = <MonologueReviewRequest>[];

  @override
  Future<MonologueReviewResult> review(MonologueReviewRequest request) async {
    requests.add(request);
    final error = this.error;
    if (error != null) throw error;
    return MonologueReviewResult(feedback: feedback, usage: TokenUsage.zero);
  }
}
