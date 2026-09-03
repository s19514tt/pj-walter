import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/drill_question_selector.dart';
import '../../services/sentence_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_route.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/score_square_badge.dart';
import '../../widgets/secondary_button.dart';
import 'drill_screen.dart';

/// 合格とみなすスコアのしきい値
const _passingScore = 70;

/// ドリル1問分の結果概要（まとめ画面表示用）。
class DrillSummaryEntry {
  const DrillSummaryEntry({required this.ja, required this.score});

  /// 出題された日本語文
  final String ja;

  /// その問のスコア
  final int score;
}

/// 口頭英作文ドリルのセッション終了後のまとめ画面。
///
/// 平均スコアと問題ごとの結果一覧を表示し、「もう一度」で同条件の
/// 新しい10問へ、「終了」でデッキ選択画面へ戻る。
class DrillSummaryScreen extends StatelessWidget {
  const DrillSummaryScreen({
    super.key,
    required this.level,
    required this.theme,
    required this.entries,
  });

  /// TOEICレベル（「もう一度」の再出題に使用）
  final int level;

  /// 出題テーマ（「もう一度」の再出題に使用、nullなら全テーマ）
  final String? theme;

  /// 問題ごとの結果一覧
  final List<DrillSummaryEntry> entries;

  double get _averageScore {
    if (entries.isEmpty) return 0;
    final total = entries.map((e) => e.score).reduce((a, b) => a + b);
    return total / entries.length;
  }

  int get _passingCount =>
      entries.where((e) => e.score >= _passingScore).length;

  Future<void> _retry(BuildContext context) async {
    final repository = context.read<SentenceRepository>();
    final sentences = await repository.sentencesFor(level: level, theme: theme);
    const selector = DrillQuestionSelector();
    final selected = selector.select(sentences);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      appRoute(
        builder: (_) =>
            DrillScreen(sentences: selected, level: level, theme: theme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final average = _averageScore.round();
    final srsCount = entries.where((e) => e.score < _passingScore).length;
    return Scaffold(
      appBar: AppBar(title: const Text('結果まとめ')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // セッション完了ヒーロー（平均スコア・正答数）
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'セッション完了',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$average',
                          style: const TextStyle(
                            fontSize: 46,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '平均スコア · 正答 $_passingCount/${entries.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 問題ごとの結果一覧（1枚のカードに区切り線で連結）
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < entries.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: i == entries.length - 1
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFF3F4F6),
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                ScoreSquareBadge(score: entries[i].score),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entries[i].ja,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (srsCount > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            size: 22,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'スコア$_passingScore未満の$srsCount問を復習キューに登録しました。明日再出題されます。',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.7,
                                color: Color(0xFFB34000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            BottomCtaBar(
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'もう一度',
                      onPressed: () => _retry(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'ホームに戻る',
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
