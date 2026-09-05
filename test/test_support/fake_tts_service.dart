import 'dart:async';

import 'package:pj_walter/models/token_usage.dart';
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

  /// [speak]が返すトークン使用量（読み上げ1回分）
  TokenUsage usage = TokenUsage.zero;

  /// [speak]を完了させずに保留させるかどうか（読み上げ中の表示の検証用）。
  ///
  /// trueにすると[speak]は[completeSpeaking]が呼ばれるまで返らない。
  bool pending = false;

  Completer<void>? _pendingSpeak;

  @override
  Future<SpeakResult> speak(String text) async {
    spoken.add(text);
    final error = this.error;
    if (error != null) throw error;
    if (pending) {
      final completer = Completer<void>();
      _pendingSpeak = completer;
      await completer.future;
    }
    return (usage: usage);
  }

  /// 保留中の[speak]を完了させる。
  void completeSpeaking() {
    _pendingSpeak?.complete();
    _pendingSpeak = null;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _pendingSpeak?.complete();
    _pendingSpeak = null;
  }

  @override
  void dispose() => disposeCount++;
}
