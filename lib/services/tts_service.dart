import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/learning_language.dart';

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
/// 実装は[FlutterTtsService]（端末OSのTTSエンジン）のみ。
/// UI側はこのインターフェースだけを見ればよい（テストではフェイクに差し替える）。
abstract class TtsService {
  /// [text]を読み上げる。読み上げが終わる（または中断される）まで待つ。
  ///
  /// すでに読み上げ中の場合は、それを止めてから新しい文を読み始める。
  /// 実際に音が鳴り始めた時点で[onSpeakingStarted]を呼ぶ。押してから音が出る
  /// までにはエンジンの準備時間があるので、UIはそれまでを「準備中」として
  /// 読み上げ中と出し分けられる（`SpeakButtonState`）。
  /// エンジンが使えない・読み上げに失敗した場合は[TtsException]を投げる。
  Future<void> speak(String text, {VoidCallback? onSpeakingStarted});

  /// 読み上げ中なら中断する。読み上げていない場合は何もしない。
  Future<void> stop();

  /// 内部リソースを解放する。画面破棄時に必ず呼ぶこと。
  void dispose();
}

/// 端末OSの音声合成エンジンを使う実装。
///
/// 言語は[LanguageProfile.ttsLanguage]（`en-US` / `zh-CN`）を設定する。
/// 音声をサーバーで生成しないので、APIコストも生成待ちも無く、押してから
/// 鳴り始めるまでが速い（生成待ちが長かったGemini TTSから戻した）。
///
/// `awaitSpeakCompletion(true)`により[speak]は読み上げ完了まで待つので、
/// 呼び出し側はそのまま「読み上げ中」の表示に使える。
class FlutterTtsService implements TtsService {
  // コンストラクタの公開パラメータ名（profile）と内部フィールド名（_profile）を
  // あえて分けているため、initializing formalは使わない
  // （使うとパラメータ名がprivateになり外部から渡せなくなる）。
  FlutterTtsService({
    required LanguageProfile profile,
    FlutterTts? tts,
    // ignore: prefer_initializing_formals
  }) : _profile = profile,
       _tts = tts ?? FlutterTts();

  final LanguageProfile _profile;
  final FlutterTts _tts;

  /// 言語・速度などの初期設定が済んでいるか（初回[speak]で一度だけ行う）
  bool _configured = false;

  /// 破棄済みかどうか。破棄後の[speak]は何もしない。
  bool _disposed = false;

  /// 再生中の[speak]を待たせているCompleter。
  ///
  /// 中断（[stop]）でエンジンが完了イベントを流さない場合があるため、
  /// [stop]側からもこれを完了させて[speak]の待ちを必ず解く
  /// （そうしないとボタンが「停止」表示のまま戻らなくなる）。
  Completer<void>? _playback;

  /// いま待っている[speak]に渡された「鳴り始めた」通知先
  VoidCallback? _onSpeakingStarted;

  @override
  Future<void> speak(String text, {VoidCallback? onSpeakingStarted}) async {
    if (_disposed || text.trim().isEmpty) return;
    await _configure();
    if (_disposed) return;
    // 直前の読み上げが残っていると重なって聞こえるため、必ず止めてから話す。
    await stop();
    final playback = Completer<void>();
    _playback = playback;
    _onSpeakingStarted = onSpeakingStarted;
    try {
      // speak()は読み上げ完了で返るが、中断時に返らない実装のプラットフォームが
      // あるため、[stop]が解くCompleterと競争させて待ちが残らないようにする。
      final speaking = _tts.speak(text);
      // 競争に負けた側の例外が未処理にならないように受けておく。
      unawaited(speaking.catchError((Object _) => null));
      await Future.any([speaking, playback.future]);
    } catch (_) {
      throw TtsException('読み上げできませんでした。端末の音声エンジンの設定を確認してください。');
    } finally {
      _finishPlayback();
    }
  }

  /// 再生の待ちを解き、通知先を捨てる。
  void _finishPlayback() {
    if (_playback?.isCompleted == false) _playback!.complete();
    _playback = null;
    _onSpeakingStarted = null;
  }

  @override
  Future<void> stop() async {
    if (_disposed || !_configured) return;
    try {
      await _tts.stop();
    } catch (_) {
      // 停止の失敗はユーザーに見せる必要がないため握りつぶす。
    }
    // 中断では完了イベントが流れないことがあるので、自分で待ちを解く。
    _finishPlayback();
  }

  @override
  void dispose() {
    _disposed = true;
    // 待っている[speak]を解いてから破棄する（解かないと永久に待ち続ける）。
    _finishPlayback();
    // 画面を離れた後も読み上げが続かないように止める。
    _tts.stop().catchError((Object _) => null);
  }

  /// 言語・速度・音量の設定を一度だけ行う。
  ///
  /// 学習言語のボイスが端末に入っていない場合は[TtsException]を投げ、
  /// 画面側で「この端末では読み上げできない」旨を出せるようにする。
  Future<void> _configure() async {
    if (_configured) return;
    final bool? available;
    try {
      available = await _tts.isLanguageAvailable(_profile.ttsLanguage);
    } catch (_) {
      throw TtsException('読み上げできませんでした。端末の音声エンジンの設定を確認してください。');
    }
    if (available == false) {
      throw TtsException('${_profile.label}の音声がこの端末にありません。端末の音声エンジンを確認してください。');
    }
    // 実際に音が鳴り始めた時点を拾って「準備中」→「読み上げ中」に切り替える。
    _tts.setStartHandler(() => _onSpeakingStarted?.call());
    // iOSは直前の録音でオーディオセッションが録音用のままになっていることが
    // あり、そのままでは読み上げが無音になる。再生用のカテゴリに切り替える。
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        const [],
      );
    }
    await _tts.setLanguage(_profile.ttsLanguage);
    // 学習用途では標準速度だと速いため、少しゆっくり読ませる。
    await _tts.setSpeechRate(_slowSpeechRate);
    await _tts.setVolume(1);
    await _tts.setPitch(1);
    // speak()が読み上げ完了まで待つようにする（UIの「読み上げ中」表示に使う）。
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }
}

/// 「標準よりやや遅い」読み上げ速度。
///
/// Android/iOSはプラグイン側で0.5が等速に揃えられているのに対し、
/// WebはWeb Speech APIの値がそのまま使われ1.0が等速なのでスケールが違う。
const double _slowSpeechRate = kIsWeb ? 0.9 : 0.45;
