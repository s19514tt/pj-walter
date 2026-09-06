import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/widgets/pill_chip.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/section_header.dart';
import 'deck_select_store.dart';
import 'drill_screen.dart';
import 'sentence_list_screen.dart';

/// 口頭作文のデッキ選択画面。
///
/// レベル（英語ならTOEIC、中国語ならHSK）とテーマ（すべて/日常/ビジネス/旅行）を選び、
/// 対象文数を確認したうえで教材一覧を見たり、トレーニングを開始したりする。
class DeckSelectScreen extends StatefulWidget {
  const DeckSelectScreen({super.key});

  @override
  State<DeckSelectScreen> createState() => _DeckSelectScreenState();
}

class _DeckSelectScreenState extends State<DeckSelectScreen> {
  late final DeckSelectStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).deckSelect();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  String _themeChipLabel(BuildContext context, String? theme) =>
      theme == null ? context.l10n.allThemes : context.l10n.themeLabel(theme);

  Future<void> _startTraining() async {
    final selected = await _store.startTraining();
    if (!mounted) return;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noSentencesForDeck)));
      return;
    }
    Navigator.of(context).push(
      appRoute(
        builder: (_) => DrillScreen(
          sentences: selected,
          level: _store.level.peek(),
          theme: _store.theme.peek(),
        ),
      ),
    );
  }

  void _openSentenceList() {
    Navigator.of(context).push(
      appRoute(
        builder: (_) => SentenceListScreen(
          level: _store.level.peek(),
          theme: _store.theme.peek(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = _store.profile;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.compositionTitle(profile.code))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: l10n.chooseLevel),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) {
              final level = _store.level.value;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in profile.levels)
                    PillChip(
                      label: l10n.deckLevelLabel(profile.code, candidate),
                      selected: level == candidate,
                      onTap: () => _store.selectLevel(candidate),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.chooseTheme),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) {
              final theme = _store.theme.value;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in DeckSelectStore.themes)
                    PillChip(
                      label: _themeChipLabel(context, candidate),
                      selected: theme == candidate,
                      onTap: () => _store.selectTheme(candidate),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SignalBuilder(
            builder: (context) {
              final count = _store.count.value.value;
              return Text(
                count == null
                    ? l10n.countingSentences
                    : l10n.sentenceCount(count),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SecondaryButton(
            label: l10n.viewSentences,
            onPressed: _openSentenceList,
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: l10n.startTraining, onPressed: _startTraining),
        ],
      ),
    );
  }
}
