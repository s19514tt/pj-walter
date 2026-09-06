import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pj_walter/services/tts_service.dart';

/// 読み上げの呼び出しを記録するだけの[TtsService]。
///
/// 実際のTTSエンジン（プラットフォームチャンネル）を叩かずに、
/// 「どの文が読み上げられたか」「停止されたか」をテストから検証できる。
class FakeTtsService implements TtsService {
  /// [speak]に渡された文を呼ばれた順に記録する
  final spoken = <String>[];

  /// [stop]が呼ばれた回数
  int stopCount = 0;

  /// [dispose]が呼ばれた回数
  int disposeCount = 0;

  /// [speak]で投げる例外。nullなら正常に完了する。
  TtsException? error;

  /// [speak]を完了させずに保留させるかどうか（読み上げ中の表示の検証用）。
  ///
  /// trueにすると[speak]は[completeSpeaking]が呼ばれるまで返らない。
  bool pending = false;

  /// [speak]の直後に「鳴り始めた」通知を出すかどうか。
  ///
  /// falseにすると通知は[startSpeaking]を呼ぶまで出ないので、
  /// 「準備中」表示のまま止められる。
  bool startImmediately = true;

  Completer<void>? _pendingSpeak;
  VoidCallback? _onSpeakingStarted;

  @override
  Future<void> speak(String text, {VoidCallback? onSpeakingStarted}) async {
    spoken.add(text);
    final error = this.error;
    if (error != null) throw error;
    _onSpeakingStarted = onSpeakingStarted;
    if (startImmediately) startSpeaking();
    if (pending) {
      final completer = Completer<void>();
      _pendingSpeak = completer;
      await completer.future;
    }
  }

  /// 保留中の[speak]に「鳴り始めた」通知を出す。
  void startSpeaking() {
    _onSpeakingStarted?.call();
    _onSpeakingStarted = null;
  }

  /// 保留中の[speak]を完了させる。
  void completeSpeaking() {
    _pendingSpeak?.complete();
    _pendingSpeak = null;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _onSpeakingStarted = null;
    _pendingSpeak?.complete();
    _pendingSpeak = null;
  }

  @override
  void dispose() => disposeCount++;
}
