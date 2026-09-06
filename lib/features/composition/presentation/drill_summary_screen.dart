import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/domain/gemini_pricing.dart';
import '../../../core/domain/token_usage.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/widgets/bottom_cta_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/score_square_badge.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../review/domain/srs_repository.dart';
import '../domain/drill_session.dart';
import 'drill_screen.dart';
import 'drill_summary_store.dart';

export '../domain/drill_session.dart';

/// 口頭作文ドリルのセッション終了後のまとめ画面。
///
/// 平均スコアと問題ごとの結果一覧、セッション全体のトークン使用量と
/// 概算コスト（USD）を表示し、「もう一度」で同条件の新しい10問へ、
/// 「ホームに戻る」でホームへ戻る。
class DrillSummaryScreen extends StatefulWidget {
  const DrillSummaryScreen({
    super.key,
    required this.level,
    required this.theme,
    required this.entries,
    this.pricing,
  });

  /// デッキレベル（「もう一度」の再出題に使用）
  final int level;

  /// 出題テーマ（「もう一度」の再出題に使用、nullなら全テーマ）
  final String? theme;

  /// 問題ごとの結果一覧
  final List<DrillSummaryEntry> entries;

  /// コスト計算に使う単価。省略時は今日の日付で[GeminiPricing.forDate]を使う
  /// （テストで固定するための注入口）。
  final GeminiPricing? pricing;

  @override
  State<DrillSummaryScreen> createState() => _DrillSummaryScreenState();
}

class _DrillSummaryScreenState extends State<DrillSummaryScreen> {
  late final DrillSummaryStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).drillSummary(
      level: widget.level,
      theme: widget.theme,
      entries: widget.entries,
      pricing: widget.pricing,
    );
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    final selected = await _store.retry();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      appRoute(
        builder: (_) => DrillScreen(
          sentences: selected,
          level: widget.level,
          theme: widget.theme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = _store.entries;
    final pricing = _store.pricing;
    final srsCount = _store.srsCount;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.summaryTitle)),
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
                        Text(
                          l10n.sessionComplete,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_store.averageScore}',
                          style: const TextStyle(
                            fontSize: 46,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.averageScoreLine(
                            _store.passingCount,
                            entries.length,
                          ),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entries[i].ja,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.6,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (!entries[i].usage.total.isZero)
                                        Text(
                                          l10n.usageLine(
                                            _formatTokens(
                                              entries[i]
                                                  .usage
                                                  .total
                                                  .promptTokens,
                                            ),
                                            _formatTokens(
                                              entries[i]
                                                  .usage
                                                  .total
                                                  .billedOutputTokens,
                                            ),
                                            formatUsd(
                                              entries[i].usage.costUsd(pricing),
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            height: 1.6,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _UsageCard(usage: _store.totalUsage, pricing: pricing),
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
                              l10n.srsRegisteredNote(passingScore, srsCount),
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
                      label: l10n.again,
                      onPressed: _retry,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: l10n.backToHome,
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

final _tokenFormat = NumberFormat.decimalPattern('en_US');

String _formatTokens(int tokens) => _tokenFormat.format(tokens);

/// セッション全体のトークン使用量（用途別・合計）と概算コストのカード。
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage, required this.pricing});

  final DrillQuestionUsage usage;
  final GeminiPricing pricing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = usage.total;
    String rate(GeminiPricing p) =>
        l10n.rateDescription(p.inputRateLabel, p.outputRateLabel);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.token_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.apiTokenUsage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _UsageRow(
            label: l10n.usageTranscription,
            usage: usage.transcription,
            cost: pricing.costUsd(usage.transcription),
          ),
          const SizedBox(height: 6),
          _UsageRow(
            label: l10n.usageCorrection,
            usage: usage.correction,
            cost: pricing.costUsd(usage.correction),
          ),
          // 読み上げはTTSモデル（単価が別）なので行を分ける
          if (usage.speech != TokenUsage.zero) ...[
            const SizedBox(height: 6),
            _UsageRow(
              label: l10n.usageSpeech,
              usage: usage.speech,
              cost: GeminiPricing.tts.costUsd(usage.speech),
            ),
          ],
          const Divider(height: 20, color: AppColors.border),
          _UsageRow(
            label: l10n.usageTotal,
            usage: total,
            cost: usage.costUsd(pricing),
            emphasize: true,
          ),
          if (total.thoughtsTokens > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.thoughtTokensNote(_formatTokens(total.thoughtsTokens)),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            l10n.pricingNote(
              rate(pricing),
              l10n.pricingTierLabel(pricing.tier.name),
              usage.speech != TokenUsage.zero
                  ? l10n.pricingSpeechNote(
                      l10n.pricingTierLabel(GeminiPricing.tts.tier.name),
                      rate(GeminiPricing.tts),
                    )
                  : '',
            ),
            style: const TextStyle(
              fontSize: 11,
              height: 1.6,
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
            context.l10n.tokensInOut(
              _formatTokens(usage.promptTokens),
              _formatTokens(usage.billedOutputTokens),
            ),
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
