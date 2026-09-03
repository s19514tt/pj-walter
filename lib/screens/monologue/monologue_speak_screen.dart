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
import '../../widgets/mic_button.dart';
import '../../widgets/primary_button.dart';
import '../settings_screen.dart';
import 'monologue_feedback_screen.dart';

/// カウントダウンリングの直径
const _ringSize = 180.0;

/// 残り時間がこの割合以下になったらリング・数値を警告色にする
const _urgentRatio = 0.2;

/// 独り言英会話のスピーキング画面。
///
/// お題を表示し、「話し始める」で[SpeechInputService]による音声入力と
/// カウントダウンを開始する。時間切れ、または「終了する」ボタンで音声入力を
/// 止め、得られた文字起こしを編集可能なTextFieldに表示する。
/// 「添削してもらう」でGeminiにフィードバックさせ、結果を保存したうえで
/// [MonologueFeedbackScreen]へ進む。
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
  final _transcriptController = TextEditingController();

  Timer? _timer;
  late int _secondsLeft;
  bool _recording = false;
  bool _processingSpeech = false;
  String _partialText = '';
  bool _grading = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.seconds;
    _speechInput =
        widget.speechInputService ??
        createSpeechInputService(geminiService: context.read<GeminiService>());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transcriptController.dispose();
    _speechInput.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _partialText = '');
    try {
      await _speechInput.start(
        onPartial: (text) => setState(() => _partialText = text),
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
        _stopRecording();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _timer?.cancel();
    setState(() {
      _recording = false;
      _processingSpeech = true;
    });
    try {
      final result = await _speechInput.stop();
      if (!mounted) return;
      setState(() {
        _transcriptController.text = result.text;
        _partialText = '';
      });
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
    if (!mounted || _grading) return;
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) return;

    final settings = context.read<SettingsService>();
    if (!settings.hasApiKey) {
      _showApiKeyDialog();
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
            Center(
              child: Column(
                children: [
                  MicButton(
                    recording: _recording,
                    processing: _processingSpeech,
                    onTap: _recording ? _stopRecording : _startRecording,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'タップして話す / もう一度タップで確定',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_recording || _partialText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _partialText.isEmpty ? '聞き取り中…' : _partialText,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _transcriptController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '発話の文字起こし',
                hintText: '音声認識結果が表示されます。直接編集もできます',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: '添削してもらう',
              onPressed: _submit,
              loading: _grading,
            ),
          ],
        ),
      ),
    );
  }
}
