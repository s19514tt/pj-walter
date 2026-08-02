import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 全幅・オレンジ枠線・白地のセカンダリボタン。
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed});

  /// ボタンのラベル文言
  final String label;

  /// タップ時のコールバック
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
