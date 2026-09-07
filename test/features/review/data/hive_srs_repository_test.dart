// HiveSrsRepository（SRS 間隔反復）のテスト。DESIGN.md「SRS アルゴリズム」。

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pj_walter/features/review/data/hive_srs_repository.dart';

import '../../../test_support/hive_test_support.dart';

void main() {
  late Box box;
  final today = DateTime(2026, 9, 6, 15, 30);
  DateTime day(int offset) => DateTime(2026, 9, 6 + offset);

  setUp(() async {
    await initTestHive();
    box = await Hive.openBox('srs_items');
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  HiveSrsRepository build({DateTime? now}) =>
      HiveSrsRepository(box, now: () => now ?? today);

  group('registerFailure', () {
    test('stage0・翌日dueで登録される', () async {
      final srs = build();

      await srs.registerFailure(
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
      );

      final items = srs.items.value;
      expect(items, hasLength(1));
      expect(items.first.sentenceId, 's700-001');
      expect(items.first.language, 'en');
      expect(items.first.stage, 0);
      expect(items.first.lapses, 0);
      expect(items.first.lastResult, isFalse);
      expect(items.first.dueDate, day(1));
    });

    test('既にキューにある文が再度不合格になるとlapsesが増えstage0に戻る', () async {
      final srs = build();
      await srs.registerFailure(
        sentenceId: 's700-003',
        language: 'en',
        level: 700,
      );
      // 復習で一度昇格させておく
      await srs.applyReviewResult('s700-003', true);
      expect(srs.items.value.first.stage, 1);

      await srs.registerFailure(
        sentenceId: 's700-003',
        language: 'en',
        level: 700,
      );

      final item = srs.items.value.first;
      expect(item.stage, 0);
      expect(item.lapses, 1);
    });
  });

  group('applyReviewResult', () {
    test('正解するとstageが1進みdueDateが3日後になる', () async {
      final srs = build();
      await srs.registerFailure(
        sentenceId: 's700-010',
        language: 'en',
        level: 700,
      );

      await srs.applyReviewResult('s700-010', true);

      final item = srs.items.value.first;
      expect(item.stage, 1);
      expect(item.lastResult, isTrue);
      expect(item.dueDate, day(3));
    });

    test('間隔は 1→3→7→14→30 日で、stage4から正解すると卒業して削除される', () async {
      final srs = build();
      await srs.registerFailure(
        sentenceId: 's700-011',
        language: 'en',
        level: 700,
      );

      final expectedDue = [3, 7, 14, 30];
      for (var i = 0; i < 4; i++) {
        await srs.applyReviewResult('s700-011', true);
        expect(srs.items.value.first.stage, i + 1);
        expect(srs.items.value.first.dueDate, day(expectedDue[i]));
      }

      // stage4 -> 5(卒業)
      await srs.applyReviewResult('s700-011', true);

      expect(srs.items.value, isEmpty);
    });

    test('不正解だとstage0に戻り翌日dueになる', () async {
      final srs = build();
      await srs.registerFailure(
        sentenceId: 's700-012',
        language: 'en',
        level: 700,
      );
      await srs.applyReviewResult('s700-012', true);
      expect(srs.items.value.first.stage, 1);

      await srs.applyReviewResult('s700-012', false);

      final item = srs.items.value.first;
      expect(item.stage, 0);
      expect(item.lastResult, isFalse);
      expect(item.dueDate, day(1));
    });

    test('存在しないsentenceIdに対しては何もしない', () async {
      final srs = build();
      await srs.applyReviewResult('unknown', true);
      expect(srs.items.value, isEmpty);
    });
  });

  group('due', () {
    test('dueDateが今日以前のアイテムのみ、dueDateの早い順に返す（日単位比較）', () async {
      final srs = build();
      await srs.registerFailure(
        sentenceId: 's700-020',
        language: 'en',
        level: 700,
      );
      // 登録直後のdueDateは翌日なので、まだ「今日の復習」には含まれない
      expect(srs.due(), isEmpty);

      // 翌日になれば対象になる（時刻は無視）
      expect(srs.due(now: DateTime(2026, 9, 7, 0, 1)), hasLength(1));
      expect(srs.due(now: day(1)).first.sentenceId, 's700-020');
    });

    test('languageを渡すとその学習言語のアイテムだけを返す', () async {
      final srs = build();
      await srs.registerFailure(
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
      );
      await srs.registerFailure(sentenceId: 'z3-001', language: 'zh', level: 3);

      final tomorrow = day(1);
      expect(srs.due(now: tomorrow), hasLength(2));
      expect(srs.due(language: 'zh', now: tomorrow).map((i) => i.sentenceId), [
        'z3-001',
      ]);
      expect(srs.due(language: 'en', now: tomorrow).map((i) => i.sentenceId), [
        's700-001',
      ]);
    });
  });

  test('保存した内容は別インスタンスで読み直せる', () async {
    await build().registerFailure(
      sentenceId: 's700-001',
      language: 'en',
      level: 700,
    );

    final reopened = build();

    expect(reopened.items.value.single.sentenceId, 's700-001');
  });
}
