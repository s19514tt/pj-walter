import 'package:flutter/material.dart';

import '../../models/pronunciation_feedback.dart';
import '../../theme/app_theme.dart';
import '../../utils/score_colors.dart';
import '../../widgets/app_card.dart';

/// 口頭英作文の発音評価カード。
///
/// 見出し行（マイクアイコン＋「発音」＋総合スコアのピル）、単語ごとの
/// スコア色付きチップ、指摘のある単語の一覧、アドバイスを縦に並べる。
/// [feedback]がnull（手入力回答・評価失敗）なら何も描画しない。
class PronunciationCard extends StatelessWidget {
  const PronunciationCard({super.key, required this.feedback});

  final PronunciationFeedback? feedback;

  @override
  Widget build(BuildContext context) {
    final feedback = this.feedback;
    if (feedback == null) return const SizedBox.shrink();
    final problems = feedback.problemWords;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '発音',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _ScorePill(score: feedback.score),
            ],
          ),
          if (feedback.words.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final word in feedback.words) _WordChip(word: word),
              ],
            ),
          ],
          if (problems.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final word in problems)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: scoreColor(word.score),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        word.issueJa,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (feedback.adviceJa.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🗣️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback.adviceJa,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 総合スコアのピル（薄色背景＋濃色数字）。
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scoreSurfaceColor(score),
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: scoreColor(score),
        ),
      ),
    );
  }
}

/// 単語チップ。スコアに応じた薄色背景＋濃色文字で、指摘がある語は下線付き。
class _WordChip extends StatelessWidget {
  const _WordChip({required this.word});

  final WordPronunciation word;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(word.score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scoreSurfaceColor(word.score),
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        word.word,
        style: TextStyle(
          fontSize: 13,
          fontWeight: word.hasIssue ? FontWeight.bold : FontWeight.normal,
          color: color,
          decoration: word.hasIssue ? TextDecoration.underline : null,
          decorationColor: color,
        ),
      ),
    );
  }
}
