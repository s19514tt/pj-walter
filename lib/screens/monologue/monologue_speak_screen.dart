import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/content/domain/topic.dart';
import '../../services/gemini_service.dart';
import '../../services/settings_service.dart';
import '../../services/speech_input_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_route.dart';
import '../../core/widgets/abort_session_dialog.dart';
import '../../core/widgets/bottom_cta_bar.dart';
import '../../core/widgets/countdown_ring.dart';
import '../../core/widgets/primary_button.dart';
import '../settings_screen.dart';
import 'monologue_feedback_screen.dart';

/// 残り時間がこの割合以下になったらリング・数値を警告色にする
const _urgentRatio = 0.2;

/// 独り言英会話のスピーキング画面。
///
/// カウントダウンは画面表示と同時に開始する（お題を読む時間もカウントに
/// 含まれる。rec移行時にリセットしない）。録音は「話しはじめる」ボタンが
/// 押されるまで始めない（pre）。録音中（rec）は「フィードバックを見る」
/// 一押し（または時間切れ）で、段階表示のフィードバック画面へ即遷移し、
/// 文字起こし→添削の進行に合わせてコンテンツが埋まっていく。
class MonologueSpeakScreen extends StatefulWidget {
  const MonologueSpeakScreen({
    super.key,
    required this.topic,
    required this.seconds,
    this.speechInputService,
  });

  /// 出題されたお題
  final Topic topic;

  /// 選択された発話時間（秒）
  final int seconds;

  /// テスト注入用。省略時は本番用のインスタンスを自動生成する。
  final SpeechInputService? speechInputService;

  @override
  State<MonologueSpeakScreen> createState() => _MonologueSpeakScreenState();
}

class _MonologueSpeakScreenState extends State<MonologueSpeakScreen> {
  late final SpeechInputService _speechInput;

  Timer? _timer;
  late int _secondsLeft;
  bool _recording = false;

  /// フィードバック画面へ音声サービスの所有権を渡したかどうか。
  /// 渡した後はこの画面のdisposeで音声サービスを破棄しない。
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.seconds;
    _speechInput =
        widget.speechInputService ??
        createSpeechInputService(
          geminiService: context.read<GeminiService>(),
          profile: context.read<SettingsService>().languageProfile,
        );
    // カウントダウンは画面表示と同時に開始する（読む時間もカウントに含まれる）。
    // 録音は「話しはじめる」ボタンが押されるまで始めない。
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_handedOff) _speechInput.dispose();
    super.dispose();
  }

  /// 「話しはじめる」: 録音を開始する。カウントダウンはすでに動いているので
  /// 触らない（recに入った時点でリセットしてはいけない）。
  Future<void> _startRecording() async {
    if (!mounted || _recording || _secondsLeft <= 0) return;
    try {
      // 部分認識テキストは表示しない（画面はお題・残り時間・主ボタンのみ）
      await _speechInput.start(onPartial: (_) {});
      setState(() => _recording = true);
    } on SpeechInputException catch (e) {
      _showSnack(e.message);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        _handleTimeUp();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  /// 時間切れ処理。録音中なら「フィードバックを見る」を押したのと同じ
  /// （段階表示のフィードバックへ）。preのままなら仕切り直し。
  Future<void> _handleTimeUp() async {
    if (_handedOff) return;
    if (_recording) {
      await _submit();
      return;
    }
    _showSnack('時間切れになりました。「話しはじめる」で開始してください。');
    setState(() => _secondsLeft = widget.seconds);
    _startCountdown();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 「フィードバックを見る」: 段階表示のフィードバック画面へ即遷移する。
  /// 録音停止（文字起こし）と添削はフィードバック画面側が進め、
  /// 完了に応じてスケルトンが実データへ置き換わる。
  Future<void> _submit() async {
    if (!mounted || !_recording || _handedOff) return;

    final settings = context.read<SettingsService>();
    if (!settings.hasApiKey) {
      // 録音は止めずにダイアログを出す（キー設定後にそのまま続行できる）
      _showApiKeyDialog();
      return;
    }

    _timer?.cancel();
    // 音声サービスの所有権ごとフィードバック画面へ渡す（stop→disposeは向こうで行う）
    _handedOff = true;
    Navigator.of(context).pushReplacement(
      appRoute(
        builder: (_) => MonologueFeedbackScreen(
          topic: widget.topic,
          seconds: widget.seconds,
          speechInput: _speechInput,
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('APIキーが未設定です'),
        content: const Text('Gemini APIキーが設定されていません。設定画面から登録してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(
                context,
              ).push(appRoute(builder: (_) => const SettingsScreen()));
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final sec = seconds % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  /// 戻る操作（AppBarの戻る・システムバック）の誤操作防止。
  /// 確認ダイアログで「中断する」を選んだときだけ画面を閉じる。
  Future<void> _onPopRequested() async {
    final abort = await confirmAbortSession(context);
    if (abort && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onPopRequested();
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final ratio = widget.seconds == 0 ? 0.0 : _secondsLeft / widget.seconds;
    // pre（録音前）かどうか。円環・ゲージだけ色を落とす（お題カードは常時アクティブ）
    final pre = !_recording;
    final urgent = !pre && ratio <= _urgentRatio;
    return Scaffold(
      appBar: AppBar(title: const Text('独り言英会話')),
      body: SafeArea(
        child: Column(
          children: [
            // 画面上端の残り時間ゲージ（6px）。pre=#C9CCD1 / rec=オレンジ、残りわずかで赤
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: ratio),
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  pre
                      ? const Color(0xFFC9CCD1)
                      : urgent
                      ? AppColors.scoreLow
                      : AppColors.primary,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'このお題について話す',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.topic.ja,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 19,
                              height: 1.7,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.topic.target,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: CountdownRing(
                          progress: ratio,
                          label: _formatTime(_secondsLeft),
                          recording: _recording,
                          idleLabel: '聞き取り前',
                          dimmed: pre,
                          urgent: urgent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BottomCtaBar(
              child: PrimaryButton(
                // pre=話しはじめる（録音開始）/ rec=フィードバックを見る（停止＝添削）。
                // 「録音する」という語は使わない。
                label: _recording ? 'フィードバックを見る' : '話しはじめる',
                onPressed: _recording ? _submit : _startRecording,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
