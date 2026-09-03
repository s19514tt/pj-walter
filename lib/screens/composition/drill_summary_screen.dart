import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/drill_question_selector.dart';
import '../../services/sentence_repository.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_route.dart';
import '../../utils/score_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/bottom_cta_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/stat_badge.dart';
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
    final sentences = await repository.sentencesFor(
      profile: context.read<SettingsService>().languageProfile,
      level: level,
      theme: theme,
    );
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
    return Scaffold(
      appBar: AppBar(title: const Text('結果まとめ')),
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
                        const Text(
                          '平均スコア',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        ScoreRing(score: average),
                        const SizedBox(height: 12),
                        StatBadge(
                          label: '合格$_passingCount問/全${entries.length}問',
                          surfaceColor: _passingCount == entries.length
                              ? AppColors.scoreGoodSurface
                              : AppColors.scoreMediumSurface,
                          textColor: _passingCount == entries.length
                              ? AppColors.scoreGood
                              : AppColors.scoreMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < entries.length; i++) ...[
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i + 1}. ${entries[i].ja}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _ScoreBadge(score: entries[i].score),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            BottomCtaBar(
              secondary: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('終了'),
              ),
              child: PrimaryButton(
                label: 'もう一度',
                onPressed: () => _retry(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// スコアを丸バッジ（36px円、白数字）で表示する。
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scoreColor(score),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$score',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
