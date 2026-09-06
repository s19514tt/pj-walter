import 'package:pj_walter/core/domain/token_usage.dart';
import 'package:pj_walter/features/speech/domain/speech_input_service.dart';

/// テスト用のフェイク音声入力サービス。
///
/// [start]は固定の状態テキストを1回流し、[stop]は
/// あらかじめ設定した[stopResult]（またはエラー）を[stopUsage]付きで返す。
class FakeSpeechInputService implements SpeechInputService {
  FakeSpeechInputService({this.stopResult = 'this is my spoken answer'});

  String stopResult;

  /// 文字起こしと一緒に返すピンイン（中国語モードのテスト用。既定は英語同様null）
  String? stopReading;
  Object? stopError;
  bool startCalled = false;
  bool stopCalled = false;
  bool cancelCalled = false;
  int disposeCount = 0;

  /// 文字起こし1回分のトークン使用量（音声入力分は入力300・出力10）
  TokenUsage stopUsage = const TokenUsage(
    promptTokens: 300,
    candidatesTokens: 10,
  );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<void> start({
    void Function(String text)? onPartial,
    void Function(double level)? onLevel,
  }) async {
    startCalled = true;
    onPartial?.call('partial text...');
    onLevel?.call(0.5);
  }

  @override
  Future<SpeechInputResult> stop() async {
    stopCalled = true;
    final error = stopError;
    if (error != null) throw error;
    return SpeechInputResult(
      text: stopResult,
      reading: stopReading,
      usage: stopUsage,
    );
  }

  @override
  Future<void> cancel() async {
    cancelCalled = true;
  }

  @override
  void dispose() => disposeCount++;
}
