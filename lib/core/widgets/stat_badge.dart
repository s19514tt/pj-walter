import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ピル型のステータスバッジ（例: 「合格 🎉」「要復習」）。
///
/// [surfaceColor]を背景、[textColor]を文字色に使う
/// （scoreGoodSurface＋scoreGood のような組み合わせを想定）。
class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.label,
    required this.surfaceColor,
    required this.textColor,
  });

  /// バッジの文言
  final String label;

  /// バッジの背景色（scoreXxxSurface系を想定）
  final Color surfaceColor;

  /// バッジの文字色（scoreXxx系を想定）
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
