import 'package:flutter/material.dart';

import '_placeholder_body.dart';

/// 復習タブ。今日の復習・フレーズ帳を表示する予定。
///
/// PR1時点ではプレースホルダー。
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('復習')),
      body: const PlaceholderBody(icon: Icons.refresh, message: '復習機能は準備中です'),
    );
  }
}
