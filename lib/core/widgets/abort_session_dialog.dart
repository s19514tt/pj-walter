import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// セッション中断の確認ダイアログを表示する。
///
/// 進行中のトレーニング（口頭英作文・独り言英会話）で戻る操作をしたときの
/// 誤操作防止に使う。「中断する」を選ぶとtrue、「続ける」・ダイアログ外
/// タップで閉じた場合はfalseを返す。
Future<bool> confirmAbortSession(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.abortSessionTitle),
      content: Text(l10n.abortSessionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.continueLabel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.abortSession),
        ),
      ],
    ),
  );
  return result ?? false;
}
