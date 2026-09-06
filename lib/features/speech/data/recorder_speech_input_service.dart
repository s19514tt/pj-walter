import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/language/learning_language.dart';
import '../../../core/utils/pcm_converter.dart';
import '../../../core/utils/wav_builder.dart';
import '../domain/speech_input_service.dart';
import '../domain/transcription_repository.dart';

/// 録音して [TranscriptionRepository] に文字起こしさせる [SpeechInputService]。
///
/// `record`パッケージの`startStream`でPCM16チャンクをメモリ上の
/// [BytesBuilder]に蓄積し、[stop]で16kHzモノラルに揃えて（[convertPcm16]）
/// WAVヘッダー（[buildWavBytes]）を付けて文字起こしに送る。
/// ファイルI/Oを一切使わないためWeb/Android/iOS全てで同じコードパスが動く。
class RecorderSpeechInputService implements SpeechInputService {
  RecorderSpeechInputService({
    required this._transcription,
    required this._profile,
    AudioRecorder? recorder,
  }) : _recorder = recorder ?? AudioRecorder();

  static const _sampleRate = 16000;
  static const _channels = 1;

  final TranscriptionRepository _transcription;
  final LanguageProfile _profile;
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
    void Function(String text)? onPartial,
    void Function(double level)? onLevel,
  }) async {
    final granted = await _recorder.hasPermission();
    if (!granted) throw const AppFailure(FailureKind.micPermission);

    final bytesBuilder = BytesBuilder(copy: false);
    _bytesBuilder = bytesBuilder;
    final streamDone = Completer<void>();
    _streamDone = streamDone;

    // 16kHz/monoを要求してもハードウェア・ブラウザ都合で書き換えられることがある
    // （Chromeは`AudioContext`の実サンプルレート48kHzが採用され、Androidは入力
    // デバイスに合わせてステレオになりうる）。PCMの生バイト列からは実フォーマットを
    // 判別できず、そのまま16kHz/monoのWAVヘッダーを付けると再生速度・音程がずれて
    // 意味不明な文字起こしが返るため、実フォーマットを受け取って[stop]で変換する。
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
          .listen((amp) => onLevel(((amp.current + 45) / 35).clamp(0.0, 1.0)));
    }
    onPartial?.call('listening');
  }

  @override
  Future<SpeechInputResult> stop() async {
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
      throw const AppFailure(FailureKind.noSpeech);
    }

    // 実際の録音フォーマットを16kHzモノラルに揃えてからWAVヘッダーを付ける。
    // 併せてデータ量も削減され、長い独り言でもリクエストサイズ上限に収まりやすくなる。
    final normalized = convertPcm16(
      pcmData,
      sourceSampleRate: _recordedSampleRate,
      sourceChannels: _recordedChannels,
      targetSampleRate: _sampleRate,
    );
    if (normalized.isEmpty) throw const AppFailure(FailureKind.noSpeech);

    final wavBytes = buildWavBytes(
      normalized,
      sampleRate: _sampleRate,
      channels: _channels,
    );
    final result = await _transcription.transcribe(
      TranscriptionRequest(
        learningLanguage: _profile.code,
        audioBytes: wavBytes,
        mimeType: 'audio/wav',
      ),
    );
    return SpeechInputResult(
      text: result.text,
      reading: result.reading,
      usage: result.usage,
    );
  }

  @override
  Future<void> cancel() async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    await _recorder.stop();
    await _subscription?.cancel();
    _subscription = null;
    _streamDone = null;
    // 溜めたPCMは文字起こしせずに捨てる
    _bytesBuilder = null;
  }

  @override
  void dispose() {
    unawaited(_amplitudeSub?.cancel());
    unawaited(_subscription?.cancel());
    unawaited(_recorder.dispose());
  }
}
