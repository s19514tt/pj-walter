// DTO（Hive の保存形式・API の応答スキーマ）と Entity の相互変換テスト。
//
// Entity（freezed）は JSON を知らない。JSON の形は data/ の DTO が持ち、
// `toEntity()` / `fromEntity()` で往復できることをここで担保する。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/features/composition/data/drill_result_dto.dart';
import 'package:pj_walter/features/composition/domain/drill_result.dart';
import 'package:pj_walter/features/composition/domain/tone_note.dart';
import 'package:pj_walter/features/content/data/sentence_dto.dart';
import 'package:pj_walter/features/content/data/topic_dto.dart';
import 'package:pj_walter/features/content/domain/sentence.dart';
import 'package:pj_walter/features/content/domain/topic.dart';
import 'package:pj_walter/features/monologue/data/monologue_result_dto.dart';
import 'package:pj_walter/features/monologue/domain/monologue_result.dart';
import 'package:pj_walter/features/review/data/phrase_dto.dart';
import 'package:pj_walter/features/review/data/srs_item_dto.dart';
import 'package:pj_walter/features/review/domain/phrase.dart';
import 'package:pj_walter/features/review/domain/srs_item.dart';

void main() {
  group('Topic', () {
    test('教材JSONから Entity を作れる', () {
      final topic = TopicDto.fromJson(const {
        'id': 't-001',
        'ja': '今日の朝ごはんについて話してください',
        'target': 'Talk about what you had for breakfast today',
        'theme': 'daily',
      }).toEntity();

      expect(
        topic,
        const Topic(
          id: 't-001',
          ja: '今日の朝ごはんについて話してください',
          target: 'Talk about what you had for breakfast today',
          theme: 'daily',
        ),
      );
      expect(topic.reading, isNull);
    });
  });

  group('Sentence', () {
    test('教材JSONとファイル側の level から Entity を作れる', () {
      final sentence = SentenceDto.fromJson(const {
        'id': 's700-001',
        'ja': 'この件については後ほど折り返しご連絡します。',
        'target': "I'll get back to you on this matter later.",
        'theme': 'business',
        'tips': 'get back to A on B で「BについてAに折り返す」',
      }).toEntity(level: 700);

      expect(
        sentence,
        const Sentence(
          id: 's700-001',
          ja: 'この件については後ほど折り返しご連絡します。',
          target: "I'll get back to you on this matter later.",
          theme: 'business',
          tips: 'get back to A on B で「BについてAに折り返す」',
          level: 700,
        ),
      );
    });
  });

  group('DrillResult', () {
    DrillResult roundTrip(DrillResult result) => DrillResultDto.fromJson(
      DrillResultDto.fromEntity(result).toJson(),
    ).toEntity();

    test('Entity → DTO → JSON → Entity で往復できる', () {
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
          explanation: '模範解答とほぼ同じ意味で問題ありません。',
          comparison: 'get back to の代わりにcall backを使っても自然です。',
        ),
      );

      final roundTripped = roundTrip(drillResult);

      expect(roundTripped, drillResult);
      // 英語では声調の気づきは無い（未判定＝null のまま保存・復元される）
      expect(roundTripped.toneNotes, isNull);
      final json = DrillResultDto.fromEntity(drillResult).toJson();
      expect(json.containsKey('toneNotes'), isFalse);
      // 添削結果の保存形式は API の応答スキーマそのもの（言語名の付かないキー）
      final feedback = json['feedback'] as Map<String, dynamic>;
      expect(feedback['explanation'], '模範解答とほぼ同じ意味で問題ありません。');
      expect(feedback.containsKey('explanation_ja'), isFalse);
      expect(feedback['is_acceptable'], isTrue);
    });

    test('声調の気づき（toneNotes）を含めて往復できる', () {
      final drillResult = DrillResult(
        id: 'd-2',
        sentenceId: 'z3-001',
        language: 'zh',
        level: 3,
        spoken: '我要睡',
        timestamp: DateTime.utc(2026, 9, 5, 10),
        feedback: const CompositionFeedback(
          score: 90,
          isAcceptable: true,
          corrected: '我要水',
          correctedReading: 'wǒ yào shuǐ',
          explanation: '解説',
          comparison: '比較',
        ),
        toneNotes: const [
          ToneNote(
            index: 2,
            spokenIndex: 2,
            hanzi: '水',
            expected: 'shuǐ',
            actual: 'shuì',
            expectedTone: 3,
            actualTone: 4,
          ),
        ],
      );

      final roundTripped = roundTrip(drillResult);

      expect(roundTripped, drillResult);
      expect(roundTripped.feedback.correctedReading, 'wǒ yào shuǐ');
      expect(roundTripped.toneNotes, hasLength(1));
      expect(roundTripped.toneNotes!.single.hanzi, '水');
      // 指摘なし（空リスト）と未判定（null）は区別して保存される
      final checked = roundTrip(
        DrillResult(
          id: 'd-3',
          sentenceId: 'z3-001',
          language: 'zh',
          level: 3,
          spoken: '我要水',
          timestamp: DateTime.utc(2026, 9, 5, 10),
          feedback: drillResult.feedback,
          toneNotes: const [],
        ),
      );
      expect(checked.toneNotes, isEmpty);
    });

    test('語区切り（corrected_words / spoken_words）を含めて往復できる', () {
      const feedback = CompositionFeedback(
        score: 80,
        isAcceptable: true,
        corrected: '我要水。',
        correctedWords: [
          WordUnit(text: '我', reading: 'wǒ'),
          WordUnit(text: '要', reading: 'yào'),
          WordUnit(text: '水', reading: 'shuǐ'),
          WordUnit(text: '。', reading: ''),
        ],
        spokenWords: [
          WordUnit(text: '我'),
          WordUnit(text: '要'),
          WordUnit(text: '睡'),
        ],
        correctedReading: 'wǒ yào shuǐ',
        explanation: '解説',
        comparison: '比較',
      );

      final roundTripped = CompositionFeedbackDto.fromJson(
        CompositionFeedbackDto.fromEntity(feedback).toJson(),
      ).toEntity();

      expect(roundTripped, feedback);
      expect(roundTripped.correctedWords!.first.reading, 'wǒ');
      // 発話側はピンインを持たない
      expect(roundTripped.spokenWords!.first.reading, isNull);
    });

    test('corrected_reading が無い応答では語ごとのピンインを繋いで読みにする', () {
      final feedback = CompositionFeedbackDto.fromJson(const {
        'score': 80,
        'is_acceptable': true,
        'corrected': '我要水。',
        'corrected_words': [
          {'hanzi': '我要', 'pinyin': 'wǒ yào'},
          {'hanzi': '水', 'pinyin': 'shuǐ'},
          {'hanzi': '。', 'pinyin': ''},
        ],
        'spoken_words': ['我要', '睡'],
        'explanation': '',
        'comparison': '',
      }).toEntity();

      expect(feedback.correctedReading, 'wǒ yào shuǐ');
      expect(feedback.spokenWords, const [
        WordUnit(text: '我要'),
        WordUnit(text: '睡'),
      ]);
    });

    test('英語の応答（語区切り無し）では読み・語区切りが null になる', () {
      final feedback = CompositionFeedbackDto.fromJson(const {
        'score': 70,
        'is_acceptable': true,
        'corrected': 'ok',
        'explanation': '',
        'comparison': '',
      }).toEntity();

      expect(feedback.correctedReading, isNull);
      expect(feedback.correctedWords, isNull);
      expect(feedback.spokenWords, isNull);
    });
  });

  group('MonologueResult', () {
    test('Entity → DTO → JSON → Entity で往復できる', () {
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
              reason: '過去の話なので過去形が適切です。',
            ),
          ],
          usefulPhrases: [
            UsefulPhrase(target: 'It slipped my mind.', ja: 'うっかり忘れていた'),
          ],
          overallFeedback: '発話量が十分で内容も明確でした。時制に注意しましょう。',
        ),
      );

      final json = MonologueResultDto.fromEntity(monologueResult).toJson();
      final roundTripped = MonologueResultDto.fromJson(json).toEntity();

      expect(roundTripped, monologueResult);
      final feedback = json['feedback'] as Map<String, dynamic>;
      expect(feedback['overall_feedback'], isNotEmpty);
      expect(
        (feedback['corrections'] as List).single,
        containsPair('reason', '過去の話なので過去形が適切です。'),
      );
    });
  });

  group('SrsItem', () {
    test('Entity → DTO → JSON → Entity で往復できる', () {
      final srsItem = SrsItem(
        sentenceId: 's700-001',
        language: 'en',
        level: 700,
        stage: 2,
        dueDate: DateTime.utc(2026, 8, 10),
        lapses: 1,
        lastResult: true,
      );

      final roundTripped = SrsItemDto.fromJson(
        SrsItemDto.fromEntity(srsItem).toJson(),
      ).toEntity();

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
    test('Entity → DTO → JSON → Entity で往復できる', () {
      final phrase = Phrase(
        id: 'p-1',
        target: 'It slipped my mind.',
        ja: 'うっかり忘れていた',
        source: 'monologue',
        createdAt: DateTime.utc(2026, 8, 3),
      );

      final roundTripped = PhraseDto.fromJson(
        PhraseDto.fromEntity(phrase).toJson(),
      ).toEntity();

      expect(roundTripped, phrase);
    });
  });
}
