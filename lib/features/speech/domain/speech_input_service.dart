import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/token_usage.dart';

part 'speech_input_service.freezed.dart';

/// [SpeechInputService.stop]の結果（文字起こしテキスト＋トークン使用量）。
@freezed
abstract class SpeechInputResult with _$SpeechInputResult {
  const factory SpeechInputResult({
    /// 文字起こしテキスト
    required String text,

    /// 文字起こしに使ったトークン数（料金表示用）
    required TokenUsage usage,

    /// 聞こえたままの声調付きピンイン（中国語のみ。英語では null）。
    /// [TranscriptionResult.reading]をそのまま透過する。
    String? reading,
  }) = _SpeechInputResult;
}

/// 音声入力（マイク録音→文字起こし）の抽象化。
///
/// 実装は `RecorderSpeechInputService`（録音→[TranscriptionRepository]）のみ。
/// UI側はこのインターフェースだけを見ればよい（テストではフェイクに差し替える）。
/// 失敗は [AppFailure]（[FailureKind.micPermission] / [FailureKind.noSpeech] 等）。
abstract interface class SpeechInputService {
  /// 音声入力を開始する。
  ///
  /// [onPartial]は状態テキストの更新通知（録音中である旨の固定文言のキー）。
  /// [onLevel]は録音中の入力音量（0.0〜1.0に正規化）が更新されるたびに
  /// 呼ばれる。プラットフォームが音量を提供しない場合は呼ばれないことがある。
  Future<void> start({
    void Function(String text)? onPartial,
    void Function(double level)? onLevel,
  });

  /// 音声入力を終了し、文字起こしテキストとトークン使用量を返す。
  Future<SpeechInputResult> stop();

  /// 録音を中止し、溜めた音声を破棄する（文字起こしはしない）。
  ///
  /// 「わからないので飛ばす」のように、録音中でも結果が要らないと決まった
  /// ときに使う。[stop]と違い文字起こしを呼ばないのでトークンを消費しない。
  Future<void> cancel();

  /// このデバイスで音声入力が利用可能かどうか。
  Future<bool> get isAvailable;

  /// 内部リソースを解放する。所有者（Store）の破棄時に必ず呼ぶこと。
  void dispose();
}
