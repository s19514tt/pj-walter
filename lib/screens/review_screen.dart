import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/l10n/l10n.dart';

import '../models/phrase.dart';
import '../models/srs_item.dart';
import '../services/history_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/review_launcher.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/section_header.dart';
import '../services/settings_service.dart';

/// 復習予定一覧で全件を個別表示する上限。超えた分は件数表示のみにする。
const _upcomingListLimit = 8;

/// 復習タブ。「今日の復習」「復習予定」「フレーズ帳」を表示する。
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _searchController = TextEditingController();
  final _launcher = const ReviewSessionLauncher();
  String _query = '';
  bool _startingReview = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startReview(List<SrsItem> dueItems) async {
    if (_startingReview) return;
    setState(() => _startingReview = true);
    await _launcher.start(context, dueItems);
    if (!mounted) return;
    setState(() => _startingReview = false);
  }

  Future<void> _deletePhrase(HistoryService history, Phrase phrase) async {
    await history.deletePhrase(phrase.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('削除しました')));
  }

  List<Phrase> _filteredPhrases(List<Phrase> phrases) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return phrases;
    return phrases
        .where(
          (p) =>
              p.target.toLowerCase().contains(query) ||
              p.ja.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();
    final profile = context.watch<SettingsService>().languageProfile;
    // 復習は現在の学習言語だけを対象にする（別言語の文が現在の言語の
    // プロンプトで採点されるのを防ぐ）。
    final dueItems = history.dueSrsItems(language: profile.code);
    final allItems = history.allSrsItems;
    final phrases = _filteredPhrases(history.phrases);

    return Scaffold(
      appBar: AppBar(title: const Text('復習')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTodayReview(dueItems, allItems),
          const SizedBox(height: 24),
          const SectionHeader(title: '復習予定'),
          const SizedBox(height: 12),
          _buildUpcoming(allItems),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'フレーズ帳',
            trailing: Text(
              '${history.phrases.length}件',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSearchField(context.l10n.languageName(profile.code)),
          const SizedBox(height: 12),
          _buildPhrases(history, phrases),
        ],
      ),
    );
  }

  Widget _buildTodayReview(List<SrsItem> dueItems, List<SrsItem> allItems) {
    // stage 0-4を「1日→3日→7日→14日→30日」の各間隔として件数表示する
    const stageLabels = ['1日', '3日', '7日', '14日', '30日'];
    final stageCounts = List<int>.filled(stageLabels.length, 0);
    for (final item in allItems) {
      if (item.stage >= 0 && item.stage < stageLabels.length) {
        stageCounts[item.stage]++;
      }
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日の復習',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1日→3日→7日→14日→30日の間隔で再出題されます',
            style: TextStyle(
              fontSize: 12,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.93),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < stageLabels.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${stageCounts[i]}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          stageLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: dueItems.isEmpty || _startingReview
                  ? null
                  : () => _startReview(dueItems),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: _startingReview
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      dueItems.isEmpty
                          ? '今日の復習はありません🎉'
                          : '${dueItems.length}件を一括で開始',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcoming(List<SrsItem> allItems) {
    if (allItems.isEmpty) {
      return const AppCard(
        child: Text(
          '復習予定の文はまだありません',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final sorted = [...allItems]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final shown = sorted.take(_upcomingListLimit).toList();
    final remaining = sorted.length - shown.length;
    final today = DateTime.now();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '合計${sorted.length}件',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.l10n.deckLevelLabel(item.language, item.level)}の文',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    _relativeDueLabel(item.dueDate, today),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'ほか$remaining件',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String language) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: '$language・日本語で検索',
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPhrases(HistoryService history, List<Phrase> phrases) {
    if (phrases.isEmpty) {
      return AppCard(
        child: Text(
          _query.isEmpty ? 'フレーズはまだ登録されていません' : '一致するフレーズがありません',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final dateFormat = DateFormat('yyyy/MM/dd');
    return Column(
      children: [
        for (final phrase in phrases) ...[
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phrase.target,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phrase.ja,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(phrase.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: '削除',
                  onPressed: () => _deletePhrase(history, phrase),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// [dueDate]の[today]からの相対的な日本語表示（「今日」「明日」「N日後」）を返す。
///
/// 時刻は無視して日単位で比較する。過去日は「今日」として扱う。
String _relativeDueLabel(DateTime dueDate, DateTime today) {
  final diffDays = _dateOnly(dueDate).difference(_dateOnly(today)).inDays;
  if (diffDays <= 0) return '今日';
  if (diffDays == 1) return '明日';
  return '$diffDays日後';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
