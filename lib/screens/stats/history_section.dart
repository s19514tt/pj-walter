import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/drill_result.dart';
import '../../models/monologue_result.dart';
import '../../models/sentence.dart';
import '../../models/topic.dart';
import '../../services/sentence_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/score_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/secondary_button.dart';

const _pageSize = 20;

/// 口頭英作文・独り言英会話の履歴を新しい順に統合表示するセクション。
///
/// 直近[_pageSize]件を表示し、「もっと見る」でさらに表示する。タップすると
/// 詳細をボトムシートで表示する。
class HistorySection extends StatefulWidget {
  const HistorySection({
    super.key,
    required this.drillHistory,
    required this.monologueHistory,
  });

  final List<DrillResult> drillHistory;
  final List<MonologueResult> monologueHistory;

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  int _limit = _pageSize;

  List<_HistoryEntry> get _entries {
    final entries = <_HistoryEntry>[
      for (final result in widget.drillHistory) _HistoryEntry.drill(result),
      for (final result in widget.monologueHistory)
        _HistoryEntry.monologue(result),
    ];
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  void _showDetail(_HistoryEntry entry) {
    // showModalBottomSheetは新しいルート（Overlayの兄弟エントリ）にbuilderの
    // 内容を差し込むため、その中のcontextからは呼び出し元のProviderを辿れない。
    // そのため、ルートがまだ辿れるここでSentenceRepositoryを読んでおき、
    // ウィジェットの引数として渡す。
    final repository = context.read<SentenceRepository>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.cardRadius),
        ),
      ),
      builder: (_) => entry.drill != null
          ? _DrillDetailSheet(result: entry.drill!, repository: repository)
          : _MonologueDetailSheet(
              result: entry.monologue!,
              repository: repository,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    if (entries.isEmpty) {
      return const AppCard(
        child: Text(
          'まだ添削履歴がありません',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final shown = entries.take(_limit).toList();
    final remaining = entries.length - shown.length;

    return Column(
      children: [
        for (final entry in shown) ...[
          _HistoryTile(entry: entry, onTap: () => _showDetail(entry)),
          const SizedBox(height: 8),
        ],
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SecondaryButton(
              label: 'もっと見る（残り$remaining件）',
              onPressed: () => setState(() => _limit += _pageSize),
            ),
          ),
      ],
    );
  }
}

/// 口頭英作文・独り言英会話のいずれか一方を保持する履歴エントリ。
class _HistoryEntry {
  _HistoryEntry.drill(DrillResult result)
    : drill = result,
      monologue = null,
      timestamp = result.timestamp;

  _HistoryEntry.monologue(MonologueResult result)
    : drill = null,
      monologue = result,
      timestamp = result.timestamp;

  final DrillResult? drill;
  final MonologueResult? monologue;
  final DateTime timestamp;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});

  final _HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final isDrill = entry.drill != null;
    final score = isDrill
        ? entry.drill!.feedback.score
        : entry.monologue!.feedback.fluencyScore;
    final summary = isDrill ? entry.drill!.spoken : entry.monologue!.transcript;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDrill ? Icons.edit_note : Icons.mic_none,
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
                      '$score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scoreColor(score),
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

/// 口頭英作文の詳細（原文/発話/修正/解説）。
class _DrillDetailSheet extends StatelessWidget {
  const _DrillDetailSheet({required this.result, required this.repository});

  final DrillResult result;
  final SentenceRepository repository;

  @override
  Widget build(BuildContext context) {
    return _DetailSheetScaffold(
      icon: Icons.edit_note,
      title: '口頭英作文',
      timestamp: result.timestamp,
      score: result.feedback.score,
      children: [
        FutureBuilder<List<Sentence>>(
          future: repository.sentencesFor(level: result.level),
          builder: (context, snapshot) {
            final match = snapshot.data?.where(
              (s) => s.id == result.sentenceId,
            );
            final ja = (match != null && match.isNotEmpty)
                ? match.first.ja
                : null;
            final value =
                ja ??
                (snapshot.connectionState == ConnectionState.waiting
                    ? '読み込み中…'
                    : '（教材が見つかりません）');
            return _DetailField(label: '原文', value: value);
          },
        ),
        const SizedBox(height: 12),
        _DetailField(label: 'あなたの発話', value: result.spoken),
        const SizedBox(height: 12),
        _DetailField(label: '修正版', value: result.feedback.corrected),
        const SizedBox(height: 12),
        _DetailField(label: '解説', value: result.feedback.explanationJa),
      ],
    );
  }
}

/// 独り言英会話の詳細（お題/トランスクリプト/総評）。
class _MonologueDetailSheet extends StatelessWidget {
  const _MonologueDetailSheet({required this.result, required this.repository});

  final MonologueResult result;
  final SentenceRepository repository;

  @override
  Widget build(BuildContext context) {
    return _DetailSheetScaffold(
      icon: Icons.mic_none,
      title: '独り言英会話',
      timestamp: result.timestamp,
      score: result.feedback.fluencyScore,
      children: [
        FutureBuilder<List<Topic>>(
          future: repository.topics(),
          builder: (context, snapshot) {
            final match = snapshot.data?.where((t) => t.id == result.topicId);
            final ja = (match != null && match.isNotEmpty)
                ? match.first.ja
                : null;
            final value =
                ja ??
                (snapshot.connectionState == ConnectionState.waiting
                    ? '読み込み中…'
                    : result.topicId);
            return _DetailField(label: 'お題', value: value);
          },
        ),
        const SizedBox(height: 12),
        _DetailField(label: 'トランスクリプト', value: result.transcript),
        const SizedBox(height: 12),
        _DetailField(label: '総評', value: result.feedback.overallFeedbackJa),
      ],
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
                'スコア $score',
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
