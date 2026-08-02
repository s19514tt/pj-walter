import 'package:flutter/material.dart';

import '_placeholder_body.dart';

/// 設定タブ。Gemini APIキー等の設定を行う予定。
///
/// PR1時点ではプレースホルダー。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const PlaceholderBody(
        icon: Icons.settings_outlined,
        message: '設定は準備中です',
      ),
    );
  }
}
