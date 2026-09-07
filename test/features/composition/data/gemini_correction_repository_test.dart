// GeminiCorrectionRepository（口頭作文の添削）のリクエスト組み立て・応答パースのテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pj_walter/core/domain/app_failure.dart';
import 'package:pj_walter/features/composition/data/gemini_correction_repository.dart';
import 'package:pj_walter/features/composition/domain/correction_repository.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';

import '../../../test_support/gemini_test_support.dart';

const _enRequest = CorrectionRequest(
  uiLocale: 'ja',
  learningLanguage: 'en',
  source: 'この件については後ほど折り返しご連絡します。',
  modelAnswer: "I'll get back to you on this matter later.",
  spoken: "I'll call you back later",
);

const _zhRequest = CorrectionRequest(
  uiLocale: 'ja',
  learningLanguage: 'zh',
  source: '水がほしい。',
  modelAnswer: '我要水。',
  spoken: '我要睡',
);

void main() {
  test('200応答をCompositionFeedbackに変換し、usageも返す', () async {
    http.Request? captured;
    final repository = GeminiCorrectionRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(
          geminiEnvelope(
            {
              'score': 85,
              'is_acceptable': true,
              'corrected': "I'll call you back later.",
              'explanation': '概ね正しいです。',
              'comparison': '模範解答とほぼ同じです。',
            },
            usageMetadata: {
              'promptTokenCount': 150,
              'candidatesTokenCount': 40,
            },
          ),
          200,
        );
      }),
    );

    final result = await repository.correct(_enRequest);

    expect(result.feedback.score, 85);
    expect(result.feedback.isAcceptable, true);
    expect(result.feedback.corrected, "I'll call you back later.");
    expect(result.feedback.explanation, '概ね正しいです。');
    expect(result.usage.promptTokens, 150);
    expect(result.usage.candidatesTokens, 40);
    expect(result.usage.thoughtsTokens, 0);
    final prompt = requestPrompt(captured!);
    // 原文・模範解答・発話がプロンプトに入る
    expect(prompt, contains(_enRequest.source));
    expect(prompt, contains(_enRequest.modelAnswer));
    expect(prompt, contains(_enRequest.spoken));
    // 採点方針の行（声調はスコアに含めない）
    expect(prompt, contains('発音・声調は評価対象に含めません'));
  });

  test('解説の言語は uiLocale から決まり、学習言語は英語名で指示する', () async {
    http.Request? captured;
    final repository = GeminiCorrectionRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(
          geminiEnvelope({
            'score': 90,
            'is_acceptable': true,
            'corrected': 'ok',
            'explanation': '',
            'comparison': '',
          }),
          200,
        );
      }),
    );

    await repository.correct(_enRequest);

    final prompt = requestPrompt(captured!);
    expect(prompt, contains('日本語'));
    expect(prompt, contains('English'));
    expect(prompt, contains('explanation'));
    expect(prompt, isNot(contains('explanation_ja')));
  });

  test('英語の添削スキーマ・プロンプトに語区切りは入らない', () async {
    http.Request? captured;
    final repository = GeminiCorrectionRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(
          geminiEnvelope({
            'score': 90,
            'is_acceptable': true,
            'corrected': 'ok',
            'explanation': '',
            'comparison': '',
          }),
          200,
        );
      }),
    );

    final result = await repository.correct(_enRequest);

    expect(result.feedback.correctedReading, isNull);
    expect(result.feedback.correctedWords, isNull);
    final schema =
        (requestJson(captured!)['generationConfig'] as Map)['responseSchema']
            as Map;
    expect(
      (schema['properties'] as Map).keys,
      isNot(contains('corrected_words')),
    );
    expect((schema['properties'] as Map).keys, contains('explanation'));
    expect((schema['required'] as List), isNot(contains('explanation_ja')));
    expect(requestPrompt(captured!), isNot(contains('corrected_words')));
  });

  test('中国語の添削は語区切りを追加で要求し、CompositionFeedbackに入れる', () async {
    http.Request? captured;
    final repository = GeminiCorrectionRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(
          geminiEnvelope({
            'score': 90,
            'is_acceptable': true,
            'corrected': '我要水。',
            'corrected_words': [
              {'hanzi': '我', 'pinyin': 'wǒ'},
              {'hanzi': '要', 'pinyin': 'yào'},
              {'hanzi': '水', 'pinyin': 'shuǐ'},
              {'hanzi': '。', 'pinyin': ''},
            ],
            'spoken_words': ['我', '要', '睡'],
            'explanation': '解説',
            'comparison': '比較',
          }),
          200,
        );
      }),
    );

    final result = await repository.correct(_zhRequest);

    expect(result.feedback.correctedWords, [
      const WordUnit(text: '我', reading: 'wǒ'),
      const WordUnit(text: '要', reading: 'yào'),
      const WordUnit(text: '水', reading: 'shuǐ'),
      const WordUnit(text: '。', reading: ''),
    ]);
    expect(result.feedback.spokenWords, [
      const WordUnit(text: '我'),
      const WordUnit(text: '要'),
      const WordUnit(text: '睡'),
    ]);
    // 語ごとのピンインは繋いで修正版の読みとしても持つ（履歴・フォールバック用）
    expect(result.feedback.correctedReading, 'wǒ yào shuǐ');
    final schema =
        (requestJson(captured!)['generationConfig'] as Map)['responseSchema']
            as Map;
    expect((schema['properties'] as Map).keys, contains('corrected_words'));
    expect((schema['properties'] as Map).keys, contains('spoken_words'));
    expect(schema['required'], contains('corrected_words'));
    final prompt = requestPrompt(captured!);
    expect(prompt, contains('corrected_words'));
    expect(prompt, contains('spoken_words'));
    expect(prompt, contains('発音・声調は評価対象に含めません'));
  });

  test('本文が空の応答は送り直す', () async {
    var requests = 0;
    final repository = GeminiCorrectionRepository(
      testGeminiClient((request) async {
        requests++;
        if (requests == 1) return jsonResponse(emptyContentEnvelope, 200);
        return jsonResponse(
          geminiEnvelope({
            'score': 90,
            'is_acceptable': true,
            'corrected': 'ok',
            'explanation': '',
            'comparison': '',
          }),
          200,
        );
      }),
    );

    final result = await repository.correct(_enRequest);

    expect(result.feedback.score, 90);
    expect(requests, 2);
  });

  test('スキーマに合わない応答はinvalidResponse', () async {
    final repository = GeminiCorrectionRepository(
      testGeminiClient(
        (request) async => jsonResponse(geminiEnvelope({'score': 1}), 200),
      ),
    );

    await expectLater(
      repository.correct(_enRequest),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.invalidResponse,
        ),
      ),
    );
  });

  test('HTTPエラーはAppFailureのまま伝播する', () async {
    final repository = GeminiCorrectionRepository(
      testGeminiClient((request) async => http.Response('unauthorized', 401)),
    );

    await expectLater(
      repository.correct(_enRequest),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.apiKeyInvalid,
        ),
      ),
    );
  });
}
