// GeminiTranscriptionRepository（文字起こし）のテスト。
//
// 英語はプレーンテキスト、中国語は構造化出力（pinyin→hanzi）で
// 「聞こえたままのピンイン」を併せて受け取る（DESIGN.md「中国語の文字起こし」）。

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pj_walter/core/domain/app_failure.dart';
import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/features/speech/data/gemini_transcription_repository.dart';
import 'package:pj_walter/features/speech/domain/transcription_repository.dart';

import '../../../test_support/gemini_test_support.dart';

const _en = TranscriptionRequest(
  learningLanguage: 'en',
  audioBytes: [1, 2, 3],
  mimeType: 'audio/wav',
);

const _zh = TranscriptionRequest(
  learningLanguage: 'zh',
  audioBytes: [1, 2, 3],
  mimeType: 'audio/wav',
);

Matcher _failsWith(FailureKind kind) =>
    throwsA(isA<AppFailure>().having((e) => e.kind, 'kind', kind));

void main() {
  test('プレーンテキスト応答とusageMetadataを返す', () async {
    final repository = GeminiTranscriptionRepository(
      testGeminiClient(
        (request) async => jsonResponse(
          geminiEnvelope(
            'This is the transcript.',
            usageMetadata: {
              'promptTokenCount': 320,
              'candidatesTokenCount': 8,
              'thoughtsTokenCount': 2,
              'totalTokenCount': 330,
            },
          ),
          200,
        ),
      ),
    );

    final result = await repository.transcribe(_en);

    expect(result.text, 'This is the transcript.');
    // 英語ではピンインは返さない
    expect(result.reading, isNull);
    expect(
      result.usage,
      const TokenUsage(
        promptTokens: 320,
        candidatesTokens: 8,
        thoughtsTokens: 2,
      ),
    );
  });

  test('英語の文字起こしはプレーンテキストのまま（構造化出力にしない）', () async {
    http.Request? captured;
    final repository = GeminiTranscriptionRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(geminiEnvelope('hello'), 200);
      }),
    );

    await repository.transcribe(_en);

    final body = requestJson(captured!);
    final config = body['generationConfig'] as Map<String, dynamic>;
    expect(config.containsKey('responseMimeType'), isFalse);
    expect(config.containsKey('responseSchema'), isFalse);
    final parts = (body['contents'] as List).first['parts'] as List;
    expect(parts.first['text'], startsWith('Transcribe this English speech'));
    expect(parts[1]['inline_data']['mime_type'], 'audio/wav');
  });

  test('文字起こしプロンプトは無音時にマーカーを返すよう指示している', () async {
    http.Request? captured;
    final repository = GeminiTranscriptionRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(geminiEnvelope('hello'), 200);
      }),
    );

    await repository.transcribe(_en);

    final prompt = requestPrompt(captured!);
    expect(prompt, contains(GeminiTranscriptionRepository.noSpeechMarker));
    expect(prompt, isNot(contains('empty string')));
  });

  test('無音マーカーの応答はnoSpeech（送り直さない）', () async {
    var requests = 0;
    final repository = GeminiTranscriptionRepository(
      testGeminiClient((request) async {
        requests++;
        return jsonResponse(
          geminiEnvelope(' ${GeminiTranscriptionRepository.noSpeechMarker}\n'),
          200,
        );
      }),
    );

    await expectLater(
      repository.transcribe(_en),
      _failsWith(FailureKind.noSpeech),
    );
    // 無音はモデルの明示的な判断なので送り直さない
    expect(requests, 1);
  });

  test('本文が空の応答は同じリクエストを送り直して成功させる', () async {
    var requests = 0;
    final repository = GeminiTranscriptionRepository(
      testGeminiClient((request) async {
        requests++;
        if (requests == 1) return jsonResponse(emptyContentEnvelope, 200);
        return jsonResponse(
          geminiEnvelope(
            'Second try.',
            usageMetadata: {'promptTokenCount': 203, 'candidatesTokenCount': 4},
          ),
          200,
        );
      }),
    );

    final result = await repository.transcribe(_en);

    expect(result.text, 'Second try.');
    expect(result.reading, isNull);
    expect(requests, 2);
    expect(
      result.usage,
      const TokenUsage(promptTokens: 406, candidatesTokens: 4),
    );
  });

  test('本文が空の応答が3回続いたらemptyResponse（noSpeechとは区別）', () async {
    var requests = 0;
    final repository = GeminiTranscriptionRepository(
      testGeminiClient((request) async {
        requests++;
        return jsonResponse(emptyContentEnvelope, 200);
      }),
    );

    await expectLater(
      repository.transcribe(_en),
      _failsWith(FailureKind.emptyResponse),
    );
    expect(requests, 3);
  });

  group('中国語（声調付きピンイン併記）', () {
    test(
      '構造化出力で pinyin→hanzi の順に生成させ、hanziをtext・pinyinをreadingとして返す',
      () async {
        http.Request? captured;
        final repository = GeminiTranscriptionRepository(
          testGeminiClient((request) async {
            captured = request;
            return jsonResponse(
              geminiEnvelope(
                {'pinyin': 'wǒ yào shuì', 'hanzi': '我要睡'},
                usageMetadata: {
                  'promptTokenCount': 300,
                  'candidatesTokenCount': 30,
                },
              ),
              200,
            );
          }),
        );

        final result = await repository.transcribe(_zh);

        expect(result.text, '我要睡');
        expect(result.reading, 'wǒ yào shuì');
        expect(
          result.usage,
          const TokenUsage(promptTokens: 300, candidatesTokens: 30),
        );

        final body = requestJson(captured!);
        final config = body['generationConfig'] as Map<String, dynamic>;
        expect(config['responseMimeType'], 'application/json');
        final schema = config['responseSchema'] as Map<String, dynamic>;
        // 漢字を先に確定させるとピンインが辞書引きになるため、順序は固定
        expect(schema['propertyOrdering'], ['pinyin', 'hanzi']);
        expect(schema['required'], ['pinyin', 'hanzi']);
        expect(config['thinkingConfig'], {'thinkingLevel': 'low'});

        final parts = (body['contents'] as List).first['parts'] as List;
        final prompt = parts.first['text'] as String;
        expect(prompt, contains('聞こえた'));
        expect(prompt, contains(GeminiTranscriptionRepository.noSpeechMarker));
        // 音声のパートは英語と同じ inline_data
        expect(parts[1]['inline_data']['mime_type'], 'audio/wav');
      },
    );

    test('hanziが無音マーカーならnoSpeech', () async {
      var requests = 0;
      final repository = GeminiTranscriptionRepository(
        testGeminiClient((request) async {
          requests++;
          return jsonResponse(
            geminiEnvelope({
              'pinyin': '',
              'hanzi': GeminiTranscriptionRepository.noSpeechMarker,
            }),
            200,
          );
        }),
      );

      await expectLater(
        repository.transcribe(_zh),
        _failsWith(FailureKind.noSpeech),
      );
      expect(requests, 1);
    });

    test('hanziが空文字でも聞き取れなかった扱いにする', () async {
      final repository = GeminiTranscriptionRepository(
        testGeminiClient(
          (request) async =>
              jsonResponse(geminiEnvelope({'pinyin': '', 'hanzi': ''}), 200),
        ),
      );

      await expectLater(
        repository.transcribe(_zh),
        _failsWith(FailureKind.noSpeech),
      );
    });

    test('pinyinが空で hanzi だけ返ってきた場合は reading を null にする', () async {
      final repository = GeminiTranscriptionRepository(
        testGeminiClient(
          (request) async =>
              jsonResponse(geminiEnvelope({'pinyin': '', 'hanzi': '我要睡'}), 200),
        ),
      );

      final result = await repository.transcribe(_zh);

      expect(result.text, '我要睡');
      expect(result.reading, isNull);
    });

    test('JSONとして解析できない応答はinvalidResponse', () async {
      final repository = GeminiTranscriptionRepository(
        testGeminiClient(
          (request) async => jsonResponse(geminiEnvelope('我要睡'), 200),
        ),
      );

      await expectLater(
        repository.transcribe(_zh),
        _failsWith(FailureKind.invalidResponse),
      );
    });
  });
}
