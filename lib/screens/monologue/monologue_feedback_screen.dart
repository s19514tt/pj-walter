import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/monologue_result.dart';
import '../../models/phrase.dart';
import '../../models/topic.dart';
import '../../services/gemini_service.dart';
import '../../services/history_service.dart';
import '../../services/speech_input_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/abort_session_dialog.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/skeleton.dart';

/// 独り言英会話のGeminiフィードバック画面（段階表示）。
///
/// 「フィードバックを見る」押下と同時にこの画面へ遷移し、3段階で埋める：
/// - stage 0: 全カードがスケルトン（[speechInput]の停止＝文字起こしを待つ）
/// - stage 1: 文字起こしカードだけ実テキスト。他はスケルトン＋バッジ
/// - stage 2: 全部表示。フッターの「完了」が出現
///
/// [result]を渡した場合は完成済みとして最初から全表示する。
/// [speechInput]を渡した場合はこの画面が停止→文字起こし→添削→保存まで
/// 進め、音声サービスの破棄もこの画面が責任を持つ。
/// フレーズは[HistoryService.addPhrase]でフレーズ帳に追加でき、追加済みの
/// ものは「保存済」表示に変わる。
class MonologueFeedbackScreen extends StatefulWidget {
  const MonologueFeedbackScreen({
    super.key,
    required this.topic,
    required this.seconds,
    this.result,
    this.speechInput,
  }) : assert(
         result != null || speechInput != null,
         'resultかspeechInputのどちらかが必要',
       );

  /// 出題されたお題（フレーズ追加時のsourceに使用）
  final Topic topic;

  /// 選択された発話時間（秒）
  final int seconds;

  /// 完成済みの独り言結果。渡された場合は段階表示せず最初から全表示する。
  final MonologueResult? result;

  /// 録音停止待ちの音声サービス（所有権ごと受け取る）。
  final SpeechInputService? speechInput;

  @override
  State<MonologueFeedbackScreen> createState() =>
      _MonologueFeedbackScreenState();
}

class _MonologueFeedbackScreenState extends State<MonologueFeedbackScreen> {
  final _addedPhraseIndices = <int>{};

  /// 文字起こし。nullは音声認識の完了待ち（stage 0）。
  String? _transcript;

  /// 添削済み結果。nullは添削待ち（stage 0〜1）。
  MonologueResult? _result;

  bool _grading = false;

  @override
  void initState() {
    super.initState();
    final result = widget.result;
    if (result != null) {
      _transcript = result.transcript;
      _result = result;
    } else {
      // SnackBar表示にScaffoldが必要なため初回フレーム後に開始する
      WidgetsBinding.instance.addPostFrameCallback((_) => _runPipeline());
    }
  }

  /// 録音停止（文字起こし）→添削→保存のパイプライン。
  Future<void> _runPipeline() async {
    final speech = widget.speechInput!;
    String transcript;
    try {
      transcript = (await speech.stop()).text;
    } on SpeechInputException catch (e) {
      _failAndExit(e.message);
      return;
    } on GeminiException catch (e) {
      _failAndExit(e.message);
      return;
    } finally {
      speech.dispose();
    }
    if (!mounted) return;
    if (transcript.trim().isEmpty) {
      _failAndExit('発話を聞き取れませんでした。もう一度話してください。');
      return;
    }
    // stage 1: 文字起こしだけ実テキストに
    setState(() => _transcript = transcript.trim());
    await _grade();
  }

