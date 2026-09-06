import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/utils/word_diff.dart';

void main() {
  group('diffWords', () {
    test('完全一致なら全てsame', () {
      final result = diffWords('I have a pen', 'I have a pen');

      expect(result, [
        const DiffSegment(text: 'I', type: DiffSegmentType.same),
        const DiffSegment(text: 'have', type: DiffSegmentType.same),
        const DiffSegment(text: 'a', type: DiffSegmentType.same),
        const DiffSegment(text: 'pen', type: DiffSegmentType.same),
      ]);
    });

    test('大文字小文字だけの違いはsame扱い（表記は元のまま保持）', () {
      final result = diffWords('i have A pen', 'I have a pen');

      expect(result.map((s) => s.type), everyElement(DiffSegmentType.same));
      // fromの表記がそのまま保持される
      expect(result.map((s) => s.text), ['i', 'have', 'A', 'pen']);
    });

    test('単語の置換を検出する', () {
      final result = diffWords('I eat toast', 'I had toast');

      expect(result, [
        const DiffSegment(text: 'I', type: DiffSegmentType.same),
        const DiffSegment(text: 'eat', type: DiffSegmentType.removed),
        const DiffSegment(text: 'had', type: DiffSegmentType.added),
        const DiffSegment(text: 'toast', type: DiffSegmentType.same),
      ]);
    });

    test('挿入を検出する', () {
      final result = diffWords('I want go', 'I want to go');

      expect(result, [
        const DiffSegment(text: 'I', type: DiffSegmentType.same),
        const DiffSegment(text: 'want', type: DiffSegmentType.same),
        const DiffSegment(text: 'to', type: DiffSegmentType.added),
        const DiffSegment(text: 'go', type: DiffSegmentType.same),
      ]);
    });

    test('削除を検出する', () {
      final result = diffWords('I really want to go', 'I want to go');

      expect(result, [
        const DiffSegment(text: 'I', type: DiffSegmentType.same),
        const DiffSegment(text: 'really', type: DiffSegmentType.removed),
        const DiffSegment(text: 'want', type: DiffSegmentType.same),
        const DiffSegment(text: 'to', type: DiffSegmentType.same),
        const DiffSegment(text: 'go', type: DiffSegmentType.same),
      ]);
    });

    test('空文字のfromは全てadded', () {
      final result = diffWords('', 'I have a pen');

      expect(result, [
        const DiffSegment(text: 'I', type: DiffSegmentType.added),
        const DiffSegment(text: 'have', type: DiffSegmentType.added),
        const DiffSegment(text: 'a', type: DiffSegmentType.added),
        const DiffSegment(text: 'pen', type: DiffSegmentType.added),
      ]);
    });

    test('空文字のtoは全てremoved', () {
      final result = diffWords('I have a pen', '');

      expect(result, [
        const DiffSegment(text: 'I', type: DiffSegmentType.removed),
        const DiffSegment(text: 'have', type: DiffSegmentType.removed),
        const DiffSegment(text: 'a', type: DiffSegmentType.removed),
        const DiffSegment(text: 'pen', type: DiffSegmentType.removed),
      ]);
    });

    test('両方空文字なら空リスト', () {
      expect(diffWords('', ''), isEmpty);
    });

    test('セグメントを絞り込むとfrom・toそれぞれの文を再構築できる', () {
      final result = diffWords('my first answer', 'Corrected answer 1');

      final reconstructedFrom = result
          .where((s) => s.type != DiffSegmentType.added)
          .map((s) => s.text)
          .join(' ');
      final reconstructedTo = result
          .where((s) => s.type != DiffSegmentType.removed)
          .map((s) => s.text)
          .join(' ');

      expect(reconstructedFrom, 'my first answer');
      expect(reconstructedTo, 'Corrected answer 1');
    });
  });

  group('diffWords（分かち書きしない言語）', () {
    test('中国語は漢字1文字ずつトークン化され、全消し全追加にならない', () {
      final result = diffWords('我昨天去公园', '我今天去公园');

      // 空白分割だと文全体が1トークンになり removed+added の2件になってしまう
      expect(result.length, greaterThan(2));
      expect(
        result.where((s) => s.type == DiffSegmentType.same).map((s) => s.text),
        containsAll(['我', '天', '去', '公', '园']),
      );
      expect(
        result
            .where((s) => s.type == DiffSegmentType.removed)
            .map((s) => s.text),
        contains('昨'),
      );
      expect(
        result.where((s) => s.type == DiffSegmentType.added).map((s) => s.text),
        contains('今'),
      );
    });

    test('中国語で完全一致なら全てsame', () {
      final result = diffWords('请把书放在桌子上。', '请把书放在桌子上。');

      expect(result.map((s) => s.type), everyElement(DiffSegmentType.same));
    });

    test('全角句読点は独立したトークンになる', () {
      final result = diffWords('我去', '我去。');

      expect(
        result.last,
        const DiffSegment(text: '。', type: DiffSegmentType.added),
      );
    });

    test('中国語に混ざる英数字はまとまりのまま1トークンになる', () {
      final result = diffWords('我有100块钱', '我有200块钱');

      expect(
        result
            .where((s) => s.type == DiffSegmentType.removed)
            .map((s) => s.text),
        ['100'],
      );
      expect(
        result.where((s) => s.type == DiffSegmentType.added).map((s) => s.text),
        ['200'],
      );
    });
  });

  group('groupDiffSegments', () {
    List<DiffSegment> correctedSide(String spoken, String corrected) =>
        diffWords(
          spoken,
          corrected,
        ).where((s) => s.type != DiffSegmentType.removed).toList();

    test('語区切りが無ければ連続する差分を1つのまとまりにする', () {
      // 句読点も追加された差分なので同じまとまりに入る（描画側で色は付けない）
      final groups = groupDiffSegments(correctedSide('我要', '我要喝水。'));

      expect(groups.map((g) => g.text), ['我', '要', '喝水。']);
      expect(groups.map((g) => g.changed), [false, false, true]);
    });

    test('語区切りがあれば単語ごとにまとまりを切る', () {
      final groups = groupDiffSegments(
        correctedSide('我们爬桥边', '我们在建筑物前面拍吧'),
        words: const ['我们', '在', '建筑物', '前面', '拍', '吧'],
      );

      expect(groups.where((g) => g.changed).map((g) => g.text), [
        '在',
        '建筑物',
        '前面',
        '拍',
        '吧',
      ]);
    });

    test('差分の無いセグメントは1つずつのまとまりのまま', () {
      final groups = groupDiffSegments(
        correctedSide('我要水', '我要水'),
        words: const ['我', '要水'],
      );

      expect(groups.map((g) => g.text), ['我', '要', '水']);
    });

    test('語区切りが文と一致しなければ使わない（ずれた位置で切らない）', () {
      final groups = groupDiffSegments(
        correctedSide('我要', '我要喝水。'),
        words: const ['我', '要', '喝', '水'], // 「。」が足りない
      );

      expect(groups.map((g) => g.text), ['我', '要', '喝水。']);
    });

    test('英語では単語がそのままトークンなので連続する差分がまとまる', () {
      final groups = groupDiffSegments(
        diffWords(
          'I eat toast',
          'I had toast',
        ).where((s) => s.type != DiffSegmentType.removed).toList(),
      );

      expect(groups.map((g) => g.text), ['I', 'had', 'toast']);
    });
  });
}
