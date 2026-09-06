import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/learning_language.dart';
import 'settings_service.dart';

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
/// 実装は[CloudTtsService]（Google Cloud Text-to-Speech）のみ。
/// UI側はこのインターフェースだけを見ればよい（テストではフェイクに差し替える）。
abstract class TtsService {
  /// [text]を読み上げる。読み上げが終わる（または中断される）まで待つ。
  ///
  /// すでに読み上げ中の場合は、それを止めてから新しい文を読み始める。
  /// 実際に音が鳴り始めた時点で[onSpeakingStarted]を呼ぶ。押してから音が出る
  /// までには音声の生成と取得の時間があるので、UIはそれまでを「生成中」として
  /// 読み上げ中と出し分けられる（`SpeakButtonState`）。
  /// 生成・再生に失敗した場合は[TtsException]を投げる。
  Future<void> speak(String text, {VoidCallback? onSpeakingStarted});

  /// 読み上げ中なら中断する。読み上げていない場合は何もしない。
  Future<void> stop();

  /// 内部リソースを解放する。画面破棄時に必ず呼ぶこと。
  void dispose();
}

/// Google Cloud Text-to-Speech で音声を生成し、端末で再生する実装。
///
/// Gemini TTS（`gemini-3.1-flash-tts-preview`）から乗り換えた理由は速度。
/// Gemini TTS はLLMが音声トークンを生成するため押してから鳴るまでが長い。
/// Cloud TTS は専用の合成エンジンで、WaveNet 音声なら短文で 300ms 前後
/// （計測値は DESIGN.md「読み上げ（TTS）」の表を参照）。
///
/// 音声は[LanguageProfile.ttsVoiceName]（WaveNet）で固定する。Neural2 の方が
/// 速いが**中国語（cmn-CN）の音声が存在しない**ため、このアプリでは使えない。
///
/// 課金は文字数（$16 / 100万文字、月100万文字まで無料）。同じ文の2回目以降は
/// メモリ上のキャッシュから再生してAPIを呼ばない。添削画面は「修正版」
/// 「模範解答」の2文だけを繰り返し読むため、キャッシュ件数の上限は設けて
/// いない（画面を離れると破棄される）。
class CloudTtsService implements TtsService {
  // コンストラクタの公開パラメータ名（settingsService/profile）と内部
  // フィールド名をあえて分けているため、initializing formalは使わない
  // （使うとパラメータ名がprivateになり外部から渡せなくなる）。
  CloudTtsService({
    required SettingsService settingsService,
    required LanguageProfile profile,
    http.Client? client,
    AudioPlayer? player,
    // ignore: prefer_initializing_formals
  }) : _settings = settingsService,
       // ignore: prefer_initializing_formals
       _profile = profile,
       _client = client ?? http.Client(),
       _injectedPlayer = player;

  static const _endpoint =
      'https://texttospeech.googleapis.com/v1/text:synthesize';
  static const _timeout = Duration(seconds: 15);

  /// 読み上げ速度（1.0が等速）。学習用途では等速だと速いので少し落とす。
  /// Cloud TTS が受け付ける範囲は 0.25〜4.0。
  static const speakingRate = 0.85;

  /// 音声フォーマット。MP3はWAVより転送量が小さく、鳴り始めるまでが速い。
  static const audioEncoding = 'MP3';

  final SettingsService _settings;
  final LanguageProfile _profile;
  final http.Client _client;

  /// コンストラクタで渡されたプレイヤー（テスト用。省略時はnull）
  final AudioPlayer? _injectedPlayer;
  AudioPlayer? _lazyPlayer;

  /// 再生に使うプレイヤー。生成がプラットフォームチャンネルに触るため、
  /// 実際に鳴らすときまで作らない（音声合成だけを試すテストでは作られない）。
  AudioPlayer get _player => _injectedPlayer ?? (_lazyPlayer ??= AudioPlayer());

  /// 生成済みの音声（キーは読み上げた文）
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
  Future<void> speak(String text, {VoidCallback? onSpeakingStarted}) async {
    if (_disposed || text.trim().isEmpty) return;

    var audio = _cache[text];
    if (audio == null) {
      audio = await synthesize(text);
      if (_disposed) return;
      _cache[text] = audio;
    }

    await _playAndWait(audio, onSpeakingStarted);
  }

