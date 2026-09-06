import 'package:flutter/material.dart';

/// 「わからないので飛ばす」の確認ダイアログを表示する。
///
/// 口頭英作文のドリルで、答えが思いつかないまま制限時間を眺め続けずに
/// 模範解答へ進むための導線。誤タップで学習機会を失わないよう必ず確認を挟む。
/// 「飛ばす」を選ぶとtrue、「続ける」・ダイアログ外タップで閉じた場合はfalse。
Future<bool> confirmSkipQuestion(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('この問題を飛ばしますか？'),
      content: const Text('録音せずに模範解答と解説へ進みます。この問題は復習キューに登録されます。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('続ける'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('飛ばす'),
        ),
      ],
    ),
  );
  return result ?? false;
}
