import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../content/domain/sentence.dart';
import 'sentence_list_store.dart';

/// 選択レベル×テーマの教材一覧。
///
/// 各文はAppCardで日本語文を表示し、タップで学習言語の文＋tipsを展開表示する。
class SentenceListScreen extends StatefulWidget {
  const SentenceListScreen({super.key, required this.level, this.theme});

  /// デッキレベル（英語 700 / 800、中国語 3 / 4）
  final int level;

  /// テーマ（null なら全テーマ）
  final String? theme;

  @override
  State<SentenceListScreen> createState() => _SentenceListScreenState();
}

class _SentenceListScreenState extends State<SentenceListScreen> {
  late final SentenceListStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(
      context,
    ).sentenceList(level: widget.level, theme: widget.theme);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = widget.theme;
    final themeText = theme == null ? l10n.allThemes : l10n.themeLabel(theme);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sentenceListTitle(
            l10n.deckLevelLabel(_store.profile.code, widget.level),
            themeText,
          ),
        ),
      ),
      body: SignalBuilder(
        builder: (context) {
          final sentences = _store.sentences.value.value;
          if (sentences == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sentences.isEmpty) {
            return Center(
              child: Text(
                l10n.noMatchingSentences,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sentences.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _SentenceCard(sentence: sentences[index]),
          );
        },
      ),
    );
  }
}

/// 教材1文のカード。タップで学習言語の文＋tipsを開閉する。
class _SentenceCard extends StatefulWidget {
  const _SentenceCard({required this.sentence});

  final Sentence sentence;

  @override
  State<_SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<_SentenceCard> {
  // 開閉は描画都合のローカル状態（業務状態ではない）
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentence;
    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sentence.ja,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.expand_more,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    sentence.target,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sentence.tips,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
