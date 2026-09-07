import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/score_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../composition/domain/drill_result.dart';
import '../../monologue/domain/monologue_result.dart';
import 'stats_store.dart';

/// 口頭作文・独り言の履歴を新しい順に統合表示するセクション。
///
/// 直近[historyPageSize]件を表示し、「もっと見る」でさらに表示する。タップすると
/// 詳細をボトムシートで表示する。
class HistorySection extends StatelessWidget {
  const HistorySection({super.key, required this.store});

  final StatsStore store;

  void _showDetail(BuildContext context, HistoryEntry entry) {
    // showModalBottomSheetは新しいルートにbuilderの内容を差し込むため、
    // 必要なもの（Store）はウィジェットの引数として渡す。
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: (_) => switch (entry) {
        DrillHistoryEntry(:final result) => _DrillDetailSheet(
          result: result,
          source: store.drillSource(result),
        ),
        MonologueHistoryEntry(:final result) => _MonologueDetailSheet(
          result: result,
          source: store.topicSource(result),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SignalBuilder(
      builder: (context) {
        final shown = store.shownEntries.value;
        final remaining = store.remainingEntries.value;
        if (shown.isEmpty) {
          return AppCard(
            child: Text(
              l10n.noHistory,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return Column(
          children: [
            for (final entry in shown) ...[
              _HistoryTile(
                entry: entry,
                onTap: () => _showDetail(context, entry),
              ),
              const SizedBox(height: 8),
            ],
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SecondaryButton(
                  label: l10n.showMore(remaining),
                  onPressed: store.showMore,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final summary = switch (entry) {
      DrillHistoryEntry(:final result) => result.spoken,
      MonologueHistoryEntry(:final result) => result.transcript,
    };

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry is DrillHistoryEntry ? Icons.edit_note : Icons.mic_none,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateFormat.format(entry.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${entry.score}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scoreColor(entry.score),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 口頭作文の詳細（原文/発話/修正/解説）。
class _DrillDetailSheet extends StatelessWidget {
  const _DrillDetailSheet({required this.result, required this.source});

  final DrillResult result;

  /// 出題文（教材から解決。見つからなければ null）
  final Future<String?> source;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _DetailSheetScaffold(
      icon: Icons.edit_note,
      title: l10n.compositionGeneric,
      timestamp: result.timestamp,
      score: result.feedback.score,
      children: [
        _AsyncDetailField(
          label: l10n.sourceText,
          value: source,
          fallback: l10n.sentenceNotFound,
        ),
        const SizedBox(height: 12),
        _DetailField(label: l10n.yourSpeech, value: result.spoken),
        const SizedBox(height: 12),
        _DetailField(
          label: l10n.correctedVersion,
          value: result.feedback.corrected,
        ),
        const SizedBox(height: 12),
        _DetailField(
          label: l10n.explanation,
          value: result.feedback.explanation,
        ),
      ],
    );
  }
}

/// 独り言の詳細（お題/トランスクリプト/総評）。
class _MonologueDetailSheet extends StatelessWidget {
  const _MonologueDetailSheet({required this.result, required this.source});

  final MonologueResult result;

  /// お題（教材から解決。見つからなければ null）
  final Future<String?> source;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _DetailSheetScaffold(
      icon: Icons.mic_none,
      title: l10n.monologueGeneric,
      timestamp: result.timestamp,
      score: result.feedback.fluencyScore,
      children: [
        _AsyncDetailField(
          label: l10n.topicLabel,
          value: source,
          fallback: result.topicId,
        ),
        const SizedBox(height: 12),
        _DetailField(label: l10n.transcriptRaw, value: result.transcript),
        const SizedBox(height: 12),
        _DetailField(
          label: l10n.overallFeedback,
          value: result.feedback.overallFeedback,
        ),
      ],
    );
  }
}

/// 教材から非同期に解決する1項目（読み込み中は「読み込み中…」、無ければ[fallback]）。
class _AsyncDetailField extends StatelessWidget {
  const _AsyncDetailField({
    required this.label,
    required this.value,
    required this.fallback,
  });

  final String label;
  final Future<String?> value;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: value,
      builder: (context, snapshot) {
        final text =
            snapshot.data ??
            (snapshot.connectionState == ConnectionState.waiting
                ? context.l10n.loading
                : fallback);
        return _DetailField(label: label, value: text);
      },
    );
  }
}

class _DetailSheetScaffold extends StatelessWidget {
  const _DetailSheetScaffold({
    required this.icon,
    required this.title,
    required this.timestamp,
    required this.score,
    required this.children,
  });

  final IconData icon;
  final String title;
  final DateTime timestamp;
  final int score;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.scoreLabel(score),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scoreColor(score),
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
