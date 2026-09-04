import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/srs_item.dart';
import '../screens/composition/drill_screen.dart';
import '../services/review_question_resolver.dart';
import '../services/sentence_repository.dart';
import 'app_route.dart';
import '../models/learning_language.dart';

/// 「今日の復習」開始処理の共通ロジック。
///
/// [SrsItem]一覧から出題文を解決し、復習モードの[DrillScreen]へ遷移する。
/// 対象教材が見つからない場合はスナックバーで通知する。ホーム画面・復習タブの
/// 両方から呼ばれるため、ここに一本化して重複実装を避ける。
class ReviewSessionLauncher {
  const ReviewSessionLauncher({this.resolver = const ReviewQuestionResolver()});

  final ReviewQuestionResolver resolver;

  /// [dueItems]を出題し、復習セッション（[DrillScreen]）が終わるまで待つ。
  Future<void> start(BuildContext context, List<SrsItem> dueItems) async {
    final repository = context.read<SentenceRepository>();
    final sentences = await resolver.resolve(
      items: dueItems,
      sentencesForDeck: (language, level) => repository.sentencesFor(
        profile: LanguageProfile.ofCode(language),
        level: level,
      ),
    );
    if (!context.mounted) return;

    if (sentences.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('復習対象の教材が見つかりませんでした')));
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
}
