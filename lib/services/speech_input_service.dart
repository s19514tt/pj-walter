import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../models/token_usage.dart';
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
/// 実装は[GeminiSpeechInputService]（録音→Gemini文字起こし）のみ。
/// 端末のOS標準音声認識（speech_to_text）はPR11で廃止した。
/// UI側はこのインターフェースだけを見ればよい（テストではフェイクに差し替える）。
abstract class SpeechInputService {
  /// 音声入力を開始する。
  ///
  /// [onPartial]は状態テキストが更新されるたびに呼ばれる（録音中である旨の
  /// 固定文言）。マイク権限拒否の場合は[SpeechInputException]を投げる。
  Future<void> start({required void Function(String text) onPartial});

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
/// `record`パッケージの`startStream`でPCM16(16kHz mono)チャンクをメモリ上の
/// [BytesBuilder]に蓄積し、[stop]でWAVヘッダー（[buildWavBytes]）を付けて
/// [GeminiService.transcribe]に送信する。ファイルI/Oを一切使わないため
/// Web/Android/iOS全てで同じコードパスが動く（`startStream`は全対応）。
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
  Completer<void>? _streamDone;

  @override
  Future<bool> get isAvailable => _recorder.hasPermission();

  @override
  Future<void> start({required void Function(String text) onPartial}) async {
    final granted = await _recorder.hasPermission();
    if (!granted) {
      throw SpeechInputException('マイクの権限が許可されていません。手入力してください。');
    }

    final bytesBuilder = BytesBuilder(copy: false);
    _bytesBuilder = bytesBuilder;
    final streamDone = Completer<void>();
    _streamDone = streamDone;

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
    onPartial('録音中…');
  }

  @override
  Future<SpeechInputResult> stop() async {
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
      throw SpeechInputException('録音データを取得できませんでした。手入力してください。');
    }

    final wavBytes = buildWavBytes(
      pcmData,
      sampleRate: _sampleRate,
      channels: _channels,
    );
    final (:text, :usage) = await _geminiService.transcribe(
      audioBytes: wavBytes,
      mimeType: 'audio/wav',
    );
    return SpeechInputResult(text: text, usage: usage);
  }

  @override
  void dispose() {
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
}) {
  return GeminiSpeechInputService(geminiService: geminiService);
}
