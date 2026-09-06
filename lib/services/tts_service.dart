import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../core/language/learning_language.dart';
import '../core/domain/token_usage.dart';
import 'gemini_service.dart';

/// [TtsService.speak]の結果（読み上げに消費したトークン使用量）。
///
/// 同じ文をキャッシュから再生した場合は[TokenUsage.zero]（API呼び出し無し）。
typedef SpeakResult = ({TokenUsage usage});

/// 読み上げ（TTS）に失敗した際に投げられる例外。
///
/// [message]はUIにそのまま表示できる日本語文言。
class TtsException implements Exception {
  TtsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 学習言語の文を読み上げる音声合成の抽象化。
///
/// 実装は[GeminiTtsService]（Gemini TTSで音声を生成して端末で再生）のみ。
/// UI側はこのインターフェースだけを見ればよい（テストではフェイクに差し替える）。
abstract class TtsService {
  /// [text]を読み上げる。再生が終わる（または中断される）まで待つ。
  ///
  /// すでに読み上げ中の場合は、それを止めてから新しい文を読み始める。
  /// 音声の生成・再生に失敗した場合は[TtsException]を投げる。
  Future<SpeakResult> speak(String text);

  /// 読み上げ中なら中断する。読み上げていない場合は何もしない。
  Future<void> stop();

  /// 内部リソースを解放する。画面破棄時に必ず呼ぶこと。
  void dispose();
}

/// Gemini TTSで音声を生成し、端末で再生する実装。
///
/// [GeminiService.synthesizeSpeech]が返すWAVを`audioplayers`で鳴らす。
/// 端末のTTSエンジンに依存しないため、対応言語・声質がプラットフォームで
/// ぶれない（中国語の音声が入っていない端末でも読み上げられる）。
///
/// 音声出力は入力テキストより単価が高い（[GeminiPricing.tts]）ので、
/// 同じ文の2回目以降はメモリ上のキャッシュから再生してAPIを呼ばない。
/// 添削画面は「修正版」「模範解答」の2文だけを繰り返し読むため、
/// キャッシュ件数の上限は設けていない（画面を離れると破棄される）。
class GeminiTtsService implements TtsService {
  // コンストラクタの公開パラメータ名（geminiService/profile）と内部フィールド名
  // をあえて分けているため、initializing formalは使わない
  // （使うとパラメータ名がprivateになり外部から渡せなくなる）。
  GeminiTtsService({
    required GeminiService geminiService,
    required LanguageProfile profile,
    AudioPlayer? player,
    // ignore: prefer_initializing_formals
  }) : _gemini = geminiService,
       // ignore: prefer_initializing_formals
       _profile = profile,
       _player = player ?? AudioPlayer();

  final GeminiService _gemini;
  final LanguageProfile _profile;
  final AudioPlayer _player;

  /// 生成済みのWAV（キーは読み上げた文）
  final _cache = <String, Uint8List>{};

  /// 再生中の[speak]を待たせているCompleter。
  ///
  /// `audioplayers`は`stop()`では`onPlayerComplete`を流さないため、
  /// 「再生完了」と「[stop]による中断」の両方でこれを完了させて
  /// [speak]の待ちを解く（そうしないと停止後に永久に待ち続ける）。
  Completer<void>? _playback;
  StreamSubscription<void>? _completeSubscription;

  /// 破棄済みかどうか。破棄後の[speak]は何もしない。
  bool _disposed = false;

  @override
  Future<SpeakResult> speak(String text) async {
    if (_disposed || text.trim().isEmpty) return (usage: TokenUsage.zero);

    var usage = TokenUsage.zero;
    var wav = _cache[text];
    if (wav == null) {
      try {
        final result = await _gemini.synthesizeSpeech(
          profile: _profile,
          text: text,
        );
        wav = result.wavBytes;
        usage = result.usage;
      } on GeminiException catch (error) {
        // GeminiExceptionのmessageはそのままUIに出せる日本語なので流用する。
        throw TtsException(error.message);
      }
      if (_disposed) return (usage: usage);
      _cache[text] = wav;
    }

    await _playAndWait(wav);
    return (usage: usage);
  }

  /// [wav]を再生し、再生完了または[stop]による中断まで待つ。
  ///
  /// 呼び出し側はこの待ちをそのまま「読み上げ中」の表示に使える。
  Future<void> _playAndWait(Uint8List wav) async {
    // 直前の読み上げが残っていると重なって聞こえるため、必ず止めてから鳴らす。
    await stop();
    final playback = Completer<void>();
    _playback = playback;
    try {
      _completeSubscription = _player.onPlayerComplete.listen((_) {
        if (!playback.isCompleted) playback.complete();
      });
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (_) {
      _finishPlayback();
      throw TtsException('音声を再生できませんでした。端末の音量・サイレントモードを確認してください。');
    }
    await playback.future;
    _finishPlayback();
  }

  /// 再生の待ちを解き、完了通知の購読を解除する。
  void _finishPlayback() {
    if (_playback?.isCompleted == false) _playback!.complete();
    _playback = null;
    unawaited(_completeSubscription?.cancel());
    _completeSubscription = null;
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // 停止の失敗はユーザーに見せる必要がないため握りつぶす。
    }
    // stop()ではonPlayerCompleteが流れないので、待っている[speak]を自分で解く。
    _finishPlayback();
  }

  @override
  void dispose() {
    _disposed = true;
    _cache.clear();
    // 待っている[speak]を解いてから破棄する（解かないと永久に待ち続ける）。
    _finishPlayback();
    // 画面を離れた後も再生が続かないように破棄する。
    unawaited(_player.dispose());
  }
}
