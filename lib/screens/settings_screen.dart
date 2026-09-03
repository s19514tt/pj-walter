import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/gemini_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_chip.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/section_header.dart';

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
