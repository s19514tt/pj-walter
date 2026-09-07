import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/score_colors.dart';

/// 円形のスコアゲージ。
///
/// 背景リング（薄グレー）＋値リング（スコアに応じた色、丸端）を
/// [CustomPaint]で描画し、中央にスコア数値（フォント44 bold）と
/// 「/100」を重ねる。0→[score]まで800msのイージングアニメーションで
/// リングが伸び、数値もカウントアップする。
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 160});

  /// 表示するスコア（0-100）
  final int score;

  /// リングの直径
  final double size;

  static const _duration = Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score.toDouble().clamp(0, 100)),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ScoreRingPainter(progress: value / 100, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${value.round()}',
                    // 直径に比例したフォントサイズ（基準: 直径160で44px）
                    style: TextStyle(
                      fontSize: size * 0.275,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    context.l10n.scoreOutOf,
                    style: TextStyle(
                      fontSize: size * 0.0875,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _strokeWidth = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -90 * 3.1415926535 / 180;
    final sweepAngle = 2 * 3.1415926535 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
