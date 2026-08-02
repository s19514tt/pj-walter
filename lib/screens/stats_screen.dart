import 'package:flutter/material.dart';

import '_placeholder_body.dart';

/// 記録タブ。ストリーク・カレンダー・グラフを表示する予定。
///
/// PR1時点ではプレースホルダー。
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('記録')),
      body: const PlaceholderBody(icon: Icons.bar_chart, message: '学習記録は準備中です'),
    );
  }
}
