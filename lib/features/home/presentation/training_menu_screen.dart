import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_route.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../composition/presentation/deck_select_screen.dart';
import '../../monologue/presentation/topic_select_screen.dart';
import '../../settings/presentation/settings_store.dart';

/// 学習タブ。口頭作文・独り言の2つのトレーニングメニューを表示する。
///
/// トレーニングの呼び名と説明文は学習言語で変わる（設定の signal を購読する）。
class TrainingMenuScreen extends StatefulWidget {
  const TrainingMenuScreen({super.key});

  @override
  State<TrainingMenuScreen> createState() => _TrainingMenuScreenState();
}

class _TrainingMenuScreenState extends State<TrainingMenuScreen> {
  late final SettingsStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).settings();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabTraining)),
      body: SignalBuilder(
        builder: (context) {
          final code = _store.learningLanguage.value.name == 'chinese'
              ? 'zh'
              : 'en';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(title: l10n.chooseTraining),
              const SizedBox(height: 12),
              AppCard(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(appRoute(builder: (_) => const DeckSelectScreen()));
                },
                child: _MenuItem(
                  icon: Icons.edit_note,
                  title: l10n.compositionTitle(code),
                  description: l10n.compositionMenuDesc(
                    l10n.languageName(code),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(appRoute(builder: (_) => const TopicSelectScreen()));
                },
                child: _MenuItem(
                  icon: Icons.mic_none,
                  title: l10n.monologueTitle(code),
                  description: l10n.monologueMenuDesc,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ],
    );
  }
}