  /// [text]をCloud TTSで合成し、再生できる音声バイト列（MP3）を返す。
  @visibleForTesting
  Future<Uint8List> synthesize(String text) async {
    final apiKey = _requireApiKey();
    final body = jsonEncode({
      'input': {'text': text},
      'voice': {
        'languageCode': _profile.ttsLanguageCode,
        'name': _profile.ttsVoiceName,
      },
      'audioConfig': {
        'audioEncoding': audioEncoding,
        'speakingRate': speakingRate,
      },
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: body,
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw TtsException('読み上げの生成がタイムアウトしました。電波状況を確認して再度お試しください。');
    } catch (_) {
      throw TtsException('読み上げの生成に失敗しました。ネットワーク接続を確認してください。');
    }
    _checkStatus(response);

    final String? audioContent;
    try {
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      audioContent = decoded['audioContent'] as String?;
    } catch (_) {
      throw TtsException('読み上げ音声を取得できませんでした。時間を置いて再度お試しください。');
    }
    if (audioContent == null || audioContent.isEmpty) {
      throw TtsException('読み上げ音声を取得できませんでした。時間を置いて再度お試しください。');
    }
    return base64Decode(audioContent);
  }

  /// [audio]を再生し、再生完了または[stop]による中断まで待つ。
  ///
  /// 呼び出し側はこの待ちをそのまま「読み上げ中」の表示に使える。
  Future<void> _playAndWait(
    Uint8List audio,
    VoidCallback? onSpeakingStarted,
  ) async {
    // 直前の読み上げが残っていると重なって聞こえるため、必ず止めてから鳴らす。
    await stop();
    final playback = Completer<void>();
    _playback = playback;
    try {
      _completeSubscription = _player.onPlayerComplete.listen((_) {
        if (!playback.isCompleted) playback.complete();
      });
      await _player.play(BytesSource(audio, mimeType: 'audio/mpeg'));
    } catch (_) {
      _finishPlayback();
      throw TtsException('音声を再生できませんでした。端末の音量・サイレントモードを確認してください。');
    }
    // play()が返った時点で音が出ている。ここで「生成中」→「読み上げ中」。
    onSpeakingStarted?.call();
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
      // 一度も鳴らしていなければプレイヤーは存在しないので、作らずに済ませる。
      if (_injectedPlayer != null || _lazyPlayer != null) await _player.stop();
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
    // 画面を離れた後も再生が続かないように破棄する（未生成なら何もしない）。
    final player = _injectedPlayer ?? _lazyPlayer;
    if (player != null) unawaited(player.dispose());
  }

  /// 読み上げに使うAPIキー。Cloud TTS 用が未設定ならGeminiのキーを使う
  /// （同じGoogle Cloudプロジェクトのキーなら1つで足りるため）。
  String _requireApiKey() {
    final apiKey = _settings.ttsApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw TtsException('APIキーが設定されていません。設定画面からAPIキーを登録してください。');
    }
    return apiKey;
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode == 200) return;
    switch (response.statusCode) {
      case 401:
      case 403:
        // Cloud TTS はGeminiと別のAPIなので、キーが有効でも
        // 「APIが有効化されていない」だけで403が返る。両方を案内する。
        throw TtsException(
          '読み上げのAPIキーが使えません。Google Cloud で Cloud Text-to-Speech API '
          'を有効化し、そのプロジェクトのAPIキーを設定画面に登録してください。',
        );
      case 429:
        throw TtsException('読み上げのリクエストが多すぎます。しばらく待ってから再度お試しください。');
      case 400:
        throw TtsException('読み上げのリクエストが不正です。時間を置いて再度お試しください。');
      default:
        if (response.statusCode >= 500) {
          throw TtsException('読み上げサーバーでエラーが発生しました。しばらくしてから再度お試しください。');
        }
        throw TtsException('読み上げに失敗しました（エラーコード: ${response.statusCode}）。');
    }
  }
}
