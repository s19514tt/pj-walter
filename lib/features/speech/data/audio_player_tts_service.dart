// コンストラクタの公開パラメータ名と内部実装用のプライベートフィールド名を
// あえて分けているため、initializing formalは使わない
// （使うとパラメータ名がprivateになり外部から渡せなくなる）。
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/domain/token_usage.dart';
import '../../../core/language/learning_language.dart';
import '../domain/tts_repository.dart';
import '../domain/tts_service.dart';

/// [TtsRepository] で音声を生成し、`audioplayers` で再生する [TtsService]。
///
/// 端末のTTSエンジンに依存しないため、対応言語・声質がプラットフォームで
/// ぶれない（中国語の音声が入っていない端末でも読み上げられる）。
///
/// 音声出力は入力テキストより単価が高い（`GeminiPricing.tts`）ので、
/// 同じ文の2回目以降はメモリ上のキャッシュから再生してAPIを呼ばない。
/// 添削画面は「修正版」「模範解答」の2文だけを繰り返し読むため、
/// キャッシュ件数の上限は設けていない（画面を離れると破棄される）。
class AudioPlayerTtsService implements TtsService {
  AudioPlayerTtsService({
    required TtsRepository tts,
    required LanguageProfile profile,
    AudioPlayer? player,
  }) : _tts = tts,
       _profile = profile,
       _player = player ?? AudioPlayer();

  final TtsRepository _tts;
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
      final result = await _tts.synthesize(
        TtsRequest(learningLanguage: _profile.code, text: text),
      );
      wav = result.wavBytes;
      usage = result.usage;
      if (_disposed) return (usage: usage);
      _cache[text] = wav;
    }

    await _playAndWait(wav);
    return (usage: usage);
  }

  /// [wav]を再生し、再生完了または[stop]による中断まで待つ。
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
      throw const AppFailure(FailureKind.playback);
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
