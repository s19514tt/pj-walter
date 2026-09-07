import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/data/gemini_client.dart';
import '../../../core/di/store_factory.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/language/learning_language.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pill_chip.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/section_header.dart';
import 'settings_store.dart';

/// 設定画面。学習言語・Gemini APIキー・独り言デフォルト時間を管理する。
///
/// 使用モデルは[GeminiClient.modelName]に固定、音声認識はGemini録音方式のみ
/// のため、どちらも選択UIは持たず情報表示のみ行う。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsStore _store;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store = StoreFactory.of(context).settings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _store.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final saved = await _store.saveApiKey(_apiKeyController.text);
    if (!saved || !mounted) return;
    _apiKeyController.clear();
    _showSnack(context.l10n.settingsApiKeySaved);
  }

  Future<void> _deleteApiKey() async {
    await _store.deleteApiKey();
    if (!mounted) return;
    _showSnack(context.l10n.settingsApiKeyDeleted);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: l10n.settingsLearningLanguageSection),
          const SizedBox(height: 12),
          _LearningLanguageSection(store: _store),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.settingsApiKeySection),
          const SizedBox(height: 12),
          _ApiKeySection(
            store: _store,
            controller: _apiKeyController,
            onSave: _saveApiKey,
            onDelete: _deleteApiKey,
          ),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.settingsModelSection),
          const SizedBox(height: 12),
          const _ModelInfoSection(),
          const SizedBox(height: 24),
          SectionHeader(title: l10n.settingsMonologueSecondsSection),
          const SizedBox(height: 12),
          _MonologueSecondsSection(store: _store),
        ],
      ),
    );
  }
}

class _ApiKeySection extends StatelessWidget {
  const _ApiKeySection({
    required this.store,
    required this.controller,
    required this.onSave,
    required this.onDelete,
  });

  final SettingsStore store;
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: SignalBuilder(
        builder: (context) {
          final hasApiKey = store.hasApiKey.value;
          final obscure = store.obscureApiKey.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsApiKeyDescription,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              if (hasApiKey) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.settingsApiKeyConfigured,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: l10n.settingsDeleteApiKey,
                  onPressed: onDelete,
                ),
              ] else ...[
                TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: l10n.settingsApiKeyHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: store.toggleObscureApiKey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: l10n.save, onPressed: onSave),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 学習言語の切り替え。教材・採点プロンプト・文字起こしの言語が一括で変わる。
class _LearningLanguageSection extends StatelessWidget {
  const _LearningLanguageSection({required this.store});

  final SettingsStore store;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SignalBuilder(
        builder: (context) {
          final selected = store.learningLanguage.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final profile in store.languageProfiles) ...[
                if (profile != store.languageProfiles.first)
                  const SizedBox(height: 12),
                _LanguageOption(
                  profile: profile,
                  selected: selected == profile.language,
                  onTap: () => store.setLearningLanguage(profile.language),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final LanguageProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageName(profile.code),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settingsLanguageDescription(
                      l10n.deckLevelList(profile.code, profile.levels),
                      l10n.compositionTitle(profile.code),
                      l10n.monologueTitle(profile.code),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 使用モデルと音声認識方式の固定値を表示する（変更不可）。
class _ModelInfoSection extends StatelessWidget {
  const _ModelInfoSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: l10n.settingsModelLabel,
            value: GeminiClient.modelName,
          ),
          const SizedBox(height: 8),
          _InfoRow(label: l10n.settingsSttLabel, value: l10n.settingsSttValue),
          const SizedBox(height: 8),
          Text(
            l10n.settingsModelNote,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonologueSecondsSection extends StatelessWidget {
  const _MonologueSecondsSection({required this.store});

  final SettingsStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: SignalBuilder(
        builder: (context) {
          final selected = store.monologueSeconds.value;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final seconds in SettingsStore.monologueSecondsCandidates)
                PillChip(
                  label: l10n.formatDuration(seconds),
                  selected: selected == seconds,
                  onTap: () => store.setMonologueSeconds(seconds),
                ),
            ],
          );
        },
      ),
    );
  }
}
