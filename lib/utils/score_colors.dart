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
