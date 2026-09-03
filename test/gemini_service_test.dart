// GeminiServiceのレスポンスパース・エラー処理のテスト。
//
// http.Clientをpackage:http/testing.dartのMockClientで差し替え、
// 実際のネットワーク通信は行わない。

import 'dart:convert';

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pj_walter/models/token_usage.dart';
import 'package:pj_walter/services/gemini_service.dart';
import 'package:pj_walter/services/settings_service.dart';

import 'test_support/hive_test_support.dart';

Map<String, dynamic> _geminiEnvelope(
  Object payload, {
  Map<String, dynamic>? usageMetadata,
}) => {
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': payload is String ? payload : jsonEncode(payload)},
        ],
      },
    },
  ],
  'usageMetadata': ?usageMetadata,
};

/// JSON文字列をUTF-8のResponseとして返す。
///
/// http.Responseはヘッダーでcharsetを明示しないとlatin1でエンコードするため、
/// 日本語を含むボディでは明示的にcharset=utf-8を指定する必要がある。
http.Response _jsonResponse(Object payload, int statusCode) => http.Response(
  jsonEncode(payload),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  late SettingsService settings;

  setUp(() async {
    await initTestHive();
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    final settingsBox = await Hive.openBox('settings');
    settings = SettingsService(settingsBox: settingsBox);
    await settings.init();
    await settings.setApiKey('test-api-key');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('correctComposition', () {
    test('200応答をCompositionFeedbackに変換する', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return _jsonResponse(
          _geminiEnvelope({
            'score': 85,
            'is_acceptable': true,
            'corrected': "I'll call you back later.",
            'explanation_ja': '概ね正しいです。',
            'comparison_ja': '模範解答とほぼ同じです。',
          }),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (:feedback, :usage) = await service.correctComposition(
        ja: 'この件については後ほど折り返しご連絡します。',
        modelAnswer: "I'll get back to you on this matter later.",
        spoken: "I'll call you back later",
      );

      expect(feedback.score, 85);
      expect(feedback.isAcceptable, true);
      expect(feedback.corrected, "I'll call you back later.");
      // usageMetadataが無い応答では使用量ゼロとして扱う
      expect(usage, TokenUsage.zero);
      expect(capturedRequest?.headers['x-goog-api-key'], 'test-api-key');
      expect(
        capturedRequest?.url.toString(),
        contains('${GeminiService.modelName}:generateContent'),
      );
    });

    test('401応答はAPIキー無効のGeminiExceptionを投げる', () async {
      final client = MockClient((request) async {
        return http.Response('{"error": "unauthorized"}', 401);
      });
      final service = GeminiService(settingsService: settings, client: client);

      expect(
        () => service.correctComposition(
          ja: 'ja',
          modelAnswer: 'model',
          spoken: 'spoken',
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.message,
            'message',
            contains('APIキーが無効です'),
          ),
        ),
      );
    });

    test('500応答はサーバーエラーのGeminiExceptionを投げる', () async {
      final client = MockClient((request) async {
        return http.Response('server error', 500);
      });
      final service = GeminiService(settingsService: settings, client: client);

      expect(
        () => service.correctComposition(
          ja: 'ja',
          modelAnswer: 'model',
          spoken: 'spoken',
        ),
        throwsA(isA<GeminiException>()),
      );
    });

    test('不正なJSON応答はパースエラーのGeminiExceptionを投げる', () async {
      final client = MockClient((request) async {
        return _jsonResponse(_geminiEnvelope('not json'), 200);
      });
      final service = GeminiService(settingsService: settings, client: client);

      expect(
        () => service.correctComposition(
          ja: 'ja',
          modelAnswer: 'model',
          spoken: 'spoken',
        ),
        throwsA(isA<GeminiException>()),
      );
    });

    test('APIキー未設定なら通信せずGeminiExceptionを投げる', () async {
      await settings.deleteApiKey();
      final client = MockClient((request) async {
        fail('APIキー未設定時は通信してはいけない');
      });
      final service = GeminiService(settingsService: settings, client: client);

      expect(
        () => service.correctComposition(
          ja: 'ja',
          modelAnswer: 'model',
          spoken: 'spoken',
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.message,
            'message',
            contains('APIキーが設定されていません'),
          ),
        ),
      );
    });
  });

  group('reviewMonologue', () {
    test('200応答をMonologueFeedbackに変換する', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _geminiEnvelope({
            'fluency_score': 72,
            'corrected_transcript': 'I had toast this morning.',
            'corrections': [
              {
                'original': 'I eat toast',
                'corrected': 'I had toast',
                'reason_ja': '過去形が適切です。',
              },
            ],
            'useful_phrases': [
              {'en': 'It slipped my mind.', 'ja': 'うっかり忘れていた'},
            ],
            'overall_feedback_ja': '良く話せていました。',
          }),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (:feedback, usage: _) = await service.reviewMonologue(
        topicJa: '朝ごはんについて話してください',
        topicEn: 'Talk about your breakfast',
        seconds: 60,
        transcript: 'I eat toast this morning.',
      );

      expect(feedback.fluencyScore, 72);
      expect(feedback.corrections, hasLength(1));
      expect(feedback.usefulPhrases.single.en, 'It slipped my mind.');
    });
  });

  group('transcribe', () {
    test('プレーンテキスト応答とusageMetadataを返す', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _geminiEnvelope(
            'This is the transcript.',
            usageMetadata: {
              'promptTokenCount': 320,
              'candidatesTokenCount': 8,
              'thoughtsTokenCount': 2,
              'totalTokenCount': 330,
            },
          ),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (:text, :usage) = await service.transcribe(
        audioBytes: [1, 2, 3],
        mimeType: 'audio/wav',
      );

      expect(text, 'This is the transcript.');
      expect(
        usage,
        const TokenUsage(
          promptTokens: 320,
          candidatesTokens: 8,
          thoughtsTokens: 2,
        ),
      );
    });
  });

  group('usageMetadata', () {
    test('構造化出力でもusageMetadataを読み取り、thoughtsが無ければ0にする', () async {
      final client = MockClient((request) async {
        return _jsonResponse(
          _geminiEnvelope(
            {
              'score': 80,
              'is_acceptable': true,
              'corrected': 'ok',
              'explanation_ja': '',
              'comparison_ja': '',
            },
            usageMetadata: {
              'promptTokenCount': 150,
              'candidatesTokenCount': 40,
              'totalTokenCount': 190,
            },
          ),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (feedback: _, :usage) = await service.correctComposition(
        ja: 'ja',
        modelAnswer: 'model',
        spoken: 'spoken',
      );

      expect(usage.promptTokens, 150);
      expect(usage.candidatesTokens, 40);
      expect(usage.thoughtsTokens, 0);
      expect(usage.billedOutputTokens, 40);
      expect(usage.totalTokens, 190);
    });
  });
}
