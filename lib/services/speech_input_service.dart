import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../models/learning_language.dart';
import '../models/token_usage.dart';
import '../utils/pcm_converter.dart';
import '../utils/wav_builder.dart';
import 'gemini_service.dart';

/// [SpeechInputService.stop]の結果（文字起こしテキスト＋トークン使用量）。
@immutable
class SpeechInputResult {
  const SpeechInputResult({required this.text, required this.usage});

  /// 文字起こしテキスト
  final String text;

  /// 文字起こしに使ったトークン数（料金表示用）
  final TokenUsage usage;
}

/// 音声入力（マイク権限・録音）に失敗した際に投げられる例外。
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
/// 実装は[GeminiSpeechInputService]（録音→Gemini文字起こし）のみ。
/// 端末のOS標準音声認識（speech_to_text）はPR17で廃止した。
/// UI側はこのインターフェースだけを見ればよい（テストではフェイクに差し替える）。
abstract class SpeechInputService {
  /// 音声入力を開始する。
  ///
  /// [onPartial]は状態テキストが更新されるたびに呼ばれる（録音中である旨の
  /// 固定文言）。マイク権限拒否の場合は[SpeechInputException]を投げる。
  ///
  /// [onLevel]は録音中の入力音量（0.0〜1.0に正規化）が更新されるたびに
  /// 呼ばれる。UI側で音量メーター表示に使う。プラットフォームが音量を
  /// 提供しない場合は呼ばれないことがある。
  Future<void> start({
    required void Function(String text) onPartial,
    void Function(double level)? onLevel,
  });

  /// 音声入力を終了し、文字起こしテキストとトークン使用量を返す。
  ///
  /// ここで録音データをGeminiに送信して文字起こしする
  /// （[GeminiException]が投げられる場合がある）。
  Future<SpeechInputResult> stop();

  /// このデバイスで音声入力が利用可能かどうか。
  Future<bool> get isAvailable;

  /// 内部リソースを解放する。画面破棄時に必ず呼ぶこと。
  void dispose();
}

/// 録音してGeminiに文字起こしさせる実装。
///
/// `record`パッケージの`startStream`でPCM16チャンクをメモリ上の
/// [BytesBuilder]に蓄積し、[stop]で16kHzモノラルに揃えて（[convertPcm16]）
/// WAVヘッダー（[buildWavBytes]）を付けて[GeminiService.transcribe]に送信する。
/// ファイルI/Oを一切使わないためWeb/Android/iOS全てで同じコードパスが動く
/// （`startStream`は全対応）。
class GeminiSpeechInputService implements SpeechInputService {
  // コンストラクタの公開パラメータ名（geminiService）と内部フィールド名
  // （_geminiService）をあえて分けているため、initializing formalは使わない
  // （使うとパラメータ名がprivateになり外部から渡せなくなる）。
  GeminiSpeechInputService({
    required GeminiService geminiService,
    required LanguageProfile profile,
    AudioRecorder? recorder,
    // ignore: prefer_initializing_formals
  }) : _geminiService = geminiService,
       // ignore: prefer_initializing_formals
       _profile = profile,
       _recorder = recorder ?? AudioRecorder();

  static const _sampleRate = 16000;
  static const _channels = 1;

  final GeminiService _geminiService;
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
    required void Function(String text) onPartial,
    void Function(double level)? onLevel,
  }) async {
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
          .listen((amp) => onLevel(((amp.current + 45) / 35).clamp(0.0, 1.0)));
    }
    onPartial('聞き取り中…');
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
    final (:text, :usage) = await _geminiService.transcribe(
      profile: _profile,
      audioBytes: wavBytes,
      mimeType: 'audio/wav',
    );
    return SpeechInputResult(text: text, usage: usage);
  }

  @override
  void dispose() {
    unawaited(_amplitudeSub?.cancel());
    unawaited(_subscription?.cancel());
    unawaited(_recorder.dispose());
  }
}

/// 本番用の[SpeechInputService]を組み立てる。
///
/// 現在はGemini録音方式のみのため常に[GeminiSpeechInputService]を返す。
/// 画面側はこの関数だけを呼び、実装クラスに直接依存しない。
SpeechInputService createSpeechInputService({
  required GeminiService geminiService,
  required LanguageProfile profile,
}) {
  return GeminiSpeechInputService(
    geminiService: geminiService,
    profile: profile,
  );
}
