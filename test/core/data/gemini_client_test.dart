// GeminiClient（共通トランスポート）のステータス判定・再試行・usageMetadata・
// 音声応答のテスト。

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pj_walter/core/data/gemini_client.dart';
import 'package:pj_walter/core/domain/app_failure.dart';
import 'package:pj_walter/core/domain/token_usage.dart';

import '../../test_support/gemini_test_support.dart';

void main() {
  const schema = {
    'type': 'OBJECT',
    'properties': {
      'ok': {'type': 'BOOLEAN'},
    },
  };

  group('generateJson', () {
    test('APIキーをヘッダーに付け、固定モデルを叩き、JSONとusageを返す', () async {
      http.Request? captured;
      final client = testGeminiClient((request) async {
        captured = request;
        return jsonResponse(
          geminiEnvelope(
            {'ok': true},
            usageMetadata: {
              'promptTokenCount': 150,
              'candidatesTokenCount': 40,
              'totalTokenCount': 190,
            },
          ),
          200,
        );
      });

      final (:json, :usage) = await client.generateJson(
        prompt: 'p',
        schema: schema,
      );

      expect(json, {'ok': true});
      // thoughtsTokenCount が無ければ 0
      expect(usage, const TokenUsage(promptTokens: 150, candidatesTokens: 40));
      expect(captured!.headers['x-goog-api-key'], testApiKey);
      expect(captured!.url.query, isNot(contains(testApiKey)));
      expect(
        captured!.url.toString(),
        contains('${GeminiClient.modelName}:generateContent'),
      );
      final body = requestJson(captured!);
      final config = body['generationConfig'] as Map<String, dynamic>;
      expect(config['responseMimeType'], 'application/json');
      expect(config['responseSchema'], schema);
      expect(config['thinkingConfig'], {'thinkingLevel': 'low'});
    });

    test('usageMetadataが無い応答は使用量ゼロ', () async {
      final client = testGeminiClient(
        (request) async => jsonResponse(geminiEnvelope({'ok': true}), 200),
      );

      final (json: _, :usage) = await client.generateJson(
        prompt: 'p',
        schema: schema,
      );

      expect(usage, TokenUsage.zero);
    });

    test('401/403はapiKeyInvalid', () async {
      final client = testGeminiClient(
        (request) async => http.Response('{"error": "unauthorized"}', 401),
      );

      await expectLater(
        client.generateJson(prompt: 'p', schema: schema),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.apiKeyInvalid,
          ),
        ),
      );
    });

    test('429はrateLimited、400はbadRequest、5xxはserverError', () async {
      Future<FailureKind> kindFor(int status) async {
        final client = testGeminiClient(
          (request) async => http.Response('error', status),
        );
        try {
          await client.generateJson(prompt: 'p', schema: schema);
        } on AppFailure catch (e) {
          return e.kind;
        }
        fail('例外にならなかった');
      }

      expect(await kindFor(429), FailureKind.rateLimited);
      expect(await kindFor(400), FailureKind.badRequest);
      expect(await kindFor(500), FailureKind.serverError);
      expect(await kindFor(418), FailureKind.unexpectedStatus);
    });

    test('JSONとして解析できない本文はinvalidResponse', () async {
      final client = testGeminiClient(
        (request) async => jsonResponse(geminiEnvelope('not json'), 200),
      );

      await expectLater(
        client.generateJson(prompt: 'p', schema: schema),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.invalidResponse,
          ),
        ),
      );
    });

    test('APIキー未設定なら通信せずapiKeyMissing', () async {
      final client = testGeminiClient((request) async {
        fail('APIキー未設定時は通信してはいけない');
      }, apiKey: null);

      await expectLater(
        client.generateJson(prompt: 'p', schema: schema),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.apiKeyMissing,
          ),
        ),
      );
    });
  });

  group('generateText', () {
    test('本文が空の応答（content: {}）は同じリクエストを送り直して成功させる', () async {
      final bodies = <String>[];
      final client = testGeminiClient((request) async {
        bodies.add(request.body);
        if (bodies.length == 1) {
          return jsonResponse(emptyContentEnvelope, 200);
        }
        return jsonResponse(
          geminiEnvelope(
            'Second try.',
            usageMetadata: {'promptTokenCount': 203, 'candidatesTokenCount': 4},
          ),
          200,
        );
      });

      final (:text, :usage) = await client.generateText(
        parts: [
          {'text': 'hello'},
        ],
      );

      expect(text, 'Second try.');
      expect(bodies, hasLength(2));
      expect(bodies[0], bodies[1]);
      // 再試行分の入力トークンも課金されるため合算される
      expect(usage, const TokenUsage(promptTokens: 406, candidatesTokens: 4));
    });

    test('本文が空の応答が3回続いたら空文字を返す（意味付けは呼び出し側）', () async {
      var requests = 0;
      final client = testGeminiClient((request) async {
        requests++;
        return jsonResponse(emptyContentEnvelope, 200);
      });

      final (:text, usage: _) = await client.generateText(
        parts: [
          {'text': 'hello'},
        ],
      );

      expect(text, isEmpty);
      expect(requests, GeminiClient.maxAttempts);
    });

    test('responseSchemaを渡さなければ構造化出力にしない', () async {
      http.Request? captured;
      final client = testGeminiClient((request) async {
        captured = request;
        return jsonResponse(geminiEnvelope('hello'), 200);
      });

      await client.generateText(
        parts: [
          {'text': 'p'},
        ],
      );

      final config =
          requestJson(captured!)['generationConfig'] as Map<String, dynamic>;
      expect(config.containsKey('responseMimeType'), isFalse);
      expect(config.containsKey('responseSchema'), isFalse);
    });
  });

  group('generateSpeech', () {
    test('TTSモデル・音声モダリティ・プリセット音声を指定して呼び出す', () async {
      http.Request? captured;
      final client = testGeminiClient((request) async {
        captured = request;
        return jsonResponse(audioEnvelope(const [1, 2, 3, 4]), 200);
      });

      await client.generateSpeech(
        instruction: 'Read: I had toast this morning.',
        voiceName: 'Kore',
      );

      // 添削・文字起こしとは別のTTSモデルを叩く（modelNameは音声出力に非対応）
      expect(
        captured!.url.toString(),
        contains('${GeminiClient.ttsModelName}:generateContent'),
      );
      final body = requestJson(captured!);
      final config = body['generationConfig'] as Map<String, dynamic>;
      expect(config['responseModalities'], ['AUDIO']);
      expect(
        config['speechConfig']['voiceConfig']['prebuiltVoiceConfig']['voiceName'],
        'Kore',
      );
      // TTSモデルは思考を持たない
      expect(config.containsKey('thinkingConfig'), isFalse);
      expect(
        body['contents'][0]['parts'][0]['text'],
        contains('I had toast this morning.'),
      );
    });

    test('PCMとmimeTypeのサンプリングレート、usageMetadataを返す', () async {
      const pcm = [0, 1, 2, 3, 4, 5, 6, 7];
      final client = testGeminiClient(
        (request) async => jsonResponse(
          audioEnvelope(
            pcm,
            mimeType: 'audio/L16;codec=pcm;rate=16000',
            usageMetadata: {
              'promptTokenCount': 12,
              'candidatesTokenCount': 340,
            },
          ),
          200,
        ),
      );

      final result = await client.generateSpeech(
        instruction: 'Hello.',
        voiceName: 'Kore',
      );

      expect(result.pcm, Uint8List.fromList(pcm));
      expect(result.sampleRate, 16000);
      expect(
        result.usage,
        const TokenUsage(promptTokens: 12, candidatesTokens: 340),
      );
    });

    test('音声が入っていない応答はnoAudio', () async {
      final client = testGeminiClient(
        (request) async => jsonResponse({
          'candidates': [
            {'content': <String, dynamic>{}},
          ],
        }, 200),
      );

      await expectLater(
        client.generateSpeech(instruction: 'Hello.', voiceName: 'Kore'),
        throwsA(
          isA<AppFailure>().having((e) => e.kind, 'kind', FailureKind.noAudio),
        ),
      );
    });

    test('APIキー未設定なら通信せずapiKeyMissing', () async {
      final client = testGeminiClient((request) async {
        fail('APIキー未設定時は通信してはいけない');
      }, apiKey: null);

      await expectLater(
        client.generateSpeech(instruction: 'Hello.', voiceName: 'Kore'),
        throwsA(
          isA<AppFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.apiKeyMissing,
          ),
        ),
      );
    });
  });
}
