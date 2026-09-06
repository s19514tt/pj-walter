import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/domain/token_usage.dart';
import '../../features/composition/domain/drill_question_selector.dart';
import '../../core/domain/gemini_pricing.dart';
import '../../features/content/domain/content_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_route.dart';
import '../../core/widgets/bottom_cta_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/score_square_badge.dart';
import '../../core/widgets/secondary_button.dart';
import 'drill_screen.dart';
import '../../services/settings_service.dart';

/// 合格とみなすスコアのしきい値
const _passingScore = 70;

/// ドリル1問分のGemini API呼び出しで消費したトークン（用途別）。
class DrillQuestionUsage {
  const DrillQuestionUsage({
    this.transcription = TokenUsage.zero,
    this.correction = TokenUsage.zero,
    this.speech = TokenUsage.zero,
  });

  /// 使用量ゼロ（時間切れなど、API呼び出しが無かった問）
  static const zero = DrillQuestionUsage();

  /// 音声の文字起こし（やり直した分も含む合計）
  final TokenUsage transcription;

  /// 添削
  final TokenUsage correction;

  /// 添削結果の読み上げ（TTSモデル。単価が別なので分けて持つ）
  final TokenUsage speech;

  /// 用途を問わない合計
  TokenUsage get total => transcription + correction + speech;

  /// [textPricing]（文字起こし・添削）と[GeminiPricing.tts]（読み上げ）を
  /// 用途ごとに使い分けた概算コスト（USD）。
  ///
  /// 読み上げは別モデル・別単価なので、合計トークンに単価を1つ掛けると
  /// 実際の請求とずれる。必ず用途ごとに計算して足し合わせる。
  double costUsd(GeminiPricing textPricing) =>
      textPricing.costUsd(transcription) +
      textPricing.costUsd(correction) +
      GeminiPricing.tts.costUsd(speech);

  DrillQuestionUsage operator +(DrillQuestionUsage other) => DrillQuestionUsage(
    transcription: transcription + other.transcription,
    correction: correction + other.correction,
    speech: speech + other.speech,
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
/// 「ホームに戻る」でホームへ戻る。
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
    final repository = context.read<ContentRepository>();
    final sentences = await repository.sentences(
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
    final srsCount = entries.where((e) => e.score < _passingScore).length;
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
                                          _usageLine(entries[i].usage, pricing),
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
                  _UsageCard(usage: _totalUsage, pricing: pricing),
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

/// 1問分のトークン使用量とコストを1行にまとめる
/// （例: `入力 1,234 · 出力 56 · $0.0012`）。
String _usageLine(DrillQuestionUsage usage, GeminiPricing pricing) {
  final total = usage.total;
  return '入力 ${_formatTokens(total.promptTokens)} · '
      '出力 ${_formatTokens(total.billedOutputTokens)} · '
      '${formatUsd(usage.costUsd(pricing))}';
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
          // 読み上げはTTSモデル（単価が別）なので行を分ける
          if (usage.speech != TokenUsage.zero) ...[
            const SizedBox(height: 6),
            _UsageRow(
              label: '読み上げ',
              usage: usage.speech,
              cost: GeminiPricing.tts.costUsd(usage.speech),
            ),
          ],
          const Divider(height: 20, color: AppColors.border),
          _UsageRow(
            label: '合計',
            usage: total,
            cost: usage.costUsd(pricing),
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
            '${usage.speech != TokenUsage.zero ? '読み上げは${GeminiPricing.tts.label}の${GeminiPricing.tts.rateDescription}。' : ''}'
            'Gemini APIの公開価格（Standardティア）から算出した概算で、無料枠は考慮していません。',
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
