import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/app_route.dart';
import '../../composition/presentation/drill_screen.dart';
import '../../content/domain/sentence.dart';

/// 「今日の復習」開始処理の共通ロジック（ホーム画面・復習タブの両方から使う）。
///
/// Store が解決した出題文で復習モードの[DrillScreen]へ遷移し、セッションが終わるまで待つ。
/// 出題文が無い（教材が見つからない）場合はスナックバーで通知する。
Future<void> startReviewSession(
  BuildContext context,
  List<Sentence> sentences,
) async {
  if (sentences.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.noReviewSentences)));
    return;
  }
  await Navigator.of(context).push(
    appRoute(
      builder: (_) => DrillScreen(
        sentences: sentences,
        level: sentences.first.level,
        theme: null,
        isReview: true,
      ),
    ),
  );
}
