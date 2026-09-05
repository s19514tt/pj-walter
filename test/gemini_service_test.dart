// GeminiServiceのレスポンスパース・エラー処理のテスト。
//
// http.Clientをpackage:http/testing.dartのMockClientで差し替え、
// 実際のネットワーク通信は行わない。

import 'dart:convert';
import 'dart:typed_data';

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
import 'package:pj_walter/models/learning_language.dart';

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
        profile: LanguageProfile.english,
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
          profile: LanguageProfile.english,
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
          profile: LanguageProfile.english,
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
          profile: LanguageProfile.english,
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
          profile: LanguageProfile.english,
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
        profile: LanguageProfile.english,
        topicJa: '朝ごはんについて話してください',
        topicTarget: 'Talk about your breakfast',
        seconds: 60,
        transcript: 'I eat toast this morning.',
      );

      expect(feedback.fluencyScore, 72);
      expect(feedback.corrections, hasLength(1));
      expect(feedback.usefulPhrases.single.target, 'It slipped my mind.');
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

      final (:text, :reading, :usage) = await service.transcribe(
        profile: LanguageProfile.english,
        audioBytes: [1, 2, 3],
        mimeType: 'audio/wav',
      );

      expect(text, 'This is the transcript.');
      // 英語ではピンインは返さない
      expect(reading, isNull);
      expect(
        usage,
        const TokenUsage(
          promptTokens: 320,
          candidatesTokens: 8,
          thoughtsTokens: 2,
        ),
      );
    });

    test('英語の文字起こしはプレーンテキストのまま（構造化出力にしない）', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(_geminiEnvelope('hello'), 200);
      });
      final service = GeminiService(settingsService: settings, client: client);

      await service.transcribe(
        profile: LanguageProfile.english,
        audioBytes: [1, 2, 3],
        mimeType: 'audio/wav',
      );

      final config = sentBody!['generationConfig'] as Map<String, dynamic>;
      expect(config.containsKey('responseMimeType'), isFalse);
      expect(config.containsKey('responseSchema'), isFalse);
      final parts = (sentBody!['contents'] as List).first['parts'] as List;
      expect(parts.first['text'], startsWith('Transcribe this 英語 speech'));
    });

    test('中国語の添削は corrected_reading を追加で要求し、CompositionFeedbackに入れる', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(
          _geminiEnvelope({
            'score': 90,
            'is_acceptable': true,
            'corrected': '我要水。',
            'corrected_reading': 'wǒ yào shuǐ',
            'explanation_ja': '解説',
            'comparison_ja': '比較',
          }),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (:feedback, usage: _) = await service.correctComposition(
        profile: LanguageProfile.chinese,
        ja: '水がほしい。',
        modelAnswer: '我要水。',
        spoken: '我要睡',
      );

      expect(feedback.correctedReading, 'wǒ yào shuǐ');
      final schema =
          (sentBody!['generationConfig'] as Map)['responseSchema'] as Map;
      expect((schema['properties'] as Map).keys, contains('corrected_reading'));
      expect(schema['required'], contains('corrected_reading'));
      final prompt =
          ((sentBody!['contents'] as List).first['parts'] as List).first['text']
              as String;
      expect(prompt, contains('corrected_reading'));
      // 採点方針の行はそのまま（声調はスコアに含めない）
      expect(prompt, contains('発音・声調は評価対象に含めません'));
    });

    test('英語の添削スキーマ・プロンプトに corrected_reading は入らない', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(
          _geminiEnvelope({
            'score': 90,
            'is_acceptable': true,
            'corrected': 'ok',
            'explanation_ja': '',
            'comparison_ja': '',
          }),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (:feedback, usage: _) = await service.correctComposition(
        profile: LanguageProfile.english,
        ja: 'ja',
        modelAnswer: 'model',
        spoken: 'spoken',
      );

      expect(feedback.correctedReading, isNull);
      final schema =
          (sentBody!['generationConfig'] as Map)['responseSchema'] as Map;
      expect(
        (schema['properties'] as Map).keys,
        isNot(contains('corrected_reading')),
      );
      final prompt =
          ((sentBody!['contents'] as List).first['parts'] as List).first['text']
              as String;
      expect(prompt, isNot(contains('corrected_reading')));
    });

    group('中国語（声調付きピンイン併記）', () {
      test(
        '構造化出力で pinyin→hanzi の順に生成させ、hanziをtext・pinyinをreadingとして返す',
        () async {
          Map<String, dynamic>? sentBody;
          final client = MockClient((request) async {
            sentBody = jsonDecode(request.body) as Map<String, dynamic>;
            return _jsonResponse(
              _geminiEnvelope(
                {'pinyin': 'wǒ yào shuì', 'hanzi': '我要睡'},
                usageMetadata: {
                  'promptTokenCount': 300,
                  'candidatesTokenCount': 30,
                },
              ),
              200,
            );
          });
          final service = GeminiService(
            settingsService: settings,
            client: client,
          );

          final (:text, :reading, :usage) = await service.transcribe(
            profile: LanguageProfile.chinese,
            audioBytes: [1, 2, 3],
            mimeType: 'audio/wav',
          );

          expect(text, '我要睡');
          expect(reading, 'wǒ yào shuì');
          expect(
            usage,
            const TokenUsage(promptTokens: 300, candidatesTokens: 30),
          );

          final config = sentBody!['generationConfig'] as Map<String, dynamic>;
          expect(config['responseMimeType'], 'application/json');
          final schema = config['responseSchema'] as Map<String, dynamic>;
          // 漢字を先に確定させるとピンインが辞書引きになるため、順序は固定
          expect(schema['propertyOrdering'], ['pinyin', 'hanzi']);
          expect(schema['required'], ['pinyin', 'hanzi']);
          expect(config['thinkingConfig'], {'thinkingLevel': 'low'});

          final parts = (sentBody!['contents'] as List).first['parts'] as List;
          final prompt = parts.first['text'] as String;
          expect(prompt, contains('聞こえた'));
          expect(prompt, contains(GeminiService.noSpeechMarker));
          // 音声のパートは英語と同じ inline_data
          expect(parts[1]['inline_data']['mime_type'], 'audio/wav');
        },
      );

      test('hanziが無音マーカーなら聞き取れなかった旨のGeminiExceptionになる', () async {
        var requests = 0;
        final client = MockClient((request) async {
          requests++;
          return _jsonResponse(
            _geminiEnvelope({
              'pinyin': '',
              'hanzi': GeminiService.noSpeechMarker,
            }),
            200,
          );
        });
        final service = GeminiService(
          settingsService: settings,
          client: client,
        );

        await expectLater(
          service.transcribe(
            profile: LanguageProfile.chinese,
            audioBytes: [1, 2, 3],
            mimeType: 'audio/wav',
          ),
          throwsA(
            isA<GeminiException>().having(
              (e) => e.message,
              'message',
              contains('聞き取れませんでした'),
            ),
          ),
        );
        expect(requests, 1);
      });

      test('hanziが空文字でも聞き取れなかった扱いにする', () async {
        final client = MockClient((request) async {
          return _jsonResponse(
            _geminiEnvelope({'pinyin': '', 'hanzi': ''}),
            200,
          );
        });
        final service = GeminiService(
          settingsService: settings,
          client: client,
        );

        await expectLater(
          service.transcribe(
            profile: LanguageProfile.chinese,
            audioBytes: [1, 2, 3],
            mimeType: 'audio/wav',
          ),
          throwsA(
            isA<GeminiException>().having(
              (e) => e.message,
              'message',
              contains('聞き取れませんでした'),
            ),
          ),
        );
      });

      test('pinyinが空で hanzi だけ返ってきた場合は reading を null にする', () async {
        final client = MockClient((request) async {
          return _jsonResponse(
            _geminiEnvelope({'pinyin': '', 'hanzi': '我要睡'}),
            200,
          );
        });
        final service = GeminiService(
          settingsService: settings,
          client: client,
        );

        final (:text, :reading, usage: _) = await service.transcribe(
          profile: LanguageProfile.chinese,
          audioBytes: [1, 2, 3],
          mimeType: 'audio/wav',
        );

        expect(text, '我要睡');
        expect(reading, isNull);
      });

      test('JSONとして解析できない応答は解析失敗のGeminiExceptionになる', () async {
        final client = MockClient((request) async {
          return _jsonResponse(_geminiEnvelope('我要睡'), 200);
        });
        final service = GeminiService(
          settingsService: settings,
          client: client,
        );

        await expectLater(
          service.transcribe(
            profile: LanguageProfile.chinese,
            audioBytes: [1, 2, 3],
            mimeType: 'audio/wav',
          ),
          throwsA(
            isA<GeminiException>().having(
              (e) => e.message,
              'message',
              contains('解析できませんでした'),
            ),
          ),
        );
      });
    });

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
        profile: LanguageProfile.english,
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

    test('無音マーカーの応答は聞き取れなかった旨のGeminiExceptionになる', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return _jsonResponse(
          _geminiEnvelope(' ${GeminiService.noSpeechMarker}\n'),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      await expectLater(
        service.transcribe(
          profile: LanguageProfile.english,
          audioBytes: [1, 2, 3],
          mimeType: 'audio/wav',
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.message,
            'message',
            contains('聞き取れませんでした'),
          ),
        ),
      );
      // 無音はモデルの明示的な判断なので送り直さない
      expect(requests, 1);
    });

    test('文字起こしプロンプトは無音時にマーカーを返すよう指示している', () async {
      String? sentPrompt;
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final parts = (body['contents'] as List).first['parts'] as List;
        sentPrompt = parts.first['text'] as String;
        return _jsonResponse(_geminiEnvelope('hello'), 200);
      });
      final service = GeminiService(settingsService: settings, client: client);

      await service.transcribe(
        profile: LanguageProfile.english,
        audioBytes: [1, 2, 3],
        mimeType: 'audio/wav',
      );

      expect(sentPrompt, contains(GeminiService.noSpeechMarker));
      expect(sentPrompt, isNot(contains('empty string')));
    });

    test('本文が空の応答（content: {}）は同じリクエストを送り直して成功させる', () async {
      final bodies = <String>[];
      final client = MockClient((request) async {
        bodies.add(request.body);
        if (bodies.length == 1) {
          return _jsonResponse(_emptyContentEnvelope, 200);
        }
        return _jsonResponse(
          _geminiEnvelope(
            'Second try.',
            usageMetadata: {'promptTokenCount': 203, 'candidatesTokenCount': 4},
          ),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (:text, :reading, :usage) = await service.transcribe(
        profile: LanguageProfile.english,
        audioBytes: [1, 2, 3],
        mimeType: 'audio/wav',
      );

      expect(text, 'Second try.');
      expect(reading, isNull);
      expect(bodies, hasLength(2));
      expect(bodies[0], bodies[1]);
      // 再試行分の入力トークンも課金されるため合算される
      expect(usage, const TokenUsage(promptTokens: 406, candidatesTokens: 4));
    });

    test('本文が空の応答が3回続いたら送り直しを促すGeminiExceptionになる', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return _jsonResponse(_emptyContentEnvelope, 200);
      });
      final service = GeminiService(settingsService: settings, client: client);

      await expectLater(
        service.transcribe(
          profile: LanguageProfile.english,
          audioBytes: [1, 2, 3],
          mimeType: 'audio/wav',
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('文字起こし結果が返ってきませんでした'),
              isNot(contains('聞き取れませんでした')),
            ),
          ),
        ),
      );
      expect(requests, 3);
    });

    test('添削でも本文が空の応答は送り直す', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        if (requests == 1) return _jsonResponse(_emptyContentEnvelope, 200);
        return _jsonResponse(
          _geminiEnvelope({
            'score': 90,
            'is_acceptable': true,
            'corrected': 'ok',
            'explanation_ja': '',
            'comparison_ja': '',
          }),
          200,
        );
      });
      final service = GeminiService(settingsService: settings, client: client);

      final (:feedback, usage: _) = await service.correctComposition(
        profile: LanguageProfile.english,
        ja: 'ja',
        modelAnswer: 'model',
        spoken: 'spoken',
      );

      expect(feedback.score, 90);
      expect(requests, 2);
    });
  });

  group('synthesizeSpeech', () {
    /// TTSモデルが返す音声応答（base64のPCM16 + mimeType）の形。
    Map<String, dynamic> audioEnvelope(
      List<int> pcm, {
      String mimeType = 'audio/L16;codec=pcm;rate=24000',
      Map<String, dynamic>? usageMetadata,
    }) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'inlineData': {'mimeType': mimeType, 'data': base64Encode(pcm)},
              },
            ],
          },
        },
      ],
      'usageMetadata': ?usageMetadata,
    };

    test('TTSモデル・音声モダリティ・プリセット音声を指定して呼び出す', () async {
      http.Request? capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return _jsonResponse(audioEnvelope(const [1, 2, 3, 4]), 200);
      });
      final service = GeminiService(settingsService: settings, client: client);

      await service.synthesizeSpeech(
        profile: LanguageProfile.english,
        text: 'I had toast this morning.',
      );

      // 添削・文字起こしとは別のTTSモデルを叩く（modelNameは音声出力に非対応）
      expect(
        capturedRequest!.url.toString(),
        contains('${GeminiService.ttsModelName}:generateContent'),
      );
      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      final config = body['generationConfig'] as Map<String, dynamic>;
      expect(config['responseModalities'], ['AUDIO']);
      expect(
        config['speechConfig']['voiceConfig']['prebuiltVoiceConfig']['voiceName'],
        GeminiService.ttsVoiceName,
      );
      // 読み上げ対象の文がプロンプトに入っている
      expect(
        body['contents'][0]['parts'][0]['text'],
        contains('I had toast this morning.'),
      );
    });

    test('PCM応答にWAVヘッダーを付けて返し、usageMetadataも読み取る', () async {
      // 8バイトのPCM16（4サンプル）
      const pcm = [0, 1, 2, 3, 4, 5, 6, 7];
      final client = MockClient(
        (request) async => _jsonResponse(
          audioEnvelope(
            pcm,
            usageMetadata: {
              'promptTokenCount': 12,
              'candidatesTokenCount': 340,
            },
          ),
          200,
        ),
      );
      final service = GeminiService(settingsService: settings, client: client);

      final result = await service.synthesizeSpeech(
        profile: LanguageProfile.english,
        text: 'Hello.',
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

    test('音声が入っていない応答は読み上げ失敗のGeminiExceptionになる', () async {
      final client = MockClient(
        (request) async => _jsonResponse({
          'candidates': [
            {'content': <String, dynamic>{}},
          ],
        }, 200),
      );
      final service = GeminiService(settingsService: settings, client: client);

      expect(
        () => service.synthesizeSpeech(
          profile: LanguageProfile.english,
          text: 'Hello.',
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.message,
            'message',
            contains('読み上げ音声を取得できませんでした'),
          ),
        ),
      );
    });

    test('APIキー未設定なら通信せずGeminiExceptionを投げる', () async {
      await settings.deleteApiKey();
      final client = MockClient((request) async {
        fail('APIキー未設定時は通信してはいけない');
      });
      final service = GeminiService(settingsService: settings, client: client);

      expect(
        () => service.synthesizeSpeech(
          profile: LanguageProfile.english,
          text: 'Hello.',
        ),
        throwsA(isA<GeminiException>()),
      );
    });
  });
}

/// 出力トークンが0で`parts`ごと省略された応答（実際にGeminiが返したもの）。
const _emptyContentEnvelope = {
  'candidates': [
    {'content': <String, dynamic>{}, 'finishReason': 'STOP', 'index': 0},
  ],
  'usageMetadata': {
    'promptTokenCount': 203,
    'totalTokenCount': 203,
    'promptTokensDetails': [
      {'modality': 'TEXT', 'tokenCount': 39},
      {'modality': 'AUDIO', 'tokenCount': 164},
    ],
    'serviceTier': 'standard',
  },
  'modelVersion': 'gemini-3.8-flash',
  'responseId': 'BNSaarXZIpzCvr0P4Or_mAc',
};