  /// 添削（stage 1 → stage 2）。失敗時は再試行スナックバーを出して
  /// stage 1に留まる。
  Future<void> _grade() async {
    if (!mounted || _grading || _result != null) return;
    final transcript = _transcript;
    if (transcript == null) return;
    setState(() => _grading = true);
    final gemini = context.read<GeminiService>();
    final historyService = context.read<HistoryService>();
    try {
      // 独り言ではトークン使用量の表示はまだ行わない（口頭英作文のまとめ画面のみ）。
      final (:feedback, usage: _) = await gemini.reviewMonologue(
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
      await historyService.saveMonologueResult(result);
      if (!mounted) return;
      setState(() {
        _result = result;
        _grading = false;
      });
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => _grading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          action: SnackBarAction(label: '再試行', onPressed: _grade),
        ),
      );
    }
  }

  /// 文字起こし段階で失敗した場合: スナックバーを出して前の画面へ戻る。
  void _failAndExit(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<void> _addPhrase(int index) async {
    final result = _result;
    if (result == null) return;
    final phrase = result.feedback.usefulPhrases[index];
    await context.read<HistoryService>().addPhrase(
      Phrase(
        id: const Uuid().v4(),
        en: phrase.en,
        ja: phrase.ja,
        source: widget.topic.id,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => _addedPhraseIndices.add(index));
  }

  /// 添削完了前の戻る操作の誤操作防止（完了前に離脱すると結果は保存されない）。
  Future<void> _onPopRequested() async {
    final abort = await confirmAbortSession(context);
    if (abort && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final transcript = _transcript;
    final seconds = widget.seconds;
    final durationLabel = seconds < 60
        ? '$seconds秒'
        : '${seconds ~/ 60}分${seconds % 60 == 0 ? '' : '${seconds % 60}秒'}';
    return PopScope(
      // 添削完了後（保存済み）は自由に戻れる。完了前だけ確認を挟む
      canPop: result != null,
      onPopInvokedWithResult: (didPop, popResult) {
        if (didPop) return;
        _onPopRequested();
      },
      child: _buildScaffold(context, result, transcript, durationLabel),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    MonologueResult? result,
    String? transcript,
    String durationLabel,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('フィードバック')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 流暢さリング＋発話メトリクス（stage 2までスケルトン）
                  if (result == null)
                    const _ScoreSkeletonCard()
                  else
                    _ScoreMetricsCard(result: result),
                  const SizedBox(height: 14),
                  // 文字起こし: stage 0=スケルトン＋認識中 / stage 1=実テキスト
                  if (transcript == null)
                    const SkeletonSectionCard(title: '文字起こし', badge: '認識中')
                  else
                    _Section(
                      title: '文字起こし（$durationLabel）',
                      badge: result == null ? 'AI採点中' : null,
                      child: Text(
                        transcript,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.9,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  // 添削結果ブロック（stage 2までスケルトン）
                  if (result == null) ...[
                    const SkeletonSectionCard(title: '修正提案', badge: 'AI採点中'),
                    const SizedBox(height: 14),
                    const SkeletonSectionCard(title: '使えるフレーズ'),
                  ] else ...[
                    _Section(
                      title: '総評',
                      child: Text(
                        result.feedback.overallFeedbackJa,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Section(
                      title: '修正版',
                      child: Text(
                        result.feedback.correctedTranscript,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.8,
                          fontWeight: FontWeight.bold,
                          color: AppColors.scoreGood,
                        ),
                      ),
                    ),
                    if (result.feedback.corrections.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _Section(
                        title: '修正提案',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final correction
                                in result.feedback.corrections) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _CorrectionPill(
                                    text: correction.original,
                                    color: AppColors.scoreLow,
                                    surface: AppColors.scoreLowSurface,
                                    strikethrough: true,
                                  ),
                                  const Text(
                                    '→',
                                    style: TextStyle(color: Color(0xFF9AA0A6)),
                                  ),
                                  _CorrectionPill(
                                    text: correction.corrected,
                                    color: AppColors.scoreGood,
                                    surface: AppColors.scoreGoodSurface,
                                    bold: true,
                                  ),
                                ],
                              ),
                              if (correction.reasonJa.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  correction.reasonJa,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (result.feedback.usefulPhrases.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _Section(
                        title: '使えるフレーズ',
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < result.feedback.usefulPhrases.length;
                              i++
                            ) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFBFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result.feedback.usefulPhrases[i].en,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            result.feedback.usefulPhrases[i].ja,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              height: 1.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _SavePhraseButton(
                                      saved: _addedPhraseIndices.contains(i),
                                      onTap: () => _addPhrase(i),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < result.feedback.usefulPhrases.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            // フッターの「完了」は添削完了（stage 2）で出現する。
            // カードの段階表示とフッターのゲートは必ずセット。
            if (result != null)
              BottomCtaBar(
                child: PrimaryButton(
                  label: '完了',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 流暢さリング＋発話メトリクスのカード（stage 2）。
class _ScoreMetricsCard extends StatelessWidget {
  const _ScoreMetricsCard({required this.result});

  final MonologueResult result;

  @override
  Widget build(BuildContext context) {
    final feedback = result.feedback;
    final wordCount = result.transcript
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Column(
            children: [
              ScoreRing(score: feedback.fluencyScore, size: 104),
              const SizedBox(height: 4),
              const Text(
                '流暢さ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _MetricBar(
                  label: '発話量',
                  value: '$wordCount語',
                  progress: wordCount / 150,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _MetricBar(
                  label: '修正点',
                  value: '${feedback.corrections.length}件',
                  progress: feedback.corrections.length / 8,
                  color: AppColors.scoreMedium,
                ),
                const SizedBox(height: 8),
                _MetricBar(
                  label: 'フレーズ',
                  value: '${feedback.usefulPhrases.length}個',
                  progress: feedback.usefulPhrases.length / 5,
                  color: AppColors.scoreGood,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 流暢さカードのスケルトン（リング位置に円プレースホルダー＋バー3本）。
class _ScoreSkeletonCard extends StatelessWidget {
  const _ScoreSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDEEF1),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(child: SkeletonParagraph(widths: [1, 0.8, 0.9])),
        ],
      ),
    );
  }
}

/// ラベル＋値＋横バーのメトリクス行。
class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 5,
            backgroundColor: const Color(0xFFF0F1F3),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// 修正提案の取り消し線付き/太字ピル。
class _CorrectionPill extends StatelessWidget {
  const _CorrectionPill({
    required this.text,
    required this.color,
    required this.surface,
    this.strikethrough = false,
    this.bold = false,
  });

  final String text;
  final Color color;
  final Color surface;
  final bool strikethrough;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          decoration: strikethrough ? TextDecoration.lineThrough : null,
          decorationColor: color,
        ),
      ),
    );
  }
}

/// フレーズ保存ボタン（未保存=オレンジ枠ピル、保存済=グレー）。
class _SavePhraseButton extends StatelessWidget {
  const _SavePhraseButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: saved ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: saved ? const Color(0xFFF5F6F8) : AppColors.background,
          border: Border.all(
            color: saved ? const Color(0xFFE3E5E8) : AppColors.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          saved ? '保存済' : '＋保存',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: saved ? const Color(0xFF9AA0A6) : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// タイトル（12px bold グレー）＋任意の進行バッジ＋中身のカードセクション。
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.badge});

  final String title;
  final Widget child;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (badge != null) ProgressBadge(label: badge!),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
