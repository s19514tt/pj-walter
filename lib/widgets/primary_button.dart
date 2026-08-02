import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 全幅・高さ52・radius14・オレンジ塗り白太字のCTAボタン。
///
/// [loading] が true の間はインジケーターを表示しタップを無効化する。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  /// ボタンのラベル文言
  final String label;

  /// タップ時のコールバック。null または [loading] が true の間は無効。
  final VoidCallback? onPressed;

  /// ローディング中はインジケーターを表示しタップを無効化する
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}
