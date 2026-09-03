import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../utils/pcm_converter.dart';
import '../utils/wav_builder.dart';
import 'gemini_service.dart';
import 'settings_service.dart';

/// 音声入力（マイク権限・音声認識）に失敗した際に投げられる例外。
///
/// [message]はUIにそのまま表示できる日本語文言。呼び出し側は録り直し等の
/// リカバリー導線を用意すること。
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
  ///
  /// [onLevel]は録音中の入力音量（0.0〜1.0に正規化）が更新されるたびに
  /// 呼ばれる。UI側で音量メーター表示に使う。プラットフォームが音量を
  /// 提供しない場合は呼ばれないことがある。
  ///
  /// [listenFor]・[pauseFor]はdevice方式（[DeviceSpeechInputService]）でのみ
  /// 使われるオプションで、独り言英会話のような長時間発話向けに
  /// 認識継続時間・無音許容時間を調整するためのもの。省略時（null）は
  /// 口頭英作文の短文発話に適した既存の挙動を維持する。gemini方式では無視される。
  Future<void> start({
    required void Function(String text) onPartial,
    void Function(double level)? onLevel,
    Duration? listenFor,
    Duration? pauseFor,
  });

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

  // onSoundLevelChangeの生値レンジはOSごとに異なる（iOSはdB負値〜、Androidは
  // 正値など）ため、セッション中の最小・最大を追跡して0〜1に正規化する。
  double _minLevel = double.infinity;
  double _maxLevel = double.negativeInfinity;

  double _normalizeLevel(double raw) {
    if (raw < _minLevel) _minLevel = raw;
    if (raw > _maxLevel) _maxLevel = raw;
    final range = _maxLevel - _minLevel;
    if (range < 1e-6) return 0;
    return ((raw - _minLevel) / range).clamp(0.0, 1.0);
  }

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
  Future<void> start({
    required void Function(String text) onPartial,
    void Function(double level)? onLevel,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_initialized) {
      bool ok;
      try {
        ok = await _speech.initialize();
      } catch (_) {
        // 端末によってはPlatformException等を投げるため利用不可として扱う
        ok = false;
      }
      if (!ok) {
        throw SpeechInputException('端末の音声認識を利用できません。');
      }
      _initialized = true;
    }

    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      throw SpeechInputException('マイクの権限が許可されていません。設定でマイクを許可してください。');
    }

    _lastWords = '';
    _finalResultCompleter = Completer<void>();
    _minLevel = double.infinity;
    _maxLevel = double.negativeInfinity;
    // listenFor/pauseForが渡された場合（独り言英会話などの長時間発話）は
    // ListenMode.dictationにし、無音許容時間・最大継続時間を延長する。
    // 未指定時（口頭英作文の短文発話）は既存の挙動を変えないため
    // ListenMode.confirmation・両方nullのままにする。
    final longForm = listenFor != null || pauseFor != null;
    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onPartial(_lastWords);
        final completer = _finalResultCompleter;
        if (result.finalResult && completer != null && !completer.isCompleted) {
          completer.complete();
        }
      },
      onSoundLevelChange: onLevel == null
          ? null
          : (raw) => onLevel(_normalizeLevel(raw)),
      // localeIdはlistenOptions側に指定する（deprecatedな引数と併用すると
      // listenOptionsが優先されlocaleIdの旧引数は無視されるため）。
      listenOptions: stt.SpeechListenOptions(
        localeId: 'en_US',
        partialResults: true,
        listenMode: longForm
            ? stt.ListenMode.dictation
            : stt.ListenMode.confirmation,
        listenFor: listenFor,
        pauseFor: pauseFor,
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
/// `record`パッケージの`startStream`でPCM16チャンクをメモリ上の
/// [BytesBuilder]に蓄積し、[stop]で16kHzモノラルに揃えて（[convertPcm16]）
/// WAVヘッダー（[buildWavBytes]）を付けて[GeminiService.transcribe]に送信する。
/// ファイルI/Oを一切使わないためWeb/Android/iOS全てで同じコードパスが動く
/// （`startStream`は全対応）。高精度だがAPIキーを消費し、[stop]の完了まで
/// タイムラグがある。
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

  static const _sampleRate = 16000;
  static const _channels = 1;

  final GeminiService _geminiService;
  final AudioRecorder _recorder;
  BytesBuilder? _bytesBuilder;
  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Completer<void>? _streamDone;
  // 実際に録音されたフォーマット。要求値と同じとは限らないため
  // `setOnConfigChanged`で通知された値で上書きする。
  int _recordedSampleRate = _sampleRate;
  int _recordedChannels = _channels;

  @override
  Future<bool> get isAvailable => _recorder.hasPermission();

  @override
  Future<void> start({
    required void Function(String text) onPartial,
    void Function(double level)? onLevel,
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    // listenFor/pauseForはdevice方式専用のオプションのためここでは使わない。
    final granted = await _recorder.hasPermission();
    if (!granted) {
      throw SpeechInputException('マイクの権限が許可されていません。設定でマイクを許可してください。');
    }

    final bytesBuilder = BytesBuilder(copy: false);
    _bytesBuilder = bytesBuilder;
    final streamDone = Completer<void>();
    _streamDone = streamDone;

    // 16kHz/monoを要求してもハードウェア・ブラウザ都合で書き換えられることがある
    // （Chromeは`AudioContext`の実サンプルレート48kHzが採用され、Androidは入力
    // デバイスに合わせてステレオになりうる）。PCMの生バイト列からは実フォーマットを
    // 判別できず、そのまま16kHz/monoのWAVヘッダーを付けると再生速度・音程がずれて
    // Geminiが意味不明な文字起こしを返すため、実フォーマットを受け取って[stop]で
    // 変換する。書き換えが無ければこのコールバックは呼ばれない。
    _recordedSampleRate = _sampleRate;
    _recordedChannels = _channels;
    await _recorder.setOnConfigChanged((config) {
      _recordedSampleRate = config.sampleRate;
      _recordedChannels = config.numChannels;
    });

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: _channels,
      ),
    );
    _subscription = stream.listen(
      bytesBuilder.add,
      onDone: () {
        if (!streamDone.isCompleted) streamDone.complete();
      },
      onError: (Object _, StackTrace _) {
        if (!streamDone.isCompleted) streamDone.complete();
      },
    );
    if (onLevel != null) {
      // 現在音量（dBFS: -160〜0）を0〜1へ正規化して通知する。
      // 発話時のマイク入力はおおむね-45〜-10dBFSに収まるためこの範囲で線形化。
      _amplitudeSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen(
            (amp) => onLevel(((amp.current + 45) / 35).clamp(0.0, 1.0)),
          );
    }
    onPartial('聞き取り中…');
  }

  @override
  Future<String> stop() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _recorder.stop();
    // stop()完了後にストリームのonDoneイベントが届くまで短時間待つ
    // （マイクロタスクのスケジューリング差によるチャンク取りこぼしを防ぐ）。
    await _streamDone?.future.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {},
    );
    await _subscription?.cancel();
    _subscription = null;
    _streamDone = null;

    final pcmData = _bytesBuilder?.takeBytes();
    _bytesBuilder = null;
    if (pcmData == null || pcmData.isEmpty) {
      throw SpeechInputException('音声を聞き取れませんでした。もう一度お試しください。');
    }

    // 実際の録音フォーマットを16kHzモノラルに揃えてからWAVヘッダーを付ける。
    // 併せてデータ量も削減され、長い独り言でもリクエストサイズ上限に収まりやすくなる。
    final normalized = convertPcm16(
      pcmData,
      sourceSampleRate: _recordedSampleRate,
      sourceChannels: _recordedChannels,
      targetSampleRate: _sampleRate,
    );
    if (normalized.isEmpty) {
      throw SpeechInputException('音声を聞き取れませんでした。もう一度お試しください。');
    }

    final wavBytes = buildWavBytes(
      normalized,
      sampleRate: _sampleRate,
      channels: _channels,
    );
    return await _geminiService.transcribe(
      audioBytes: wavBytes,
      mimeType: 'audio/wav',
    );
  }

  @override
  void dispose() {
    unawaited(_amplitudeSub?.cancel());
    unawaited(_subscription?.cancel());
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
