// GeminiTtsRepository（読み上げ音声の生成）のテスト。

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/features/speech/data/gemini_tts_repository.dart';
import 'package:pj_walter/features/speech/domain/tts_repository.dart';

import '../../../test_support/gemini_test_support.dart';

void main() {
  test('学習言語の英語名と文を指示文に入れ、言語のTTSボイスを指定する', () async {
    http.Request? captured;
    final repository = GeminiTtsRepository(
      testGeminiClient((request) async {
        captured = request;
        return jsonResponse(audioEnvelope(const [1, 2, 3, 4]), 200);
      }),
    );

    await repository.synthesize(
      const TtsRequest(learningLanguage: 'zh', text: '我要水。'),
    );

    final body = requestJson(captured!);
    final text = body['contents'][0]['parts'][0]['text'] as String;
    expect(text, contains('Chinese (Mandarin)'));
    expect(text, contains('我要水。'));
    expect(
      body['generationConfig']['speechConfig']['voiceConfig']['prebuiltVoiceConfig']['voiceName'],
      'Kore',
    );
  });

  test('PCM応答にWAVヘッダーを付けて返し、usageMetadataも読み取る', () async {
    // 8バイトのPCM16（4サンプル）
    const pcm = [0, 1, 2, 3, 4, 5, 6, 7];
    final repository = GeminiTtsRepository(
      testGeminiClient(
        (request) async => jsonResponse(
          audioEnvelope(
            pcm,
            usageMetadata: {
              'promptTokenCount': 12,
              'candidatesTokenCount': 340,
            },
          ),
          200,
        ),
      ),
    );

    final result = await repository.synthesize(
      const TtsRequest(learningLanguage: 'en', text: 'Hello.'),
    );

    // 44バイトのWAVヘッダー＋PCM本体
    expect(result.wavBytes.length, 44 + pcm.length);
    expect(String.fromCharCodes(result.wavBytes.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(result.wavBytes.sublist(8, 12)), 'WAVE');
    expect(result.wavBytes.sublist(44), pcm);
    // mimeTypeのrate=24000がWAVヘッダーのサンプリングレートに反映される
    final sampleRate = ByteData.sublistView(
      result.wavBytes,
      24,
      28,
    ).getUint32(0, Endian.little);
    expect(sampleRate, 24000);
    expect(
      result.usage,
      const TokenUsage(promptTokens: 12, candidatesTokens: 340),
    );
  });
}
