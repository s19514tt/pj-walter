import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/language/learning_language.dart';
import '../services/gemini_service.dart';
import '../services/settings_service.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/pill_chip.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/secondary_button.dart';
import '../core/widgets/section_header.dart';

/// 設定画面。Gemini APIキー・独り言デフォルト時間を管理する。
///
/// 使用モデルは[GeminiService.modelName]に固定、音声認識はGemini録音方式のみ
/// のため、どちらも選択UIは持たず情報表示のみ行う。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _monologueSecondsCandidates = <int, String>{
    30: '30秒',
    60: '1分',
    120: '2分',
    180: '3分',
  };

  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: '学習する言語'),
          const SizedBox(height: 12),
          _LearningLanguageSection(settings: settings),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Gemini APIキー'),
          const SizedBox(height: 12),
          _ApiKeySection(
            settings: settings,
            controller: _apiKeyController,
            obscure: _obscureApiKey,
            onToggleObscure: () =>
                setState(() => _obscureApiKey = !_obscureApiKey),
            onSave: () async {
              final key = _apiKeyController.text.trim();
              if (key.isEmpty) return;
              await settings.setApiKey(key);
              _apiKeyController.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('APIキーを保存しました')));
              }
            },
            onDelete: () async {
              await settings.deleteApiKey();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('APIキーを削除しました')));
              }
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'モデル・音声認識'),
          const SizedBox(height: 12),
          const _ModelInfoSection(),
          const SizedBox(height: 24),
          const SectionHeader(title: '独り言のデフォルト時間'),
          const SizedBox(height: 12),
          _MonologueSecondsSection(
            settings: settings,
            candidates: _monologueSecondsCandidates,
          ),
        ],
      ),
    );
  }
}

class _ApiKeySection extends StatelessWidget {
  const _ApiKeySection({
    required this.settings,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSave,
    required this.onDelete,
  });

  final SettingsService settings;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Google AI Studio（aistudio.google.com）でAPIキーを取得して入力してください。',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (settings.hasApiKey) ...[
            const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text(
                  'APIキーは設定済みです',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SecondaryButton(label: 'APIキーを削除', onPressed: onDelete),
          ] else ...[
            TextField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: 'APIキーを入力',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleObscure,
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: '保存', onPressed: onSave),
          ],
        ],
      ),
    );
  }
}

/// 使用モデルと音声認識方式の固定値を表示する（変更不可）。
/// 学習言語の切り替え。教材・採点プロンプト・文字起こしの言語が一括で変わる。
class _LearningLanguageSection extends StatelessWidget {
  const _LearningLanguageSection({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final profile in LanguageProfile.values) ...[
            if (profile != LanguageProfile.values.first)
              const SizedBox(height: 12),
            _LanguageOption(
              profile: profile,
              selected: settings.learningLanguage == profile.language,
              onTap: () => settings.setLearningLanguage(profile.language),
            ),
          ],
        ],
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
                    '${profile.levels.map((level) => l10n.deckLevelLabel(profile.code, level)).join('・')}'
                    'の教材で、${l10n.compositionTitle(profile.code)}と'
                    '${l10n.monologueTitle(profile.code)}のトレーニングができます。',
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

class _ModelInfoSection extends StatelessWidget {
  const _ModelInfoSection();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: '使用モデル', value: GeminiService.modelName),
          SizedBox(height: 8),
          _InfoRow(label: '音声認識', value: '話した音声をGeminiに送信して文字起こし'),
          SizedBox(height: 8),
          Text(
            '添削・文字起こしは全てこのモデルで行い、APIキーの利用量を消費します。',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
  const _MonologueSecondsSection({
    required this.settings,
    required this.candidates,
  });

  final SettingsService settings;
  final Map<int, String> candidates;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in candidates.entries)
            PillChip(
              label: entry.value,
              selected: settings.monologueSeconds == entry.key,
              onTap: () => settings.setMonologueSeconds(entry.key),
            ),
        ],
      ),
    );
  }
}
