// Gemini 実装の Repository / GeminiClient のテスト共通ヘルパー。
//
// http.Client を package:http/testing.dart の MockClient で差し替え、
// 実際のネットワーク通信は行わない。

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pj_walter/core/data/gemini_client.dart';

/// テストで使う API キー。
const testApiKey = 'test-api-key';

/// [handler] に応答させる [GeminiClient]。[apiKey] を null にすると未設定扱い。
GeminiClient testGeminiClient(
  MockClientHandler handler, {
  String? apiKey = testApiKey,
}) => GeminiClient(apiKey: () => apiKey, client: MockClient(handler));

/// Gemini 応答のエンベロープ（テキスト or JSON ペイロード）。
Map<String, dynamic> geminiEnvelope(
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

/// 出力トークンが0で`parts`ごと省略された応答（実際にGeminiが返したもの）。
const emptyContentEnvelope = {
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

/// JSON文字列をUTF-8のResponseとして返す。
///
/// http.Responseはヘッダーでcharsetを明示しないとlatin1でエンコードするため、
/// 日本語を含むボディでは明示的にcharset=utf-8を指定する必要がある。
http.Response jsonResponse(Object payload, int statusCode) => http.Response(
  jsonEncode(payload),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// リクエスト本文の JSON。
Map<String, dynamic> requestJson(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;

/// リクエスト本文の最初のテキストパート（プロンプト）。
String requestPrompt(http.Request request) =>
    ((requestJson(request)['contents'] as List).first['parts'] as List)
            .first['text']
        as String;
