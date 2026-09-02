import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/monologue_result.dart';
import '../../models/topic.dart';
import '../../services/gemini_service.dart';
import '../../services/history_service.dart';
import '../../services/settings_service.dart';
import '../../services/speech_input_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_route.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/primary_button.dart';
import '../settings_screen.dart';
import 'monologue_feedback_screen.dart';

/// 発話終了後の文字起こし待ち時間も見込んで、選択時間より長めに設定する
/// 音声認識の最大継続時間バッファ（device方式の[SpeechInputService.start]に渡す）。
const _listenBuffer = Duration(seconds: 30);

/// 長時間発話中に許容する無音の最大長（device方式）。短いと発話の合間で
/// 認識が打ち切られてしまうため、口頭英作文より長めに設定する。
const _pauseFor = Duration(seconds: 15);

/// カウントダウンリングの直径
const _ringSize = 180.0;

/// 残り時間がこの割合以下になったらリング・数値を警告色にする
const _urgentRatio = 0.2;

/// 独り言英会話のスピーキング画面。
///
/// お題表示と同時に[SpeechInputService]による音声入力とカウントダウンを
/// 自動で開始する。画面の要素はお題・残り時間・「添削してもらう」ボタン
/// 1つだけで、録音停止＝添削：ボタン一押し（または時間切れ）で聞き取り終了→
/// 文字起こし→Geminiフィードバックまで一気に行い、結果を保存したうえで
/// [MonologueFeedbackScreen]へ進む。編集用の入力欄は無い。
/// 聞き取りに失敗した場合のみ「録り直す」導線を出す。
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

  /// テスト注入用。省略時は設定に応じたインスタンスを自動生成する。
  final SpeechInputService? speechInputService;

  @override
  State<MonologueSpeakScreen> createState() => _MonologueSpeakScreenState();
}

class _MonologueSpeakScreenState extends State<MonologueSpeakScreen> {
  late final SpeechInputService _speechInput;

  Timer? _timer;
  late int _secondsLeft;
  bool _recording = false;
  bool _processingSpeech = false;

  /// 録音停止時に確定した文字起こし。停止＝添削に直結するため編集UIは持たない。
  String _transcript = '';
  bool _grading = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.seconds;
    _speechInput =
        widget.speechInputService ??
        createSpeechInputService(
          settingsService: context.read<SettingsService>(),
          geminiService: context.read<GeminiService>(),
        );
    // お題表示と同時に音声入力とカウントダウンを自動開始する。
    // SnackBar表示にScaffoldが必要なため初回フレーム後に行う。
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRecording());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechInput.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!mounted || _recording) return;
    // 録り直し＝新しいテイクなので、前回の文字起こしはクリアする。
    setState(() => _transcript = '');
    try {
      // 部分認識テキストは表示しない（画面はお題・残り時間・停止ボタンのみ）
      await _speechInput.start(
        onPartial: (_) {},
        listenFor: Duration(seconds: widget.seconds) + _listenBuffer,
        pauseFor: _pauseFor,
      );
      setState(() {
        _recording = true;
        _secondsLeft = widget.seconds;
      });
      _startCountdown();
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

  /// 時間切れ処理。
  ///
  /// ボタン操作なしでも必ず聞き取り終了（文字起こし）まで行い、そのまま
  /// 添削へ進む。「添削してもらう」押下による処理が既に走っている場合は
  /// そちらに任せる（二重停止・二重添削を防ぐ）。
  Future<void> _handleTimeUp() async {
    if (_grading || _processingSpeech) return;
    await _stopRecording();
    if (!mounted) return;
    await _submit();
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _timer?.cancel();
    setState(() {
      _recording = false;
      _processingSpeech = true;
    });
    try {
      final text = await _speechInput.stop();
      if (!mounted) return;
      setState(() => _transcript = text);
    } on SpeechInputException catch (e) {
      _showSnack(e.message);
    } on GeminiException catch (e) {
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _processingSpeech = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    // SnackBarの「再試行」から画面破棄後・添削中に呼ばれる可能性があるためガード
    if (!mounted || _grading || _processingSpeech) return;

    final settings = context.read<SettingsService>();
    if (!settings.hasApiKey) {
      // 録音は止めずにダイアログを出す（キー設定後にそのまま続行できる）
      _showApiKeyDialog();
      return;
    }

    // 録音中なら「添削してもらう」一押しで聞き取り終了→文字起こしまで行い、
    // そのまま添削に進む。
    if (_recording) {
      await _stopRecording();
      if (!mounted) return;
    }

    final transcript = _transcript.trim();
    if (transcript.isEmpty) {
      _showSnack('発話を聞き取れませんでした。「録り直す」からもう一度話してください。');
      return;
    }

    setState(() => _grading = true);
    final gemini = context.read<GeminiService>();
    try {
      final feedback = await gemini.reviewMonologue(
        topicJa: widget.topic.ja,
        topicEn: widget.topic.en,
        seconds: widget.seconds,
        transcript: transcript,
      );
      final result = MonologueResult(
        id: const Uuid().v4(),
        topicId: widget.topic.id,
        seconds: widget.seconds,
        transcript: transcript,
        timestamp: DateTime.now(),
        feedback: feedback,
      );
      if (!mounted) return;
      await context.read<HistoryService>().saveMonologueResult(result);
      if (!mounted) return;
      setState(() => _grading = false);
      Navigator.of(context).pushReplacement(
        appRoute(
          builder: (_) =>
              MonologueFeedbackScreen(topic: widget.topic, result: result),
        ),
      );
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => _grading = false);
      _showRetrySnack(e.message);
    }
  }

  void _showRetrySnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: '再試行', onPressed: _submit),
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
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.seconds == 0 ? 0.0 : _secondsLeft / widget.seconds;
    final urgent = ratio <= _urgentRatio;
    final ringColor = urgent ? AppColors.scoreLow : AppColors.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('独り言英会話')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.topic.ja,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.topic.en,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: _ringSize,
                height: _ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 1, end: ratio),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.linear,
                      builder: (context, value, child) {
                        return SizedBox(
                          width: _ringSize,
                          height: _ringSize,
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(begin: ringColor, end: ringColor),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, color, child) =>
                                CircularProgressIndicator(
                                  value: value.clamp(0, 1),
                                  strokeWidth: 8,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation(
                                    color ?? ringColor,
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                    Text(
                      _formatTime(_secondsLeft),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: urgent
                            ? AppColors.scoreLow
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 操作ボタンは下部の「添削してもらう」1つだけ（録音停止＝添削）。
            // ここは録音状態の表示のみ：録音中はインジケーター、文字起こし中は
            // スピナー、失敗して録音が止まっている時だけ録り直しの導線を出す。
            Center(
              child: _processingSpeech
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                  : _recording
                  ? const RecordingIndicator()
                  : TextButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.mic),
                      label: const Text('録り直す'),
                    ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              // 録音中は「停止＝添削」であることをラベルでも明示する
              label: _recording ? '停止して添削' : '添削してもらう',
              onPressed: _submit,
              // 文字起こし（_processingSpeech）→添削（_grading）まで一続きの
              // 処理として、ボタンはその間ずっとローディング表示にする。
              loading: _grading || _processingSpeech,
            ),
          ],
        ),
      ),
    );
  }
}
