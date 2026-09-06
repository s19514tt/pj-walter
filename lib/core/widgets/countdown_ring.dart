import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// スピーキング画面共通の円形カウントダウンリング。
///
/// 200×200のボックスに直径180（半径`size * 0.45`）・線幅8のリングを描く。
/// 12時起点で**時計回りに消費**され（先端が12時に固定され、空きが時計回りに
/// 広がる）、1秒ごとの更新をlinear補間で滑らかに描画する。
///
/// 聞き取りが始まった瞬間（[recording]がfalse→true）にリング全体が
/// 1.0→1.11→1.08と一度弾んで1.08で止まる（デザインの`ringPop`、620ms）。
/// 「大きくなったまま聞き取り中」であることが分かるようにするための演出で、
/// 線幅・半径は変えない。[recording]がfalseに戻ると等倍へ戻す。
///
/// [dimmed]は録音開始前（pre）の状態で、弧・数字は#B9BDC4、ドットはグレー、
/// ラベルは[idleLabel]（「聞き取り前」など）になる。聞き取り中（rec）は
/// オレンジ・「聞き取り中」・赤ドット、残りわずか（[urgent]）で警告色。
/// トラックは常に#EDEEF1。
class CountdownRing extends StatefulWidget {
  const CountdownRing({
    super.key,
    required this.progress,
    required this.label,
    required this.recording,
    required this.idleLabel,
    this.dimmed = false,
    this.urgent = false,
    this.size = 200,
  });

  /// 残り時間の割合（0.0〜1.0）。リングはこの割合ぶんだけ描画される。
  final double progress;

  /// 中央に表示する残り時間（「23」「1:42」など）
  final String label;

  /// 録音中かどうか（状態ドットの色・状態テキストと、弾む演出に反映）
  final bool recording;

  /// pre（録音開始前）に表示する状態テキスト（例:「録音前」）
  final String idleLabel;

  /// 録音開始前（pre）の控えめ表示
  final bool dimmed;

  /// 残りわずか表示（リング・数値を警告色にする）
  final bool urgent;

  /// リングの直径
  final double size;

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing>
    with SingleTickerProviderStateMixin {
  /// 聞き取り開始時に一度だけ再生する「弾み」（デザインの`ringPop`）。
  /// 再生後は1.08倍のまま保持し、preへ戻るとリセットして等倍に戻す。
  static final _pop = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.11,
      ).chain(CurveTween(curve: const Cubic(.3, .85, .5, 1))),
      weight: 38,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.11,
        end: 1.08,
      ).chain(CurveTween(curve: const Cubic(.5, 0, .5, 1))),
      weight: 62,
    ),
  ]);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  bool get _active => widget.recording && !widget.dimmed;

  @override
  void initState() {
    super.initState();
    // 最初から聞き取り中の状態で組み立てられた場合は、弾み終わった姿で見せる。
    if (_active) _controller.value = 1;
  }

  @override
  void didUpdateWidget(CountdownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.recording && !oldWidget.dimmed;
    if (_active == wasActive) return;
    if (_active) {
      _controller.forward(from: 0);
    } else {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.dimmed
        ? const Color(0xFFB9BDC4)
        : widget.urgent
        ? AppColors.scoreLow
        : AppColors.primary;
    return ScaleTransition(
      scale: _pop.animate(_controller),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        // 1秒刻みの更新をlinear補間して滑らかに減らす
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: widget.progress.clamp(0, 1)),
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
          builder: (context, animatedProgress, child) => CustomPaint(
            painter: _CountdownRingPainter(
              progress: animatedProgress.clamp(0.0, 1.0),
              color: ringColor,
            ),
            child: child,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
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
                        color: _active
                            ? AppColors.scoreLow
                            : const Color(0xFFC4C7CC),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _active ? context.l10n.listening : widget.idleLabel,
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
      ),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  /// トラック・進捗弧の線幅（デザインどおり固定）
  static const _strokeWidth = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // デザインは200のボックスに r=90。線幅が変わらないので比率で決め打ちできる。
    final radius = size.shortestSide * 0.45;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = const Color(0xFFEDEEF1);
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
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
      oldDelegate.progress != progress || oldDelegate.color != color;
}
