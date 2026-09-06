import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [SpeakButton]の3状態。
///
/// 押してから音が鳴り始めるまでには音声の生成・取得の時間があるので、
/// 「押した／押していない」の2状態だと反応が無いように見える。生成中を
/// 挟んで、押したことが必ず見た目に出るようにする。
enum SpeakButtonState {
  /// 待機中（押すと読み上げが始まる）
  idle,

  /// 押した直後。音声の生成・取得待ちで、まだ鳴っていない
  preparing,

  /// 読み上げ中（押すと止まる）
  speaking,
}

/// カード見出しの右端に置く、ピル型の「読み上げ」ボタン。
///
/// 通常はオレンジ枠＋白地、生成中・読み上げ中（[state]）はオレンジ薄背景に
/// 変わり、アイコンとラベルが「生成中」→「停止」と切り替わる
/// （読み上げ中にもう一度押すと止められる）。
///
/// 同じ文言のボタンが同じ画面に複数並ぶ（修正版と模範解答が一致した場合など）
/// ため、状態は読み上げている文ではなくボタンごとに持たせて渡すこと。
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.onPressed,
    this.state = SpeakButtonState.idle,
  });

  /// タップ時のコールバック（読み上げ開始／生成中・読み上げ中なら停止）
  final VoidCallback onPressed;

  /// ボタンの状態
  final SpeakButtonState state;

  @override
  Widget build(BuildContext context) {
    final active = state != SpeakButtonState.idle;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primarySurface : AppColors.background,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 生成中は「押したのに無音」の間を埋めるため、アイコンの代わりに
              // 同じ大きさのスピナーを出す（幅が変わらないので文字が揺れない）。
              if (state == SpeakButtonState.preparing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(
                  state == SpeakButtonState.speaking
                      ? Icons.stop
                      : Icons.volume_up,
                  size: 18,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 6),
              Text(
                switch (state) {
                  SpeakButtonState.idle => '読み上げ',
                  SpeakButtonState.preparing => '生成中',
                  SpeakButtonState.speaking => '停止',
                },
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
