import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../domain/phrase.dart';
import 'review_launcher.dart';
import 'review_store.dart';

/// 復習タブ。「今日の復習」「復習予定」「フレーズ帳」を表示する。
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewStore _store;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).review();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _store.dispose();
    super.dispose();
  }

  Future<void> _startReview() async {
    final sentences = await _store.loadReviewSentences();
    if (!mounted) return;
    await startReviewSession(context, sentences);
    _store.reviewFinished();
  }

  Future<void> _deletePhrase(Phrase phrase) async {
    await _store.deletePhrase(phrase.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.deleted)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.review)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SignalBuilder(builder: (context) => _buildTodayReview(context)),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.upcomingReviews),
          const SizedBox(height: 12),
          SignalBuilder(builder: (context) => _buildUpcoming(context)),
          const SizedBox(height: 24),
          SignalBuilder(
            builder: (context) => SectionHeader(
              title: l10n.phraseBook,
              trailing: Text(
                l10n.itemCount(_store.phraseCount.value),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) => TextField(
              controller: _searchController,
              onChanged: _store.setQuery,
              decoration: InputDecoration(
                hintText: l10n.phraseSearchHint(
                  l10n.languageName(_store.profile.value.code),
                ),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SignalBuilder(builder: (context) => _buildPhrases(context)),
        ],
      ),
    );
  }

  Widget _buildTodayReview(BuildContext context) {
    final l10n = context.l10n;
    final dueItems = _store.dueItems.value;
    final stageCounts = _store.upcoming.value.stageCounts;
    final starting = _store.startingReview.value;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todayReview,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.srsIntervalNote,
            style: TextStyle(
              fontSize: 12,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.93),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < ReviewStore.srsStageDays.length; i++) ...[
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
                          l10n.daysLabel(ReviewStore.srsStageDays[i]),
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
              onPressed: dueItems.isEmpty || starting ? null : _startReview,
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
              child: starting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      dueItems.isEmpty
                          ? l10n.noReviewToday
                          : l10n.startReviewBatch(dueItems.length),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcoming(BuildContext context) {
    final l10n = context.l10n;
    final upcoming = _store.upcoming.value;
    if (upcoming.total == 0) {
      return AppCard(
        child: Text(
          l10n.noUpcomingReviews,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalCount(upcoming.total),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in upcoming.shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sentenceOfDeck(
                        l10n.deckLevelLabel(item.language, item.level),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    _relativeDueLabel(context, _store.daysUntil(item.dueDate)),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          if (upcoming.remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.andMore(upcoming.remaining),
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

  /// 今日からの相対的な表示（「今日」「明日」「N日後」）。過去日は「今日」として扱う。
  String _relativeDueLabel(BuildContext context, int diffDays) {
    final l10n = context.l10n;
    if (diffDays <= 0) return l10n.today;
    if (diffDays == 1) return l10n.tomorrow;
    return l10n.daysLater(diffDays);
  }

  Widget _buildPhrases(BuildContext context) {
    final l10n = context.l10n;
    final phrases = _store.filteredPhrases.value;
    if (phrases.isEmpty) {
      return AppCard(
        child: Text(
          _store.query.value.isEmpty ? l10n.noPhrases : l10n.noMatchingPhrases,
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
                  tooltip: l10n.delete,
                  onPressed: () => _deletePhrase(phrase),
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
