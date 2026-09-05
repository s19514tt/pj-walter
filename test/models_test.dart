// モデルのfromJson/toJsonラウンドトリップテスト。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/monologue_result.dart';
import 'package:pj_walter/models/phrase.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/models/srs_item.dart';
import 'package:pj_walter/models/topic.dart';

void main() {
  group('Topic', () {
    test('fromJson/toJson roundtrip', () {
      const topic = Topic(
        id: 't-001',
        ja: '今日の朝ごはんについて話してください',
        target: 'Talk about what you had for breakfast today',
        theme: 'daily',
      );

      final roundTripped = Topic.fromJson(topic.toJson());

      expect(roundTripped, topic);
    });
  });

  group('Sentence', () {
    test('fromJson/toJson roundtrip', () {
      const sentence = Sentence(
        id: 's700-001',
        ja: 'この件については後ほど折り返しご連絡します。',
        target: "I'll get back to you on this matter later.",
        theme: 'business',
        tips: 'get back to A on B で「BについてAに折り返す」',
        level: 700,
      );

      final roundTripped = Sentence.fromJson(sentence.toJson());

      expect(roundTripped, sentence);
    });
  });

  group('DrillResult', () {
    test('fromJson/toJson roundtrip', () {
      final drillResult = DrillResult(
        id: 'd-1',
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
        spoken: "I'll call you back later about this",
        timestamp: DateTime.utc(2026, 8, 3, 12, 30),
        feedback: const CompositionFeedback(
          score: 85,
          isAcceptable: true,
          corrected: "I'll call you back later about this matter.",
          explanationJa: '模範解答とほぼ同じ意味で問題ありません。',
          comparisonJa: 'get back to の代わりにcall backを使っても自然です。',
        ),
      );

      final roundTripped = DrillResult.fromJson(drillResult.toJson());

      expect(roundTripped, drillResult);
    });
  });

  group('MonologueResult', () {
    test('fromJson/toJson roundtrip', () {
      final monologueResult = MonologueResult(
        id: 'm-1',
        topicId: 't-001',
        language: 'en',
        seconds: 60,
        transcript: 'I had toast and coffee this morning.',
        timestamp: DateTime.utc(2026, 8, 3, 9),
        feedback: const MonologueFeedback(
          fluencyScore: 72,
          correctedTranscript: 'I had toast and coffee this morning.',
          corrections: [
            Correction(
              original: 'I eat toast',
              corrected: 'I had toast',
              reasonJa: '過去の話なので過去形が適切です。',
            ),
          ],
          usefulPhrases: [
            UsefulPhrase(target: 'It slipped my mind.', ja: 'うっかり忘れていた'),
          ],
          overallFeedbackJa: '発話量が十分で内容も明確でした。時制に注意しましょう。',
        ),
      );

      final roundTripped = MonologueResult.fromJson(monologueResult.toJson());

      expect(roundTripped, monologueResult);
    });
  });

  group('SrsItem', () {
    test('fromJson/toJson roundtrip', () {
      final srsItem = SrsItem(
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
        stage: 2,
        dueDate: DateTime.utc(2026, 8, 10),
        lapses: 1,
        lastResult: true,
      );

      final roundTripped = SrsItem.fromJson(srsItem.toJson());

      expect(roundTripped, srsItem);
    });

    test('copyWith updates only given fields', () {
      final srsItem = SrsItem(
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
        stage: 0,
        dueDate: DateTime.utc(2026, 8, 4),
        lapses: 0,
        lastResult: false,
      );

      final updated = srsItem.copyWith(stage: 1, lastResult: true);

      expect(updated.stage, 1);
      expect(updated.lastResult, true);
      expect(updated.sentenceId, srsItem.sentenceId);
      expect(updated.dueDate, srsItem.dueDate);
    });
  });

  group('Phrase', () {
    test('fromJson/toJson roundtrip', () {
      final phrase = Phrase(
        id: 'p-1',
        target: 'It slipped my mind.',
        ja: 'うっかり忘れていた',
        source: 'monologue',
        createdAt: DateTime.utc(2026, 8, 3),
      );

      final roundTripped = Phrase.fromJson(phrase.toJson());

      expect(roundTripped, phrase);
    });
  });
}
