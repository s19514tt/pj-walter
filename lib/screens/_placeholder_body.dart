import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 「準備中」プレースホルダー画面の共通本文。
///
/// アイコンとメッセージを中央に表示する。screens/ 配下のみで使う内部ウィジェット。
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({super.key, required this.icon, required this.message});

  /// 表示するアイコン
  final IconData icon;

  /// 表示するメッセージ
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
