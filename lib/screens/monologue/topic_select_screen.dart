import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/topic.dart';
import '../../services/sentence_repository.dart';
import '../../services/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_route.dart';
import '../../core/utils/theme_labels.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/section_header.dart';
import 'monologue_speak_screen.dart';

/// 選択できる発話時間（秒）
const secondsOptions = [30, 60, 120, 180];

/// 発話時間（秒）を「30秒」「1分」のような表示文言に変換する。
String secondsLabel(int seconds) {
  if (seconds < 60) return '$seconds秒';
  return '${seconds ~/ 60}分';
}

/// 独り言英会話のお題選択画面。
///
/// テーマでお題一覧をフィルタし、発話時間を選んだうえでお題をタップ
/// （または「ランダムに選ぶ」）すると[MonologueSpeakScreen]へ進む。
class TopicSelectScreen extends StatefulWidget {
  const TopicSelectScreen({super.key});

  @override
  State<TopicSelectScreen> createState() => _TopicSelectScreenState();
}

class _TopicSelectScreenState extends State<TopicSelectScreen> {
  static const _themes = <String?>[null, 'daily', 'business', 'travel'];

  String? _theme;
  late int _seconds;
  late Future<List<Topic>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    final defaultSeconds = context.read<SettingsService>().monologueSeconds;
    _seconds = secondsOptions.contains(defaultSeconds)
        ? defaultSeconds
        : secondsOptions[1];
    _topicsFuture = _loadTopics();
  }

  Future<List<Topic>> _loadTopics() =>
      context.read<SentenceRepository>().topics(
        profile: context.read<SettingsService>().languageProfile,
        theme: _theme,
      );

  void _setTheme(String? theme) {
    setState(() {
      _theme = theme;
      _topicsFuture = _loadTopics();
    });
  }

  String _themeChipLabel(String? theme) =>
      theme == null ? 'すべて' : themeLabel(theme);

  void _openSpeak(Topic topic) {
    Navigator.of(context).push(
      appRoute(
        builder: (_) => MonologueSpeakScreen(topic: topic, seconds: _seconds),
      ),
    );
  }

  Future<void> _pickRandom() async {
    final topics = await _topicsFuture;
    if (!mounted) return;
    if (topics.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('該当するお題がありません')));
      return;
    }
    _openSpeak(topics[Random().nextInt(topics.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('独り言英会話')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  onTap: () => _setTheme(theme),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: '発話時間を選ぶ'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final seconds in secondsOptions)
                PillChip(
                  label: secondsLabel(seconds),
                  selected: _seconds == seconds,
                  onTap: () => setState(() => _seconds = seconds),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SecondaryButton(label: 'ランダムに選ぶ', onPressed: _pickRandom),
          const SizedBox(height: 24),
          const SectionHeader(title: 'お題を選ぶ'),
          const SizedBox(height: 12),
          FutureBuilder<List<Topic>>(
            future: _topicsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final topics = snapshot.data!;
              if (topics.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '該当するお題がありません',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final topic in topics) ...[
                    AppCard(
                      onTap: () => _openSpeak(topic),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.ja,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            topic.target,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
