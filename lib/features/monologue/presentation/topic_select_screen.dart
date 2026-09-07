import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pill_chip.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../content/domain/topic.dart';
import 'monologue_speak_screen.dart';
import 'topic_select_store.dart';

/// 独り言のお題選択画面。
///
/// テーマでお題一覧をフィルタし、発話時間を選んだうえでお題をタップ
/// （または「ランダムに選ぶ」）すると[MonologueSpeakScreen]へ進む。
class TopicSelectScreen extends StatefulWidget {
  const TopicSelectScreen({super.key});

  @override
  State<TopicSelectScreen> createState() => _TopicSelectScreenState();
}

class _TopicSelectScreenState extends State<TopicSelectScreen> {
  late final TopicSelectStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).topicSelect();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _openSpeak(Topic topic) {
    Navigator.of(context).push(
      appRoute(
        builder: (_) =>
            MonologueSpeakScreen(topic: topic, seconds: _store.seconds.peek()),
      ),
    );
  }

  Future<void> _pickRandom() async {
    final topic = await _store.pickRandom();
    if (!mounted) return;
    if (topic == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.noMatchingTopics)));
      return;
    }
    _openSpeak(topic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.monologueTitle(_store.profile.code))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: l10n.chooseTheme),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) {
              final theme = _store.theme.value;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in TopicSelectStore.themes)
                    PillChip(
                      label: candidate == null
                          ? l10n.allThemes
                          : l10n.themeLabel(candidate),
                      selected: theme == candidate,
                      onTap: () => _store.selectTheme(candidate),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.chooseDuration),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) {
              final seconds = _store.seconds.value;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in TopicSelectStore.secondsOptions)
                    PillChip(
                      label: l10n.formatDuration(candidate),
                      selected: seconds == candidate,
                      onTap: () => _store.selectSeconds(candidate),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          SecondaryButton(label: l10n.pickRandomTopic, onPressed: _pickRandom),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.chooseTopic),
          const SizedBox(height: 12),
          SignalBuilder(
            builder: (context) {
              final topics = _store.topics.value.value;
              if (topics == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (topics.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.noMatchingTopics,
                      style: const TextStyle(color: AppColors.textSecondary),
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
