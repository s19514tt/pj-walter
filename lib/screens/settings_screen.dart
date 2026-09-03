import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_language.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_chip.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/section_header.dart';

/// 設定タブ。学習言語・Gemini APIキー・モデル・音声認識方式・独り言デフォルト時間を管理する。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _modelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash',
  ];

  static const _monologueSecondsCandidates = <int, String>{
    30: '30秒',
    60: '1分',
    120: '2分',
    180: '3分',
  };

  final _apiKeyController = TextEditingController();
  final _customModelController = TextEditingController();
  bool _obscureApiKey = true;
  bool _modelFieldInitialized = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    // 再ビルドのたびに上書きすると編集中の入力が消えるため、初回のみ反映する
    if (!_modelFieldInitialized) {
      _customModelController.text = settings.modelName;
      _modelFieldInitialized = true;
    }

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
          const SectionHeader(title: 'モデル'),
          const SizedBox(height: 12),
          _ModelSection(
            settings: settings,
            candidates: _modelCandidates,
            customController: _customModelController,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: '音声認識方式'),
          const SizedBox(height: 12),
          _SttModeSection(settings: settings),
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

class _ModelSection extends StatelessWidget {
  const _ModelSection({
    required this.settings,
    required this.candidates,
    required this.customController,
  });

  final SettingsService settings;
  final List<String> candidates;
  final TextEditingController customController;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final model in candidates)
                PillChip(
                  label: model,
                  selected: settings.modelName == model,
                  onTap: () {
                    settings.setModelName(model);
                    customController.text = model;
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: customController,
            decoration: const InputDecoration(
              labelText: 'モデル名を直接入力',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) settings.setModelName(trimmed);
            },
          ),
        ],
      ),
    );
  }
}

/// 学習言語の切り替え。教材・採点プロンプト・音声認識のロケールが一括で変わる。
class _LearningLanguageSection extends StatelessWidget {
  const _LearningLanguageSection({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (final profile in LanguageProfile.values) ...[
            if (profile != LanguageProfile.values.first)
              const SizedBox(height: 12),
            _SttModeOption(
              title: profile.label,
              description:
                  '${profile.levels.map((deck) => deck.label).join('・')}'
                  'の教材で、${profile.compositionTitle}と'
                  '${profile.monologueTitle}を行います。',
              selected: settings.learningLanguage == profile.language,
              onTap: () => settings.setLearningLanguage(profile.language),
            ),
          ],
        ],
      ),
    );
  }
}

class _SttModeSection extends StatelessWidget {
  const _SttModeSection({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _SttModeOption(
            title: '端末の音声認識',
            description: '無料・高速。端末の標準音声認識機能を使用します。',
            selected: settings.sttMode == SttMode.device,
            onTap: () => settings.setSttMode(SttMode.device),
          ),
          const SizedBox(height: 12),
          _SttModeOption(
            title: 'Gemini音声認識',
            description: '高精度。録音をGeminiに送信して文字起こしします（APIキーを消費）。',
            selected: settings.sttMode == SttMode.gemini,
            onTap: () => settings.setSttMode(SttMode.gemini),
          ),
        ],
      ),
    );
  }
}

class _SttModeOption extends StatelessWidget {
  const _SttModeOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
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
