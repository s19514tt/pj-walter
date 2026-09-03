import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sentence.dart';
import '../../models/learning_language.dart';
import '../../services/sentence_repository.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/theme_labels.dart';
import '../../widgets/app_card.dart';

/// 選択レベル×テーマの教材一覧。
///
/// 各文はAppCardで日本語文を表示し、タップで英文＋tipsを展開表示する。
class SentenceListScreen extends StatefulWidget {
  const SentenceListScreen({super.key, required this.level, this.theme});

  /// TOEICレベル（700 / 800）
  final int level;

  /// テーマ（null なら全テーマ）
  final String? theme;

  @override
  State<SentenceListScreen> createState() => _SentenceListScreenState();
}

class _SentenceListScreenState extends State<SentenceListScreen> {
  late final Future<List<Sentence>> _sentencesFuture;
  late final LanguageProfile _profile;

  @override
  void initState() {
    super.initState();
    final repository = context.read<SentenceRepository>();
    _profile = context.read<SettingsService>().languageProfile;
    _sentencesFuture = repository.sentencesFor(
      profile: _profile,
      level: widget.level,
      theme: widget.theme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeText = widget.theme == null ? 'すべて' : themeLabel(widget.theme!);
    final levelText = _profile.levels
        .firstWhere((deck) => deck.value == widget.level)
        .label;
    return Scaffold(
      appBar: AppBar(title: Text('教材一覧（$levelText・$themeText）')),
      body: FutureBuilder<List<Sentence>>(
        future: _sentencesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sentences = snapshot.data!;
          if (sentences.isEmpty) {
            return const Center(
              child: Text(
                '該当する教材がありません',
                style: TextStyle(color: AppColors.textSecondary),
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

/// 教材1文のカード。タップで英文＋tipsを開閉する。
class _SentenceCard extends StatefulWidget {
  const _SentenceCard({required this.sentence});

  final Sentence sentence;

  @override
  State<_SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<_SentenceCard> {
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
                  if (sentence.reading != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sentence.reading!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
