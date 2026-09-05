import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// カード見出しの右端に置く、ピル型の「読み上げ」ボタン。
///
/// 通常はオレンジ枠＋白地、読み上げ中（[speaking]）はオレンジ薄背景に変わり、
/// アイコンとラベルが「停止」に切り替わる（もう一度押すと止められる）。
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.onPressed,
    this.speaking = false,
  });

  /// タップ時のコールバック（読み上げ開始／[speaking]中なら停止）
  final VoidCallback onPressed;

  /// 読み上げ中かどうか
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: speaking ? AppColors.primarySurface : AppColors.background,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                speaking ? Icons.stop : Icons.volume_up,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                speaking ? '停止' : '読み上げ',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
