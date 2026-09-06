import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// セッション中断の確認ダイアログを表示する。
///
/// 進行中のトレーニング（口頭英作文・独り言英会話）で戻る操作をしたときの
/// 誤操作防止に使う。「中断する」を選ぶとtrue、「続ける」・ダイアログ外
/// タップで閉じた場合はfalseを返す。
Future<bool> confirmAbortSession(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('トレーニングを中断しますか？'),
      content: const Text('一度中断すると、このセッションは再開できません。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('続ける'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('中断する'),
        ),
      ],
    ),
  );
  return result ?? false;
}
