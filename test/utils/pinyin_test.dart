// ピンインの音節分割・声調抽出・声調差分（utils/pinyin.dart）のユニットテスト。
//
// 音節分割のケースは教材の実データ（assets/data/zh/sentences_*.json の reading）
// から取っている。語ごとに連結された表記・スペース区切り・儿化・jue/xue・軽声を含む。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/learning_language.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/models/tone_note.dart';
import 'package:pj_walter/utils/pinyin.dart';

List<String> _bases(String pinyin) =>
    parsePinyinSyllables(pinyin).map((s) => s.base).toList();

List<int> _tones(String pinyin) =>
    parsePinyinSyllables(pinyin).map((s) => s.tone).toList();

Sentence _zhSentence({String? reading, String target = '我要水'}) => Sentence(
  id: 'z3-999',
  ja: '水がほしい。',
  target: target,
  theme: 'daily',
  tips: '',
  level: 3,
  reading: reading,
);

void main() {
  group('parsePinyinSyllables', () {
    test('語ごとに連結された教材表記（z3-001）を音節に切り、声調番号を抽出する', () {
      const reading = 'Qǐngwèn nǐ néng bāng wǒ yíxià ma';
      expect(_bases(reading), [
        'qing',
        'wen',
        'ni',
        'neng',
        'bang',
        'wo',
        'yi',
        'xia',
        'ma',
      ]);
      expect(_tones(reading), [3, 4, 3, 2, 1, 3, 2, 4, neutralTone]);
    });

    test('音節スペース区切りでも連結表記でも同じ結果になる', () {
      expect(
        parsePinyinSyllables('wǒ yào shuǐ'),
        parsePinyinSyllables('wǒyàoshuǐ'),
      );
      expect(_bases('wǒ yào shuǐ'), ['wo', 'yao', 'shui']);
      expect(_tones('wǒ yào shuǐ'), [3, 4, 3]);
    });

    test('儿化の r を同じ音節に取り込む（z3-015 / z3-022 / z3-060 / z3-197）', () {
      expect(_bases('Nǐ zǎo diǎnr huíjiā xiūxi ba'), [
        'ni',
        'zao',
        'dianr',
        'hui',
        'jia',
        'xiu',
        'xi',
        'ba',
      ]);
      expect(_bases('Nǐmen zhèr shénme cài hǎochī'), [
        'ni',
        'men',
        'zher',
        'shen',
        'me',
        'cai',
        'hao',
        'chi',
      ]);
      expect(_bases('Wǒ yíhuìr zài dǎ gěi nǐ'), [
        'wo',
        'yi',
        'huir',
        'zai',
        'da',
        'gei',
        'ni',
      ]);
      expect(_bases('Zhè cì lǚyóu wǒ wánr de hěn gāoxìng'), [
        'zhe',
        'ci',
        'lv',
        'you',
        'wo',
        'wanr',
        'de',
        'hen',
        'gao',
        'xing',
      ]);
    });

    test('r の後ろに母音が続く場合は儿化ではなく次の音節の声母として扱う', () {
      // 有人 yǒurén: you + ren（"your" + "en" ではない）
      expect(_bases('Zhèr yǒurén ma'), ['zher', 'you', 'ren', 'ma']);
      // 二 èr は韻母 er そのもの
      expect(_bases('shí èr diǎn'), ['shi', 'er', 'dian']);
    });

    test('j/q/x/y の後ろの ue（=üe）と、ü・ǚ・ǜ を扱う（z3-099 / z4-119）', () {
      expect(_bases('Wǒ juéde yǒudiǎnr nán'), [
        'wo',
        'jue',
        'de',
        'you',
        'dianr',
        'nan',
      ]);
      expect(_tones('Wǒ juéde yǒudiǎnr nán'), [3, 2, neutralTone, 3, 3, 2]);
      expect(_bases('xuéxiào'), ['xue', 'xiao']);
      expect(_bases('Wǒmen chóngxīn kǎolǜ yíxià'), [
        'wo',
        'men',
        'chong',
        'xin',
        'kao',
        'lv',
        'yi',
        'xia',
      ]);
      expect(_tones('kǎolǜ'), [3, 4]);
      expect(_bases('nǚ'), ['nv']);
    });

    test('記号なしの音節は軽声（tone 5）になる（z3-002 の 事情 shìqing）', () {
      final syllables = parsePinyinSyllables('Wǒ xiǎng wèn nǐ yí jiàn shìqing');
      expect(syllables.map((s) => s.base), [
        'wo',
        'xiang',
        'wen',
        'ni',
        'yi',
        'jian',
        'shi',
        'qing',
      ]);
      expect(syllables.last.tone, neutralTone);
      expect(syllables.last.isNeutral, isTrue);
      expect(syllables.first.isNeutral, isFalse);
    });

    test('文頭が大文字の声調付き母音でも扱える（z4-285 Ànzhào）', () {
      expect(_bases('Ànzhào nǐmen de shíjiān ānpái jiù xíng'), [
        'an',
        'zhao',
        'ni',
        'men',
        'de',
        'shi',
        'jian',
        'an',
        'pai',
        'jiu',
        'xing',
      ]);
      expect(_tones('Ànzhào'), [4, 4]);
    });

    test('句読点（全角含む）・アポストロフィ・ハイフンは除去され、rawは小文字になる', () {
      final syllables = parsePinyinSyllables(
        "Qǐngwèn， nǐ néng bāng wǒ yí'xià ma？!",
      );
      expect(syllables.map((s) => s.base), [
        'qing',
        'wen',
        'ni',
        'neng',
        'bang',
        'wo',
        'yi',
        'xia',
        'ma',
      ]);
      expect(syllables.first.raw, 'qǐng');
      expect(_bases('xī-ān'), ['xi', 'an']);
    });

    test('声調番号表記（wen4）と結合文字（NFD）の声調記号も読める', () {
      expect(_bases('wo3 yao4 shui3'), ['wo', 'yao', 'shui']);
      expect(_tones('wo3 yao4 shui3'), [3, 4, 3]);
      // u + 結合ウムラウト + 結合caron = ǚ
      expect(_bases('nǚ'), ['nv']);
      expect(_tones('nǚ'), [3]);
      // i + 結合macron = ī
      expect(_tones('jīn'), [1]);
    });

    test('空文字は空リスト', () {
      expect(parsePinyinSyllables(''), isEmpty);
      expect(parsePinyinSyllables('  ，。 '), isEmpty);
    });

    test('教材の全 reading が空でない音節列に分割でき、各音節の綴りが韻母表で終わる', () {
      // 教材アセットの読み込みは chinese_deck_test に任せ、ここでは代表的な
      // 綴りパターンが崩れないことだけ見る。
      for (final reading in const [
        'Wǒmen sān diǎn zài huǒchēzhàn jiànmiàn ba',
        'Zhè ge huìyì néngbunéng tuīchí dào xià gè xīngqī',
        'Yǒudiǎnr là búguò hěn zhídé cháng yi cháng',
        'Nǐ míngtiān xiàwǔ yǒu shíjiān ma',
      ]) {
        final syllables = parsePinyinSyllables(reading);
        expect(syllables, isNotEmpty, reason: reading);
        for (final s in syllables) {
          expect(s.base, matches(RegExp(r'^[a-z]+$')), reason: '$reading / $s');
          expect(s.base.length, greaterThan(1), reason: '$reading / $s');
        }
      }
    });
  });

  group('compareTones', () {
    test('完全一致なら空リスト（指摘なし）', () {
      expect(
        compareTones(expected: 'Wǒ yào shuǐ', actual: 'wǒ yào shuǐ'),
        isEmpty,
      );
      // 連結表記 vs スペース区切りでも一致とみなす
      expect(
        compareTones(expected: 'Qǐngwèn nǐ', actual: 'qǐng wèn nǐ'),
        isEmpty,
      );
    });

    test('綴りが同じで声調だけ違う音節を、期待・実測の両方を付けて返す', () {
      final notes = compareTones(
        expected: 'Wǒ yào shuǐ',
        actual: 'wǒ yào shuì',
      );
      expect(notes, [
        const ToneNote(
          index: 2,
          expected: 'shuǐ',
          actual: 'shuì',
          expectedTone: 3,
          actualTone: 4,
        ),
      ]);
    });

    test('複数の不一致は文中の順に並ぶ', () {
      final notes = compareTones(
        expected: 'tā yào mǎi fáng zi',
        actual: 'tá yào mài fáng zi',
      )!;
      expect(notes.map((n) => n.index), [0, 2]);
      expect(notes[0].expectedTone, 1);
      expect(notes[0].actualTone, 2);
      expect(notes[1].expected, 'mǎi');
      expect(notes[1].actual, 'mài');
    });

    test('ガード2: どちらかが軽声の音節は比較せず無視する', () {
      // 喜欢: 教材 xǐhuān / 認識 xǐhuan（軽声）→ 指摘しない
      expect(
        compareTones(expected: 'wǒ xǐhuān nǐ', actual: 'wǒ xǐ huan nǐ'),
        isEmpty,
      );
      // 逆方向（期待側が軽声、実測側に声調が付いた）も指摘しない
      expect(compareTones(expected: 'yǎnjing', actual: 'yǎn jīng'), isEmpty);
      // 軽声音節を無視しても、他の音節の不一致は残る
      expect(
        compareTones(expected: 'wǒ xǐhuān nǐ', actual: 'wò xǐ huan nǐ'),
        hasLength(1),
      );
    });

    test('ガード1: 綴りの列が一致しなければ null（声調について何も言わない）', () {
      // 音節数が違う
      expect(
        compareTones(expected: 'Wǒ yào shuǐ', actual: 'wǒ yào shuǐ le'),
        isNull,
      );
      expect(compareTones(expected: 'Wǒ yào shuǐ', actual: 'wǒ shuǐ'), isNull);
      // 同じ数でも綴りが1音節ずれている（聞き取り崩壊）
      expect(
        compareTones(expected: 'Wǒ yào shuǐ', actual: 'wǒ yào shǔ'),
        isNull,
      );
      // 声調の不一致があっても、別の音節の綴りがずれていれば丸ごと null
      expect(
        compareTones(expected: 'Wǒ yào shuǐ', actual: 'wó yào shǔ'),
        isNull,
      );
      // 空
      expect(compareTones(expected: 'Wǒ yào shuǐ', actual: ''), isNull);
      expect(compareTones(expected: '', actual: 'wǒ'), isNull);
    });
  });

  group('toneNotesFor', () {
    test('英語モードでは何もしない（null）', () {
      expect(
        toneNotesFor(
          profile: LanguageProfile.english,
          sentence: _zhSentence(reading: 'Wǒ yào shuǐ'),
          spokenReading: 'wǒ yào shuì',
        ),
        isNull,
      );
    });

    test('模範解答にピンインが無い・認識ピンインが無い場合は null', () {
      expect(
        toneNotesFor(
          profile: LanguageProfile.chinese,
          sentence: _zhSentence(reading: null),
          spokenReading: 'wǒ yào shuì',
        ),
        isNull,
      );
      expect(
        toneNotesFor(
          profile: LanguageProfile.chinese,
          sentence: _zhSentence(reading: 'Wǒ yào shuǐ'),
          spokenReading: null,
        ),
        isNull,
      );
      expect(
        toneNotesFor(
          profile: LanguageProfile.chinese,
          sentence: _zhSentence(reading: 'Wǒ yào shuǐ'),
          spokenReading: '   ',
        ),
        isNull,
      );
    });

    test('漢字数と音節数が一致するときは対応する漢字を付ける', () {
      final notes = toneNotesFor(
        profile: LanguageProfile.chinese,
        sentence: _zhSentence(reading: 'Wǒ yào shuǐ', target: '我要水。'),
        spokenReading: 'wǒ yào shuì',
      );
      expect(notes, hasLength(1));
      expect(notes!.single.hanzi, '水');
      expect(notes.single.expected, 'shuǐ');
      expect(notes.single.actual, 'shuì');
    });

    test('儿化などで漢字数と音節数が一致しないときは漢字を付けない', () {
      final notes = toneNotesFor(
        profile: LanguageProfile.chinese,
        sentence: _zhSentence(
          reading: 'Nǐ zǎo diǎnr huíjiā xiūxi ba',
          target: '你早点儿回家休息吧。',
        ),
        spokenReading: 'nǐ zǎo diǎnr huìjiā xiūxi ba',
      );
      expect(notes, hasLength(1));
      expect(notes!.single.index, 3);
      expect(notes.single.hanzi, isNull);
      expect(notes.single.expected, 'huí');
      expect(notes.single.actual, 'huì');
    });

    test('指摘なしは空リスト、音節ズレは null', () {
      expect(
        toneNotesFor(
          profile: LanguageProfile.chinese,
          sentence: _zhSentence(reading: 'Wǒ yào shuǐ'),
          spokenReading: 'wǒ yào shuǐ',
        ),
        isEmpty,
      );
      expect(
        toneNotesFor(
          profile: LanguageProfile.chinese,
          sentence: _zhSentence(reading: 'Wǒ yào shuǐ'),
          spokenReading: 'wǒ yào shuǐ le',
        ),
        isNull,
      );
    });
  });
}
