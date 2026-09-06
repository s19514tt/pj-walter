// GeminiMonologueReviewRepository（独り言のフィードバック）のテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pj_walter/features/monologue/data/gemini_monologue_review_repository.dart';
import 'package:pj_walter/features/monologue/domain/monologue_review_repository.dart';

import '../../../test_support/gemini_test_support.dart';

const _request = MonologueReviewRequest(
  uiLocale: 'ja',
  learningLanguage: 'en',
  topicSource: '朝ごはんについて話してください',
  topicTarget: 'Talk about your breakfast',
  seconds: 60,
  transcript: 'I eat toast this morning.',
);

void main() {
  test('200応答をMonologueFeedbackに変換する', () async {
    http.Request? captured;
    final repository = GeminiMonologueReviewRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(
          geminiEnvelope({
            'fluency_score': 72,
            'corrected_transcript': 'I had toast this morning.',
            'corrections': [
              {
                'original': 'I eat toast',
                'corrected': 'I had toast',
                'reason': '過去形が適切です。',
              },
            ],
            'useful_phrases': [
              {'target': 'It slipped my mind.', 'ja': 'うっかり忘れていた'},
            ],
            'overall_feedback': '良く話せていました。',
          }),
          200,
        );
      }),
    );

    final result = await repository.review(_request);

    expect(result.feedback.fluencyScore, 72);
    expect(result.feedback.corrections, hasLength(1));
    expect(result.feedback.corrections.single.reason, '過去形が適切です。');
    expect(result.feedback.usefulPhrases.single.target, 'It slipped my mind.');
    expect(result.feedback.overallFeedback, '良く話せていました。');

    final prompt = requestPrompt(captured!);
    expect(prompt, contains('60秒'));
    expect(prompt, contains(_request.topicSource));
    expect(prompt, contains(_request.transcript));
    // 解説の言語は uiLocale（ja）から、学習言語は英語名で
    expect(prompt, contains('日本語'));
    expect(prompt, contains('English'));
    final schema =
        (requestJson(captured!)['generationConfig'] as Map)['responseSchema']
            as Map;
    expect(schema['required'], contains('overall_feedback'));
    expect(schema['required'], isNot(contains('overall_feedback_ja')));
  });
}
