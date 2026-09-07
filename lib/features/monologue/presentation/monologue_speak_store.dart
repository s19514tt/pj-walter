import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/domain/app_failure.dart';
import '../../../core/language/learning_language.dart';
import '../../../core/state/store.dart';
import '../../content/domain/topic.dart';
import '../../settings/domain/settings_repository.dart';
import '../../speech/domain/speech_input_service.dart';

/// スピーキング画面が反応する一回きりの出来事。
sealed class MonologueSpeakNotice {
  const MonologueSpeakNotice();
}

/// 録音開始の失敗など
class MonologueSpeakFailureNotice extends MonologueSpeakNotice {
  const MonologueSpeakFailureNotice(this.failure);

  final AppFailure failure;
}

/// pre のまま時間切れになった（仕切り直しを案内する）
class MonologueTimeUpNotice extends MonologueSpeakNotice {
  const MonologueTimeUpNotice();
}

/// API キーが未設定
class MonologueApiKeyMissingNotice extends MonologueSpeakNotice {
  const MonologueApiKeyMissingNotice();
}

/// 録音サービスの所有権ごとフィードバック画面へ渡す。
///
/// 画面はこれを受けてフィードバック画面へ遷移する（停止→文字起こし→添削は向こうで行う）。
class MonologueHandOffNotice extends MonologueSpeakNotice {
  const MonologueHandOffNotice(this.speechInput);

  final SpeechInputService speechInput;
}

/// 独り言のスピーキング画面の Store。
///
/// カウントダウンは画面表示と同時に開始する（お題を読む時間もカウントに
/// 含まれる。rec移行時にリセットしない）。録音は「話しはじめる」が
/// 押されるまで始めない（pre）。録音中（rec）は「フィードバックを見る」
/// 一押し（または時間切れ）で、録音サービスごとフィードバック画面へ渡す。
class MonologueSpeakStore extends Store {
  MonologueSpeakStore({
    required this.topic,
    required this.seconds,
    required this._speechInput,
    required SettingsRepository settings,
  }) : _settings = settings,
       profile = settings.settings.peek().languageProfile {
    secondsLeft = createSignal(seconds);
    recording = createSignal(false);
    notice = createSignal(null);
    ratio = createComputed(
      () => seconds == 0 ? 0.0 : secondsLeft.value / seconds,
    );
    urgent = createComputed(
      () => recording.value && ratio.value <= urgentRatio,
    );
    addDisposer(() {
      _timer?.cancel();
      // 所有権を渡した後はフィードバック画面側が破棄する
      if (!_handedOff) _speechInput.dispose();
    });
    _startCountdown();
  }

  /// 残り時間がこの割合以下になったらリング・数値を警告色にする
  static const urgentRatio = 0.2;

  final Topic topic;
  final int seconds;
  final LanguageProfile profile;
  final SpeechInputService _speechInput;
  final SettingsRepository _settings;

  late final Signal<int> secondsLeft;
  late final Signal<bool> recording;
  late final Signal<MonologueSpeakNotice?> notice;
  late final Computed<double> ratio;
  late final Computed<bool> urgent;

  Timer? _timer;
  bool _handedOff = false;

  /// 「話しはじめる」: 録音を開始する。カウントダウンはすでに動いているので触らない。
  Future<void> startRecording() async {
    if (disposed || recording.value || secondsLeft.value <= 0) return;
    try {
      await _speechInput.start();
      if (disposed) return;
      recording.value = true;
    } on AppFailure catch (e) {
      notice.value = MonologueSpeakFailureNotice(e);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (disposed) {
        timer.cancel();
        return;
      }
      if (secondsLeft.value <= 1) {
        timer.cancel();
        secondsLeft.value = 0;
        _handleTimeUp();
        return;
      }
      secondsLeft.value--;
    });
  }

  /// 時間切れ処理。録音中なら「フィードバックを見る」を押したのと同じ。
  /// preのままなら仕切り直し。
  void _handleTimeUp() {
    if (_handedOff) return;
    if (recording.value) {
      submit();
      return;
    }
    notice.value = const MonologueTimeUpNotice();
    secondsLeft.value = seconds;
    _startCountdown();
  }

  /// 「フィードバックを見る」: 録音サービスの所有権ごとフィードバック画面へ渡す。
  void submit() {
    if (disposed || !recording.value || _handedOff) return;
    if ((_settings.apiKey.peek() ?? '').isEmpty) {
      // 録音は止めずにダイアログを出す（キー設定後にそのまま続行できる）
      notice.value = const MonologueApiKeyMissingNotice();
      return;
    }
    _timer?.cancel();
    _handedOff = true;
    notice.value = MonologueHandOffNotice(_speechInput);
  }
}
