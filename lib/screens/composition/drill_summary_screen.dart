import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/token_usage.dart';
import '../../services/drill_question_selector.dart';
import '../../services/gemini_pricing.dart';
import '../../services/sentence_repository.dart';
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

/// ドリル1問分のGemini API呼び出しで消費したトークン（用途別）。
class DrillQuestionUsage {
  const DrillQuestionUsage({
    this.transcription = TokenUsage.zero,
    this.correction = TokenUsage.zero,
  });

  /// 使用量ゼロ（手入力＋時間切れなど、API呼び出しが無かった問）
  static const zero = DrillQuestionUsage();

  /// 音声の文字起こし（録音し直した分も含む合計）
  final TokenUsage transcription;

  /// 添削
  final TokenUsage correction;

  /// 用途を問わない合計
  TokenUsage get total => transcription + correction;

  DrillQuestionUsage operator +(DrillQuestionUsage other) => DrillQuestionUsage(
    transcription: transcription + other.transcription,
    correction: correction + other.correction,
  );
}

/// ドリル1問分の結果概要（まとめ画面表示用）。
class DrillSummaryEntry {
  const DrillSummaryEntry({
    required this.ja,
    required this.score,
    this.usage = DrillQuestionUsage.zero,
  });

  /// 出題された日本語文
  final String ja;

  /// その問のスコア
  final int score;

  /// その問で消費したトークン
  final DrillQuestionUsage usage;
}

/// 口頭英作文ドリルのセッション終了後のまとめ画面。
///
/// 平均スコアと問題ごとの結果一覧、セッション全体のトークン使用量と
/// 概算コスト（USD）を表示し、「もう一度」で同条件の新しい10問へ、
/// 「終了」でデッキ選択画面へ戻る。
class DrillSummaryScreen extends StatelessWidget {
  const DrillSummaryScreen({
    super.key,
    required this.level,
    required this.theme,
    required this.entries,
    this.pricing,
  });

  /// TOEICレベル（「もう一度」の再出題に使用）
  final int level;

  /// 出題テーマ（「もう一度」の再出題に使用、nullなら全テーマ）
  final String? theme;

  /// 問題ごとの結果一覧
  final List<DrillSummaryEntry> entries;

  /// コスト計算に使う単価。省略時は今日の日付で[GeminiPricing.forDate]を使う
  /// （テストで固定するための注入口）。
  final GeminiPricing? pricing;

  DrillQuestionUsage get _totalUsage =>
      entries.fold(DrillQuestionUsage.zero, (sum, entry) => sum + entry.usage);

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
    final pricing = this.pricing ?? GeminiPricing.forDate(DateTime.now());
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
                  _UsageCard(usage: _totalUsage, pricing: pricing),
                  const SizedBox(height: 24),
                  for (var i = 0; i < entries.length; i++) ...[
                    AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${entries[i].ja}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (!entries[i].usage.total.isZero) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _usageLine(entries[i].usage, pricing),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
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

/// 1問分のトークン使用量とコストを1行にまとめる
/// （例: `入力 1,234 · 出力 56 · $0.0012`）。
String _usageLine(DrillQuestionUsage usage, GeminiPricing pricing) {
  final total = usage.total;
  return '入力 ${_formatTokens(total.promptTokens)} · '
      '出力 ${_formatTokens(total.billedOutputTokens)} · '
      '${formatUsd(pricing.costUsd(total))}';
}

final _tokenFormat = NumberFormat.decimalPattern('en_US');

String _formatTokens(int tokens) => _tokenFormat.format(tokens);

/// セッション全体のトークン使用量（用途別・合計）と概算コストのカード。
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage, required this.pricing});

  final DrillQuestionUsage usage;
  final GeminiPricing pricing;

  @override
  Widget build(BuildContext context) {
    final total = usage.total;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.token_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'APIトークン使用量',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UsageRow(
            label: '文字起こし',
            usage: usage.transcription,
            cost: pricing.costUsd(usage.transcription),
          ),
          const SizedBox(height: 6),
          _UsageRow(
            label: '添削',
            usage: usage.correction,
            cost: pricing.costUsd(usage.correction),
          ),
          const Divider(height: 20, color: AppColors.border),
          _UsageRow(
            label: '合計',
            usage: total,
            cost: pricing.costUsd(total),
            emphasize: true,
          ),
          if (total.thoughtsTokens > 0) ...[
            const SizedBox(height: 4),
            Text(
              '出力のうち思考トークン ${_formatTokens(total.thoughtsTokens)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '単価: ${pricing.rateDescription}（${pricing.label}）。'
            'Gemini APIの公開価格（Standardティア）から算出した概算で、無料枠は考慮していません。',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 用途ラベル／入力／出力／コストを横並びにした1行。
class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.usage,
    required this.cost,
    this.emphasize = false,
  });

  final String label;
  final TokenUsage usage;
  final double cost;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: AppColors.textPrimary,
    );
    final subStyle = TextStyle(
      fontSize: 13,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: AppColors.textSecondary,
    );
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label, style: style)),
        Expanded(
          child: Text(
            '入力 ${_formatTokens(usage.promptTokens)} · '
            '出力 ${_formatTokens(usage.billedOutputTokens)}',
            style: subStyle,
          ),
        ),
        Text(
          formatUsd(cost),
          style: style.copyWith(
            color: emphasize ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
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
