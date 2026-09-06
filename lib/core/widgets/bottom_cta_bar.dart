import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 画面下固定のCTAバー。
///
/// 白背景・上辺1px border・SafeArea内に[child]（通常は[PrimaryButton]）を
/// 左右16px/上下12pxパディングで配置する。スクロール本文はこの分の
/// 下部余白（[BottomCtaBar.contentPadding]目安）を取ること。
class BottomCtaBar extends StatelessWidget {
  const BottomCtaBar({super.key, required this.child, this.secondary});

  /// バーに表示するメインのウィジェット（通常は[PrimaryButton]）
  final Widget child;

  /// メインの上に表示する任意のウィジェット（テキストボタンなど）
  final Widget? secondary;

  /// 本文側に確保しておくべきおおよその下部余白
  static const double contentPadding = 96;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [?secondary, child],
          ),
        ),
      ),
    );
  }
}
