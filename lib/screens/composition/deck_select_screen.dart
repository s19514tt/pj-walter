import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/drill_question_selector.dart';
import '../../services/sentence_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_route.dart';
import '../../utils/theme_labels.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/section_header.dart';
import 'drill_screen.dart';
import 'sentence_list_screen.dart';

/// 口頭英作文のデッキ選択画面。
///
/// TOEICレベル（700点台/800点台）とテーマ（すべて/日常/ビジネス/旅行）を選び、
/// 対象文数を確認したうえで教材一覧を見たり、トレーニングを開始したりする。
class DeckSelectScreen extends StatefulWidget {
  const DeckSelectScreen({super.key});

  @override
  State<DeckSelectScreen> createState() => _DeckSelectScreenState();
}

class _DeckSelectScreenState extends State<DeckSelectScreen> {
  static const _levels = [700, 800];
  static const _themes = <String?>[null, 'daily', 'business', 'travel'];

  int _level = _levels.first;
  String? _theme;
  late Future<int> _countFuture;

  @override
  void initState() {
    super.initState();
    _countFuture = _loadCount();
  }

  Future<int> _loadCount() async {
    final repository = context.read<SentenceRepository>();
    final sentences = await repository.sentencesFor(
      level: _level,
      theme: _theme,
    );
    return sentences.length;
  }

  String _levelLabel(int level) => 'TOEIC $level点台';

  String _themeChipLabel(String? theme) =>
      theme == null ? 'すべて' : themeLabel(theme);

  Future<void> _startTraining() async {
    final repository = context.read<SentenceRepository>();
    final sentences = await repository.sentencesFor(
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
      appBar: AppBar(title: const Text('口頭英作文')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'レベルを選ぶ'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in _levels)
                PillChip(
                  label: _levelLabel(level),
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
