import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 左にオレンジ縦バー（幅4×高さ18、radius2）＋太字18pxのセクション見出し。
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  /// 見出しの文言
  final String title;

  /// 右端に表示する任意のウィジェット（「すべて見る」ボタンなど）
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
