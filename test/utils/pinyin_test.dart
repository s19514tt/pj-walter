// ピンインの音節分割・声調抽出・声調差分（utils/pinyin.dart）のユニットテスト。
//
// 音節分割のケースは教材の実データ（assets/data/zh/sentences_*.json の reading）
// から取っている。語ごとに連結された表記・スペース区切り・儿化・jue/xue・軽声を含む。

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/models/drill_result.dart';
import 'package:pj_walter/models/learning_language.dart';
import 'package:pj_walter/models/sentence.dart';
import 'package:pj_walter/models/tone_note.dart';
import 'package:pj_walter/utils/pinyin.dart';
import 'package:pj_walter/utils/word_diff.dart';

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
      // 番号表記は表示用（raw）に記号付きへ直す
      expect(
        parsePinyinSyllables(
          'wo3 zong3 shi4 zai4 tong2 yi4 jia1 dian4 mai3 lv4 ma5',
        ).map((s) => s.raw),
        [
          'wǒ',
          'zǒng',
          'shì',
          'zài',
          'tóng',
          'yì',
          'jiā',
          'diàn',
          'mǎi',
          'lǜ',
          'ma',
        ],
      );
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
          spokenIndex: 2,
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

    test('ガード1: 綴りが対応しない音節には何も言わず、対応した音節だけ声調を比べる', () {
      // 語数が違っても、綴りが一致した音節は比較する（le は対応先が無いので無視）
      expect(
        compareTones(expected: 'Wǒ yào shuǐ', actual: 'wǒ yào shuǐ le'),
        isEmpty,
      );
      expect(
        compareTones(
          expected: 'Wǒ yào shuǐ',
          actual: 'wǒ yào shuì le',
        )!.map((n) => (n.index, n.spokenIndex, n.actual)),
        [(2, 2, 'shuì')],
      );
      // 音節が抜けていても残りは比較する
      expect(compareTones(expected: 'Wǒ yào shuǐ', actual: 'wǒ shuǐ'), isEmpty);
      // 綴りが崩れた音節（shǔ）には何も言わない。崩れていない wó の声調差だけ残る
      expect(
        compareTones(expected: 'Wǒ yào shuǐ', actual: 'wǒ yào shǔ'),
        isEmpty,
      );
      final notes = compareTones(
        expected: 'Wǒ yào shuǐ',
        actual: 'wó yào shǔ',
      )!;
      expect(notes.map((n) => n.expected), ['wǒ']);
      // 語順が違っても、綴りが一致した音節は比較する（スクリーンショットの事例）
      final reordered = compareTones(
        expected: 'Zhè ge wǒ yào liǎng ge',
        actual: 'wǒ yào liàng ge zhè ge',
      )!;
      expect(
        reordered.map((n) => (n.index, n.spokenIndex, n.expected, n.actual)),
        [(4, 2, 'liǎng', 'liàng')],
      );
      // 空なら判定しない（null）
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

    test('儿化を含む文でも対応する漢字を付ける', () {
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
      expect(notes.single.hanzi, '回');
      expect(notes.single.expected, 'huí');
      expect(notes.single.actual, 'huì');
    });

    test('指摘なしは空リスト。語順が違っても対応する漢字を模範解答側から付ける', () {
      expect(
        toneNotesFor(
          profile: LanguageProfile.chinese,
          sentence: _zhSentence(reading: 'Wǒ yào shuǐ'),
          spokenReading: 'wǒ yào shuǐ',
        ),
        isEmpty,
      );
      final notes = toneNotesFor(
        profile: LanguageProfile.chinese,
        sentence: _zhSentence(
          reading: 'Zhè ge wǒ yào liǎng ge',
          target: '这个我要两个。',
        ),
        spokenReading: 'wǒ yào liàng ge zhè ge',
      )!;
      expect(notes.single.hanzi, '两');
      expect(notes.single.spokenIndex, 2);
    });
  });

  group('alignReading', () {
    List<String> tokens(String text) => text.split('');

    test('漢字1文字ずつにルビを割り当て、句読点は null', () {
      final aligned = alignReading(
        tokens: tokens('我要水。'),
        reading: 'Wǒ yào shuǐ',
      );
      expect(aligned, [
        const TokenReading(reading: 'wǒ', syllableIndex: 0),
        const TokenReading(reading: 'yào', syllableIndex: 1),
        const TokenReading(reading: 'shuǐ', syllableIndex: 2),
        null,
      ]);
    });

    test('儿化は「点」に diǎn、「儿」に r を付けて同じ音節番号にする', () {
      final aligned = alignReading(
        tokens: tokens('你早点儿回家休息吧。'),
        reading: 'Nǐ zǎo diǎnr huíjiā xiūxi ba',
      )!;
      expect(aligned[2], const TokenReading(reading: 'diǎn', syllableIndex: 2));
      expect(aligned[3], const TokenReading(reading: 'r', syllableIndex: 2));
      expect(aligned[4], const TokenReading(reading: 'huí', syllableIndex: 3));
      expect(aligned.last, isNull);
      // 这儿 / 一会儿
      final zher = alignReading(
        tokens: tokens('这儿有人吗'),
        reading: 'Zhèr yǒurén ma',
      )!;
      expect(zher.map((t) => t?.reading), ['zhè', 'r', 'yǒu', 'rén', 'ma']);
      final huir = alignReading(
        tokens: tokens('我一会儿看一下'),
        reading: 'Wǒ yíhuìr kàn yíxià',
      )!;
      expect(huir.map((t) => t?.reading), [
        'wǒ',
        'yí',
        'huì',
        'r',
        'kàn',
        'yí',
        'xià',
      ]);
    });

    test('漢字数と音節数が合わないときは null（位置のずれたルビを出さない）', () {
      expect(alignReading(tokens: tokens('我要水'), reading: 'wǒ yào'), isNull);
      expect(
        alignReading(tokens: tokens('我要'), reading: 'wǒ yào shuǐ'),
        isNull,
      );
      expect(alignReading(tokens: tokens('我要水'), reading: ''), isNull);
    });

    test('toneNotesFor は儿化を含む文でも対応する漢字（点儿）を付ける', () {
      final notes = toneNotesFor(
        profile: LanguageProfile.chinese,
        sentence: _zhSentence(
          reading: 'Nǐ zǎo diǎnr huíjiā xiūxi ba',
          target: '你早点儿回家休息吧。',
        ),
        spokenReading: 'nǐ zǎo diànr huíjiā xiūxi ba',
      )!;
      expect(notes.single.hanzi, '点儿');
      expect(notes.single.expected, 'diǎnr');
      expect(notes.single.actual, 'diànr');
    });
  });

  group('toneMarked', () {
    test('a・e 優先、ou は o、それ以外は最後の母音に記号を付ける', () {
      expect(toneMarked('xiao', 3), 'xiǎo');
      expect(toneMarked('xie', 4), 'xiè');
      expect(toneMarked('dou', 1), 'dōu');
      expect(toneMarked('hui', 2), 'huí');
      expect(toneMarked('liu', 2), 'liú');
      expect(toneMarked('nv', 3), 'nǚ');
      expect(toneMarked('lve', 4), 'lüè');
      expect(toneMarked('dianr', 3), 'diǎnr');
      expect(toneMarked('er', 4), 'èr');
      expect(toneMarked('ma', neutralTone), 'ma');
    });
  });

  group('alignWordReadings', () {
    List<String> tokens(String text) =>
        diffWords(text, text).map((s) => s.text).toList();

    test('語ごとにルビを割り当てる', () {
      final readings = alignWordReadings(
        tokens: tokens('我要水。'),
        words: const [
          WordUnit(text: '我要', reading: 'wǒ yào'),
          WordUnit(text: '水', reading: 'shuǐ'),
          WordUnit(text: '。', reading: ''),
        ],
      )!;

      expect(readings.map((r) => r?.reading), ['wǒ', 'yào', 'shuǐ', null]);
    });

    test('音節数が合わない語だけルビが落ちる（ほかの語は残る）', () {
      final readings = alignWordReadings(
        tokens: tokens('请重新说明'),
        words: const [
          WordUnit(text: '请', reading: 'qǐng'),
          WordUnit(text: '重新', reading: 'chóng xīn'),
          // 1音節多い
          WordUnit(text: '说明', reading: 'shuō míng bái'),
        ],
      )!;

      expect(readings.map((r) => r?.reading), [
        'qǐng',
        'chóng',
        'xīn',
        null,
        null,
      ]);
    });

    test('儿化は語の中でも「点」と「儿」に分けて付く', () {
      final readings = alignWordReadings(
        tokens: tokens('早点儿'),
        words: const [WordUnit(text: '早点儿', reading: 'zǎo diǎnr')],
      )!;

      expect(readings.map((r) => r?.reading), ['zǎo', 'diǎn', 'r']);
    });

    test('語を繋いだ文字列が本文と違えば null（呼び出し側は文全体の割り当てに戻す）', () {
      expect(
        alignWordReadings(
          tokens: tokens('我要水'),
          words: const [WordUnit(text: '我要', reading: 'wǒ yào')],
        ),
        isNull,
      );
    });

    test('ピンインを持たない語区切り（あなたの発話側）では null', () {
      expect(
        alignWordReadings(
          tokens: tokens('我要水'),
          words: const [
            WordUnit(text: '我要'),
            WordUnit(text: '水'),
          ],
        ),
        isNull,
      );
    });
  });
}
