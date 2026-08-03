import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 全幅・高さ52・radius14・オレンジ塗り白太字のCTAボタン。
///
/// [loading] が true の間はインジケーターを表示しタップを無効化する。
/// [compact] が true の場合は全幅ではなく内容幅・高さ40の小型ボタンになる
/// （カード内のインラインCTAなどに使用）。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.compact = false,
  });

  /// ボタンのラベル文言
  final String label;

  /// タップ時のコールバック。null または [loading] が true の間は無効。
  final VoidCallback? onPressed;

  /// ローディング中はインジケーターを表示しタップを無効化する
  final bool loading;

  /// trueの場合、全幅ではなく内容幅・高さ40の小型ボタンになる
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(label);

    if (compact) {
      return SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: child,
      ),
    );
  }
}
