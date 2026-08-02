import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 白・radius16・border #EEEEEE 1px の共通カード。
///
/// [onTap] を指定するとタップ可能なカードになる。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  /// カード内に表示するウィジェット
  final Widget child;

  /// タップ時のコールバック（null ならタップ不可）
  final VoidCallback? onTap;

  /// カード内の余白
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
