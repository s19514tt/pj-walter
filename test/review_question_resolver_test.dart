// ReviewQuestionResolverの出題解決ロジック（sentenceId→Sentence解決・
// 欠損スキップ・dueDateが古い順に最大件数）のテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/models/srs_item.dart';
import 'package:pj_walter/services/review_question_resolver.dart';

Sentence _sentence({required String id, int level = 700}) => Sentence(
  id: id,
  ja: '日本語 $id',
  target: 'English $id',
  theme: 'daily',
  tips: 'tips',
  level: level,
);

SrsItem _item({
  required String sentenceId,
  required DateTime dueDate,
  int level = 700,
}) => SrsItem(
  sentenceId: sentenceId,
  language: 'en',
  level: level,
  stage: 0,
  dueDate: dueDate,
  lapses: 0,
  lastResult: false,
);

void main() {
  group('ReviewQuestionResolver', () {
    test('dueDateが古い順にSentenceへ解決する', () async {
      final level700 = [
        _sentence(id: 's700-001'),
        _sentence(id: 's700-002'),
        _sentence(id: 's700-003'),
      ];
      final items = [
        _item(sentenceId: 's700-003', dueDate: DateTime(2026, 1, 3)),
        _item(sentenceId: 's700-001', dueDate: DateTime(2026, 1, 1)),
        _item(sentenceId: 's700-002', dueDate: DateTime(2026, 1, 2)),
      ];
      const resolver = ReviewQuestionResolver();

      final result = await resolver.resolve(
        items: items,
        sentencesForDeck: (language, level) async => level700,
      );

      expect(result.map((s) => s.id).toList(), [
        's700-001',
        's700-002',
        's700-003',
      ]);
    });

    test('教材に存在しないsentenceIdはスキップする', () async {
      final level700 = [_sentence(id: 's700-001')];
      final items = [
        _item(sentenceId: 's700-001', dueDate: DateTime(2026, 1, 1)),
        _item(sentenceId: 's700-999', dueDate: DateTime(2026, 1, 2)),
      ];
      const resolver = ReviewQuestionResolver();

      final result = await resolver.resolve(
        items: items,
        sentencesForDeck: (language, level) async => level700,
      );

      expect(result, hasLength(1));
      expect(result.first.id, 's700-001');
    });

    test('既定の最大件数(10件)を超えるアイテムは切り捨てる', () async {
      final level700 = List.generate(
        15,
        (i) => _sentence(id: 's700-${(i + 1).toString().padLeft(3, '0')}'),
      );
      final items = List.generate(
        15,
        (i) => _item(
          sentenceId: 's700-${(i + 1).toString().padLeft(3, '0')}',
          dueDate: DateTime(2026, 1, 1).add(Duration(days: i)),
        ),
      );
      const resolver = ReviewQuestionResolver();

      final result = await resolver.resolve(
        items: items,
        sentencesForDeck: (language, level) async => level700,
      );

      expect(result, hasLength(10));
      expect(result.first.id, 's700-001');
      expect(result.last.id, 's700-010');
    });

    test('件数上限をカスタマイズできる', () async {
      final level700 = List.generate(
        5,
        (i) => _sentence(id: 's700-${(i + 1).toString().padLeft(3, '0')}'),
      );
      final items = List.generate(
        5,
        (i) => _item(
          sentenceId: 's700-${(i + 1).toString().padLeft(3, '0')}',
          dueDate: DateTime(2026, 1, 1).add(Duration(days: i)),
        ),
      );
      const resolver = ReviewQuestionResolver(limit: 3);

      final result = await resolver.resolve(
        items: items,
        sentencesForDeck: (language, level) async => level700,
      );

      expect(result, hasLength(3));
    });

    test('レベルをまたぐアイテムをそれぞれのレベルの教材から解決する', () async {
      final level700 = [_sentence(id: 's700-001')];
      final level800 = [_sentence(id: 's800-001', level: 800)];
      final items = [
        _item(
          sentenceId: 's800-001',
          level: 800,
          dueDate: DateTime(2026, 1, 2),
        ),
        _item(
          sentenceId: 's700-001',
          level: 700,
          dueDate: DateTime(2026, 1, 1),
        ),
      ];
      var level700Calls = 0;
      var level800Calls = 0;
      const resolver = ReviewQuestionResolver();

      final result = await resolver.resolve(
        items: items,
        sentencesForDeck: (language, level) async {
          if (level == 700) {
            level700Calls++;
            return level700;
          }
          level800Calls++;
          return level800;
        },
      );

      expect(result.map((s) => s.id).toList(), ['s700-001', 's800-001']);
      // 同一レベルのアイテムが複数あっても1回しかロードしない（今回は各1件だが
      // レベルごとに1回だけ呼ばれることを確認する）。
      expect(level700Calls, 1);
      expect(level800Calls, 1);
    });
  });
}
