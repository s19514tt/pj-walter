// CloudTtsService（Google Cloud Text-to-Speech）のリクエスト組み立て・
// レスポンスパース・エラー処理のテスト。
//
// http.ClientをMockClientで差し替え、実際のネットワーク通信は行わない。
// 再生（audioplayers）はプラットフォームチャンネルに触るため、ここでは
// 音声合成（synthesize）だけを対象にする。

import 'dart:convert';

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pj_walter/models/learning_language.dart';
import 'package:pj_walter/services/settings_service.dart';
import 'package:pj_walter/services/tts_service.dart';

import '../test_support/hive_test_support.dart';

/// Cloud TTS の成功応答（base64のMP3）。
http.Response _audioResponse(List<int> audio) => http.Response(
  jsonEncode({'audioContent': base64Encode(audio)}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// 通信失敗を模した例外（dart:ioに依存せずどのプラットフォームでも動くように）。
class _NetworkFailure implements Exception {
  const _NetworkFailure();
}

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
    await settings.setApiKey('gemini-key');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  CloudTtsService service(
    http.Client client, {
    LanguageProfile profile = LanguageProfile.english,
  }) => CloudTtsService(
    settingsService: settings,
    profile: profile,
    client: client,
  );

  test('中国語はcmn-CNのWaveNet音声と読み上げ速度を指定して呼び出す', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return _audioResponse(const [1, 2, 3]);
    });

    await service(client, profile: LanguageProfile.chinese).synthesize('我要水。');

    expect(
      captured!.url.toString(),
      'https://texttospeech.googleapis.com/v1/text:synthesize',
    );
    // APIキーはURLではなくヘッダーで送る（URLに載せるとログに残るため）
    expect(captured!.headers['x-goog-api-key'], 'gemini-key');
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['input'], {'text': '我要水。'});
    // 教材側の言語コード（zh）ではなくCloud TTSの表記（cmn-CN）を送る
    expect(body['voice'], {
      'languageCode': 'cmn-CN',
      'name': 'cmn-CN-Wavenet-A',
    });
    expect(body['audioConfig'], {
      'audioEncoding': CloudTtsService.audioEncoding,
      'speakingRate': CloudTtsService.speakingRate,
    });
  });

  test('英語はen-USのWaveNet音声を使う', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return _audioResponse(const [1]);
    });

    await service(client).synthesize('Hello.');

    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['voice'], {'languageCode': 'en-US', 'name': 'en-US-Wavenet-F'});
  });

  test('audioContentのbase64をデコードして返す', () async {
    const audio = [0xFF, 0xFB, 0x90, 0x00];
    final client = MockClient((request) async => _audioResponse(audio));

    expect(await service(client).synthesize('Hello.'), audio);
  });

  test('Cloud TTS用のキーが登録されていればGeminiのキーより優先する', () async {
    await settings.setCloudTtsApiKey('tts-key');
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return _audioResponse(const [1]);
    });

    await service(client).synthesize('Hello.');

    expect(captured!.headers['x-goog-api-key'], 'tts-key');
  });

  test('403はAPIの有効化を案内するメッセージになる', () async {
    // キーが有効でもCloud TTS APIが有効化されていなければ403が返るため、
    // 「キーが無効」だけの案内にしない。
    final client = MockClient((request) async => http.Response('{}', 403));

    expect(
      () => service(client).synthesize('Hello.'),
      throwsA(
        isA<TtsException>().having(
          (e) => e.message,
          'message',
          contains('Cloud Text-to-Speech API'),
        ),
      ),
    );
  });

  test('audioContentが空の応答は読み上げ失敗になる', () async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode({'audioContent': ''}), 200),
    );

    expect(
      () => service(client).synthesize('Hello.'),
      throwsA(
        isA<TtsException>().having(
          (e) => e.message,
          'message',
          contains('読み上げ音声を取得できませんでした'),
        ),
      ),
    );
  });

  test('APIキー未設定なら通信せずTtsExceptionを投げる', () async {
    await settings.deleteApiKey();
    final client = MockClient((request) async {
      fail('APIキー未設定時は通信してはいけない');
    });

    expect(
      () => service(client).synthesize('Hello.'),
      throwsA(
        isA<TtsException>().having(
          (e) => e.message,
          'message',
          contains('APIキーが設定されていません'),
        ),
      ),
    );
  });

  test('通信エラーはネットワークを案内するメッセージになる', () async {
    final client = MockClient((request) async => throw const _NetworkFailure());

    expect(
      () => service(client).synthesize('Hello.'),
      throwsA(
        isA<TtsException>().having(
          (e) => e.message,
          'message',
          contains('ネットワーク接続'),
        ),
      ),
    );
  });
}
