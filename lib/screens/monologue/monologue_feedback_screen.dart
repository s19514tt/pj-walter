import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/monologue_result.dart';
import '../../models/phrase.dart';
import '../../models/topic.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/score_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/stat_badge.dart';

/// 独り言英会話1回分のGeminiフィードバック表示画面。
///
/// 流暢さスコア・総評・修正版全文・個別修正点・使えるフレーズを表示する。
/// フレーズは[HistoryService.addPhrase]でフレーズ帳に追加でき、追加済みの
/// ものはチェック表示に変わる。「終了」でお題選択画面（[MonologueSpeakScreen]の
/// 呼び出し元）まで戻る。
class MonologueFeedbackScreen extends StatefulWidget {
  const MonologueFeedbackScreen({
    super.key,
    required this.topic,
    required this.result,
  });

  /// 出題されたお題（フレーズ追加時のsourceに使用）
  final Topic topic;

  /// 保存済みの独り言結果（トランスクリプト＋フィードバック）
  final MonologueResult result;

  @override
  State<MonologueFeedbackScreen> createState() =>
      _MonologueFeedbackScreenState();
}

class _MonologueFeedbackScreenState extends State<MonologueFeedbackScreen> {
  final _addedPhraseIndices = <int>{};

  Future<void> _addPhrase(int index) async {
    final phrase = widget.result.feedback.usefulPhrases[index];
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

  @override
  Widget build(BuildContext context) {
    final feedback = widget.result.feedback;
    final color = scoreColor(feedback.fluencyScore);
    return Scaffold(
      appBar: AppBar(title: const Text('フィードバック')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        ScoreRing(score: feedback.fluencyScore),
                        const SizedBox(height: 12),
                        StatBadge(
                          label: feedback.fluencyScore >= 70 ? '合格 🎉' : '要復習',
                          surfaceColor: feedback.fluencyScore >= 70
                              ? AppColors.scoreGoodSurface
                              : AppColors.scoreMediumSurface,
                          textColor: color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Section(
                    icon: Icons.summarize_outlined,
                    title: '総評',
                    content: feedback.overallFeedbackJa,
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    icon: Icons.edit,
                    title: '修正版',
                    content: feedback.correctedTranscript,
                    highlight: true,
                  ),
                  if (feedback.corrections.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _SubHeader(title: '個別の修正点'),
                    const SizedBox(height: 8),
                    for (final correction in feedback.corrections) ...[
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              correction.original,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              correction.corrected,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              correction.reasonJa,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  if (feedback.usefulPhrases.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const _SubHeader(title: '使えるフレーズ'),
                    const SizedBox(height: 8),
                    for (var i = 0; i < feedback.usefulPhrases.length; i++) ...[
                      AppCard(
                        color: AppColors.primarySurface,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feedback.usefulPhrases[i].en,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    feedback.usefulPhrases[i].ja,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _addedPhraseIndices.contains(i)
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '追加済み',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : TextButton(
                                    onPressed: () => _addPhrase(i),
                                    child: const Text('＋追加'),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
            BottomCtaBar(
              child: SecondaryButton(
                label: '終了',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.content,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String content;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: highlight ? AppColors.primarySurface : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: highlight ? 17 : 15,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
