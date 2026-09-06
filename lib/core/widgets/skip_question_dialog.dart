import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// 「わからないので飛ばす」の確認ダイアログを表示する。
///
/// 口頭英作文のドリルで、答えが思いつかないまま制限時間を眺め続けずに
/// 模範解答へ進むための導線。誤タップで学習機会を失わないよう必ず確認を挟む。
/// 「飛ばす」を選ぶとtrue、「続ける」・ダイアログ外タップで閉じた場合はfalse。
Future<bool> confirmSkipQuestion(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.skipQuestionTitle),
      content: Text(l10n.skipQuestionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.continueLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.skipQuestion),
        ),
      ],
    ),
  );
  return result ?? false;
}
