import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'gemini_service.dart';
import 'settings_service.dart';

/// 音声入力（マイク権限・音声認識）に失敗した際に投げられる例外。
///
/// [message]はUIにそのまま表示できる日本語文言。呼び出し側は必ず
/// 手入力フォールバックを用意すること。
class SpeechInputException implements Exception {
  SpeechInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 音声入力の抽象化。
///
/// [SettingsService.sttMode]に応じて[DeviceSpeechInputService]（端末STT）と
/// [GeminiSpeechInputService]（録音→Gemini文字起こし）のどちらかを使う。
/// UI側はこのインターフェースだけを見ればよい。
abstract class SpeechInputService {
  /// 音声入力を開始する。
  ///
  /// [onPartial]は認識中のテキストが更新されるたびに呼ばれる
  /// （device方式はリアルタイムの部分認識結果、gemini方式は録音中である旨の
  /// 固定文言）。マイク権限拒否・STT利用不可の場合は[SpeechInputException]を投げる。
  Future<void> start({required void Function(String text) onPartial});

  /// 音声入力を終了し、確定したテキストを返す。
  ///
  /// gemini方式の場合、ここで録音データをGeminiに送信して文字起こしする
  /// （[GeminiException]が投げられる場合がある）。
  Future<String> stop();

  /// このデバイス・設定で音声入力が利用可能かどうか。
  Future<bool> get isAvailable;

  /// 内部リソースを解放する。画面破棄時に必ず呼ぶこと。
  void dispose();
}

/// 端末のOS標準音声認識（speech_to_text）を使う実装。
///
/// リアルタイムに認識テキストを[onPartial]で流す。無料・高速だが、
/// 端末やOSバージョンによっては利用できない場合がある。
class DeviceSpeechInputService implements SpeechInputService {
  DeviceSpeechInputService({stt.SpeechToText? speechToText})
    : _speech = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _initialized = false;
  String _lastWords = '';
  Completer<void>? _finalResultCompleter;

  @override
  Future<bool> get isAvailable async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize();
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<void> start({required void Function(String text) onPartial}) async {
    if (!_initialized) {
      bool ok;
      try {
        ok = await _speech.initialize();
      } catch (_) {
        // 端末によってはPlatformException等を投げるため利用不可として扱う
        ok = false;
      }
      if (!ok) {
        throw SpeechInputException('端末の音声認識を利用できません。手入力してください。');
      }
      _initialized = true;
    }

    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      throw SpeechInputException('マイクの権限が許可されていません。手入力してください。');
    }

    _lastWords = '';
    _finalResultCompleter = Completer<void>();
    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onPartial(_lastWords);
        final completer = _finalResultCompleter;
        if (result.finalResult && completer != null && !completer.isCompleted) {
          completer.complete();
        }
      },
      // localeIdはlistenOptions側に指定する（deprecatedな引数と併用すると
      // listenOptionsが優先されlocaleIdの旧引数は無視されるため）。
      listenOptions: stt.SpeechListenOptions(
        localeId: 'en_US',
        partialResults: true,
      ),
    );
  }

  @override
  Future<String> stop() async {
    await _speech.stop();
    // 停止直後に最終確定結果が非同期で届くことがあるため、短時間だけ待つ。
    await _finalResultCompleter?.future.timeout(
      const Duration(milliseconds: 800),
      onTimeout: () {},
    );
    return _lastWords;
  }

  @override
  void dispose() {
    _speech.cancel();
  }
}

/// 録音してGeminiに文字起こしさせる実装。
///
/// `record`パッケージでwav(16kHz mono)を一時ファイルに録音し、[stop]で
/// [GeminiService.transcribe]に送信する。高精度だがAPIキーを消費し、
/// [stop]の完了までタイムラグがある。
class GeminiSpeechInputService implements SpeechInputService {
  // コンストラクタの公開パラメータ名（geminiService）と内部フィールド名
  // （_geminiService）をあえて分けているため、initializing formalは使わない
  // （使うとパラメータ名がprivateになり外部から渡せなくなる）。
  GeminiSpeechInputService({
    required GeminiService geminiService,
    AudioRecorder? recorder,
    // ignore: prefer_initializing_formals
  }) : _geminiService = geminiService,
       _recorder = recorder ?? AudioRecorder();

  final GeminiService _geminiService;
  final AudioRecorder _recorder;
  String? _recordingPath;

  @override
  Future<bool> get isAvailable => _recorder.hasPermission();

  @override
  Future<void> start({required void Function(String text) onPartial}) async {
    final granted = await _recorder.hasPermission();
    if (!granted) {
      throw SpeechInputException('マイクの権限が許可されていません。手入力してください。');
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/pj_walter_drill_${DateTime.now().microsecondsSinceEpoch}.wav';
    _recordingPath = path;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    onPartial('録音中…');
  }

  @override
  Future<String> stop() async {
    final stoppedPath = await _recorder.stop();
    final path = stoppedPath ?? _recordingPath;
    if (path == null) {
      throw SpeechInputException('録音データを取得できませんでした。手入力してください。');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw SpeechInputException('録音データを取得できませんでした。手入力してください。');
    }

    try {
      final bytes = await file.readAsBytes();
      return await _geminiService.transcribe(
        audioBytes: bytes,
        mimeType: 'audio/wav',
      );
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  @override
  void dispose() {
    unawaited(_recorder.dispose());
  }
}

/// [SettingsService.sttMode]に応じた[SpeechInputService]を組み立てる。
///
/// GeminiServiceが必要なため、Providerツリーから両サービスを取り出して渡す形にしている。
SpeechInputService createSpeechInputService({
  required SettingsService settingsService,
  required GeminiService geminiService,
}) {
  switch (settingsService.sttMode) {
    case SttMode.device:
      return DeviceSpeechInputService();
    case SttMode.gemini:
      return GeminiSpeechInputService(geminiService: geminiService);
  }
}
