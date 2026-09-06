// DrillQuestionSelectorの出題選択ロジック（ランダム10問・重複なし・
// 母数が10未満なら全問）のテスト。

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/features/content/domain/sentence.dart';
import 'package:pj_walter/features/composition/domain/drill_question_selector.dart';

Sentence _sentence(int i) => Sentence(
  id: 's700-${i.toString().padLeft(3, '0')}',
  ja: '日本語文$i',
  target: 'English sentence $i',
  theme: 'daily',
  tips: 'tips $i',
  level: 700,
);

void main() {
  group('DrillQuestionSelector', () {
    test('母数が10より多い場合はちょうど10問を重複なく選ぶ', () {
      final sentences = List.generate(20, _sentence);
      const selector = DrillQuestionSelector();

      final selected = selector.select(sentences, random: Random(1));

      expect(selected, hasLength(10));
      expect(selected.map((s) => s.id).toSet(), hasLength(10));
      for (final s in selected) {
        expect(sentences.map((e) => e.id), contains(s.id));
      }
    });

    test('母数が10未満の場合は全問を返す', () {
      final sentences = List.generate(5, _sentence);
      const selector = DrillQuestionSelector();

      final selected = selector.select(sentences, random: Random(1));

      expect(selected, hasLength(5));
      expect(
        selected.map((s) => s.id).toSet(),
        sentences.map((s) => s.id).toSet(),
      );
    });

    test('母数がちょうどcountの場合は全問を返す', () {
      final sentences = List.generate(10, _sentence);
      const selector = DrillQuestionSelector();

      final selected = selector.select(sentences, random: Random(1));

      expect(selected, hasLength(10));
    });

    test('countをカスタマイズできる', () {
      final sentences = List.generate(20, _sentence);
      const selector = DrillQuestionSelector(count: 3);

      final selected = selector.select(sentences, random: Random(1));

      expect(selected, hasLength(3));
    });

    test('引数のリストを破壊しない（unmodifiableでも動作する）', () {
      final sentences = List<Sentence>.unmodifiable(
        List.generate(15, _sentence),
      );
      const selector = DrillQuestionSelector();

      // unmodifiableなリストを渡しても例外にならないこと
      expect(
        () => selector.select(sentences, random: Random(1)),
        returnsNormally,
      );
      expect(sentences, hasLength(15));
    });
  });
}
