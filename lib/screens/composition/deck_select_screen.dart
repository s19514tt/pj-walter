import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/drill_question_selector.dart';
import '../../services/sentence_repository.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_route.dart';
import '../../core/utils/theme_labels.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/section_header.dart';
import 'drill_screen.dart';
import 'sentence_list_screen.dart';
import '../../services/settings_service.dart';
import '../../core/language/learning_language.dart';

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
  static const _themes = <String?>[null, 'daily', 'business', 'travel'];

  late LanguageProfile _profile;
  late int _level;
  String? _theme;
  late Future<int> _countFuture;

  @override
  void initState() {
    super.initState();
    _profile = context.read<SettingsService>().languageProfile;
    _level = _profile.levels.first;
    _countFuture = _loadCount();
  }

  Future<int> _loadCount() async {
    final repository = context.read<SentenceRepository>();
    final sentences = await repository.sentencesFor(
      profile: _profile,
      level: _level,
      theme: _theme,
    );
    return sentences.length;
  }

  String _themeChipLabel(String? theme) =>
      theme == null ? 'すべて' : themeLabel(theme);

  Future<void> _startTraining() async {
    final repository = context.read<SentenceRepository>();
    final sentences = await repository.sentencesFor(
      profile: _profile,
      level: _level,
      theme: _theme,
    );
    if (!mounted) return;
    if (sentences.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('対象の教材がありません')));
      return;
    }
    const selector = DrillQuestionSelector();
    final selected = selector.select(sentences);
    if (!mounted) return;
    Navigator.of(context).push(
      appRoute(
        builder: (_) =>
            DrillScreen(sentences: selected, level: _level, theme: _theme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.compositionTitle(_profile.code))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'レベルを選ぶ'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in _profile.levels)
                PillChip(
                  label: context.l10n.deckLevelLabel(_profile.code, level),
                  selected: _level == level,
                  onTap: () => setState(() {
                    _level = level;
                    _countFuture = _loadCount();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'テーマを選ぶ'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final theme in _themes)
                PillChip(
                  label: _themeChipLabel(theme),
                  selected: _theme == theme,
                  onTap: () => setState(() {
                    _theme = theme;
                    _countFuture = _loadCount();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<int>(
            future: _countFuture,
            builder: (context, snapshot) {
              final count = snapshot.data;
              return Text(
                count == null ? '対象文数を確認しています…' : '対象文数: $count文',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SecondaryButton(
            label: '教材を見る',
            onPressed: () {
              Navigator.of(context).push(
                appRoute(
                  builder: (_) =>
                      SentenceListScreen(level: _level, theme: _theme),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'トレーニング開始', onPressed: _startTraining),
        ],
      ),
    );
  }
}
