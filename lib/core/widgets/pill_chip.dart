import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ピル型（radius999）の選択チップ。
///
/// 選択時はオレンジ薄背景＋オレンジ枠・文字、非選択時はグレー枠。
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  /// チップの文言
  final String label;

  /// 選択状態かどうか
  final bool selected;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
