import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// スピーキング画面共通の円形カウントダウンリング。
///
/// 直径200のリング。12時起点で**時計回りに消費**され（先端が12時に固定され、
/// 空きが時計回りに広がる）、1秒ごとの更新をlinear補間で滑らかに描画する。
///
/// 進捗弧の線幅は入力音量[level]に応じて8〜14pxで変化し、話している間は
/// リングが太く脈動する（Claude Designプロトタイプには無い本実装独自の仕様）。
///
/// [dimmed]は録音開始前（pre）の状態で、弧・数字は#B9BDC4、ドットはグレー、
/// ラベルは[idleLabel]（「聞き取り前」など）になる。聞き取り中（rec）は
/// オレンジ・「聞き取り中」・赤ドット、残りわずか（[urgent]）で警告色。
/// トラックは常に#EDEEF1。
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.progress,
    required this.label,
    required this.recording,
    required this.idleLabel,
    this.level = 0,
    this.dimmed = false,
    this.urgent = false,
    this.size = 200,
  });

  /// 残り時間の割合（0.0〜1.0）。リングはこの割合ぶんだけ描画される。
  final double progress;

  /// 中央に表示する残り時間（「23」「1:42」など）
  final String label;

  /// 録音中かどうか（状態ドットの色と状態テキストに反映）
  final bool recording;

  /// pre（録音開始前）に表示する状態テキスト（例:「録音前」）
  final String idleLabel;

  /// 入力音量（0.0〜1.0）。進捗弧の線幅を8pxから14pxの間で変化させる。
  final double level;

  /// 録音開始前（pre）の控えめ表示
  final bool dimmed;

  /// 残りわずか表示（リング・数値を警告色にする）
  final bool urgent;

  /// リングの直径
  final double size;

  @override
  Widget build(BuildContext context) {
    final ringColor = dimmed
        ? const Color(0xFFB9BDC4)
        : urgent
        ? AppColors.scoreLow
        : AppColors.primary;
    return SizedBox(
      width: size,
      height: size,
      // 1秒刻みの更新をlinear補間して滑らかに減らす
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: progress.clamp(0, 1)),
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
        builder: (context, animatedProgress, child) => CustomPaint(
          painter: _CountdownRingPainter(
            progress: animatedProgress.clamp(0.0, 1.0),
            color: ringColor,
            // 音量0で8px、最大音量で14px
            strokeWidth: dimmed ? 8 : 8 + 6 * level.clamp(0.0, 1.0),
          ),
          child: child,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: ringColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: recording && !dimmed
                          ? AppColors.scoreLow
                          : const Color(0xFFC4C7CC),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    recording && !dimmed ? '聞き取り中' : idleLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;

  /// 進捗弧の線幅（音量に応じて8〜14px）
  final double strokeWidth;

  /// 最大線幅。レイアウト半径はこれ基準で固定し、線幅が変わっても
  /// リングの外径が動かないようにする。
  static const _maxStrokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _maxStrokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = const Color(0xFFEDEEF1);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    // 弧の終端（12時）を固定し、始端を時計回りに進めることで
    // 「時計回りに消費される」見え方にする（終端を縮めると反時計回りに見える）。
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (2 * math.pi - sweep),
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
