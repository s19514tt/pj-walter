import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// スケルトンのベース色
const _skeletonBase = Color(0xFFEDEEF1);

/// シマー（横に流れるハイライト）の色
const _skeletonShimmer = Color(0xFFF6F7F8);

/// 段階表示中のプレースホルダー行。
///
/// 角丸7px・ベース#EDEEF1に、#F6F7F8のハイライトが1.3秒linearで
/// 左から右へ流れ続ける。実テキストの折り返しを模すため、呼び出し側は
/// [widthFactor]を100%/88%/52%のように不均等に指定すること。
class SkeletonLine extends StatefulWidget {
  const SkeletonLine({super.key, this.widthFactor = 1, this.height = 12});

  /// 親幅に対する行の幅（0.0〜1.0）
  final double widthFactor;

  /// 行の高さ
  final double height;

  @override
  State<SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<SkeletonLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widget.widthFactor,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // ハイライト帯を-1.5→+1.5のAlignmentで横断させる
          final t = _controller.value * 3 - 1.5;
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: LinearGradient(
                begin: Alignment(t - 1, 0),
                end: Alignment(t + 1, 0),
                colors: const [
                  _skeletonBase,
                  _skeletonShimmer,
                  _skeletonBase,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 進行中カードに付ける小さなピルバッジ（「認識中」「AI採点中」）。
class ProgressBadge extends StatelessWidget {
  const ProgressBadge({super.key, required this.label});

  /// バッジの文言
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// 不均等な幅のスケルトン行を縦に並べた本文プレースホルダー。
class SkeletonParagraph extends StatelessWidget {
  const SkeletonParagraph({super.key, this.widths = const [1, 0.88, 0.52]});

  /// 各行の幅（親幅比）
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widths.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          SkeletonLine(widthFactor: widths[i]),
        ],
      ],
    );
  }
}

/// 処理待ちセクションのスケルトンカード（タイトル＋任意の進行バッジ＋
/// 不均等な行のプレースホルダー）。
class SkeletonSectionCard extends StatelessWidget {
  const SkeletonSectionCard({super.key, required this.title, this.badge});

  /// カードのタイトル
  final String title;

  /// 進行中バッジの文言（「認識中」「AI採点中」）。nullならバッジなし。
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (badge != null) ProgressBadge(label: badge!),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonParagraph(),
        ],
      ),
    );
  }
}
