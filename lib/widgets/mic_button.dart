import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ドリル・独り言共通のマイク操作ボタン。
///
/// 未録音時はprimaryGradient背景＋オレンジの影。録音中は外側に広がる
/// 半透明オレンジのパルスリングを繰り返しアニメーションさせ、
/// アイコンをstopに切り替える。処理中はローディングインジケーターを表示する。
class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.recording,
    required this.processing,
    required this.onTap,
    this.size = 88,
  });

  /// 録音中かどうか
  final bool recording;

  /// 音声認識/文字起こし処理中かどうか（trueの間はタップ不可）
  final bool processing;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// ボタン本体の直径
  final double size;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.recording) _pulseController.repeat();
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.recording && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseSize = widget.size * 1.7;
    return SizedBox(
      width: pulseSize,
      height: pulseSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.recording)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final t = _pulseController.value;
                return Opacity(
                  opacity: (1 - t) * 0.35,
                  child: Container(
                    width: widget.size + (pulseSize - widget.size) * t,
                    height: widget.size + (pulseSize - widget.size) * t,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.recording ? AppColors.error : null,
              gradient: widget.recording ? null : AppColors.primaryGradient,
              boxShadow: widget.recording
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.processing ? null : widget.onTap,
                customBorder: const CircleBorder(),
                child: Center(
                  child: widget.processing
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          widget.recording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
