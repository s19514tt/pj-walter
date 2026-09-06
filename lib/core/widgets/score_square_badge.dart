import 'package:flutter/material.dart';

import '../utils/score_colors.dart';

/// スコアを角丸スクエア（42px・radius13・スコア色の薄背景＋濃文字）で表示する
/// バッジ。まとめ画面・履歴一覧などのリスト行で使う。
class ScoreSquareBadge extends StatelessWidget {
  const ScoreSquareBadge({super.key, required this.score, this.size = 42});

  /// 表示するスコア（0-100）
  final int score;

  /// バッジの一辺
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scoreSurfaceColor(score),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: scoreColor(score),
        ),
      ),
    );
  }
}
