import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// スコア（0-100）に応じた表示色を返す。
///
/// 70以上は[AppColors.scoreGood]、40〜69は[AppColors.scoreMedium]、
/// それ未満は[AppColors.scoreLow]。
Color scoreColor(int score) {
  if (score >= 70) return AppColors.scoreGood;
  if (score >= 40) return AppColors.scoreMedium;
  return AppColors.scoreLow;
}

/// スコア（0-100）に応じた薄い背景色（バッジ・ハイライト用）を返す。
///
/// 70以上は[AppColors.scoreGoodSurface]、40〜69は[AppColors.scoreMediumSurface]、
/// それ未満は[AppColors.scoreLowSurface]。
Color scoreSurfaceColor(int score) {
  if (score >= 70) return AppColors.scoreGoodSurface;
  if (score >= 40) return AppColors.scoreMediumSurface;
  return AppColors.scoreLowSurface;
}
