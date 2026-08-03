import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/phrase.dart';
import '../models/srs_item.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../utils/review_launcher.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

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
              p.en.toLowerCase().contains(query) ||
              p.ja.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();
    final dueItems = history.dueSrsItems;
    final allItems = history.allSrsItems;
    final phrases = _filteredPhrases(history.phrases);

    return Scaffold(
      appBar: AppBar(title: const Text('復習')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: '今日の復習'),
          const SizedBox(height: 12),
          _buildTodayReview(dueItems),
          const SizedBox(height: 24),
          const SectionHeader(title: '復習予定'),
          const SizedBox(height: 12),
          _buildUpcoming(allItems),
          const SizedBox(height: 24),
          const SectionHeader(title: 'フレーズ帳'),
          const SizedBox(height: 12),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildPhrases(history, phrases),
        ],
      ),
    );
  }

  Widget _buildTodayReview(List<SrsItem> dueItems) {
    if (dueItems.isEmpty) {
      return const AppCard(
        child: Center(
          child: Text(
            '今日の復習はありません🎉',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }
    return AppCard(
      child: Row(
        children: [
          Text(
            '${dueItems.length}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '件の復習があります',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          PrimaryButton(
            label: '復習を始める',
            loading: _startingReview,
            onPressed: () => _startReview(dueItems),
            compact: true,
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
                      'TOEIC ${item.level}点台の文',
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: const InputDecoration(
        hintText: '英語・日本語で検索',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
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
                        phrase.en,
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
