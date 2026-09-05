import 'package:flutter/foundation.dart';

import '../models/learning_language.dart';
import '../models/sentence.dart';
import '../models/tone_note.dart';

/// ピンインの音節分割・声調抽出・声調差分（DESIGN.md「声調フィードバック」参照）。
///
/// 外部パッケージは使わず、`tool/pinyin_poc/poc.js`（ブランチ
/// `claude/chinese-hanzi-pinyin-output-n0pzxe`）の検証済み実装を移植したもの。
/// 語ごとに連結された表記（`Qǐngwèn`）と音節スペース区切り（`qǐng wèn`）の
/// 両方を扱い、声調記号つき母音を「素の母音＋声調番号」に分解する。
///
/// ここでの比較はすべて決定的なローカル処理で、Geminiに声調の正誤を
/// 判定させることはしない（聞くと作り話が返る）。

/// 軽声（声調記号なし）を表す声調番号。
const neutralTone = 5;

/// ピンイン1音節分。
@immutable
class PinyinSyllable {
  const PinyinSyllable({
    required this.base,
    required this.tone,
    required this.raw,
  });

  /// 声調記号を外した綴り（小文字。`ü` は `v` で表す。儿化の `r` を含む）
  final String base;

  /// 声調番号（1〜4）。記号が無ければ[neutralTone]
  final int tone;

  /// 元の表記（声調記号つき、小文字化済み。表示用）
  final String raw;

  /// 軽声（声調記号なし）かどうか
  bool get isNeutral => tone == neutralTone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PinyinSyllable &&
          base == other.base &&
          tone == other.tone &&
          raw == other.raw;

  @override
  int get hashCode => Object.hash(base, tone, raw);

  @override
  String toString() => 'PinyinSyllable($raw = $base$tone)';
}

/// ピンイン文字列を音節に分割する。
///
/// 大文字小文字は無視し、句読点（全角含む）・アポストロフィ・ハイフンは
/// 区切りとして扱う。`wen4` のような声調番号表記も受け付ける。
/// 綴りとして解釈できない文字は1文字を1音節として前進する
/// （その結果、模範解答と綴り列が一致せずガード1で弾かれる）。
List<PinyinSyllable> parsePinyinSyllables(String pinyin) {
  final syllables = <PinyinSyllable>[];
  for (final word in _splitWords(pinyin)) {
    syllables.addAll(_splitWord(word));
  }
  return syllables;
}

/// 模範解答のピンイン[expected]と認識ピンイン[actual]を音節ごとに比較し、
/// 声調だけが違う音節を返す。
///
/// - 声調記号を外した綴りの列が完全一致しない場合は null（ガード1:
///   聞き取り失敗や言い回しの違いに声調の指摘を乗せない）
/// - どちらかが軽声の音節は比較しない（ガード2: 軽声かどうかは辞書でも
///   話者でも揺れる）
/// - 不一致が無ければ空リスト（呼び出し側はカードを出さない: ガード3）
List<ToneNote>? compareTones({
  required String expected,
  required String actual,
}) {
  final expectedSyllables = parsePinyinSyllables(expected);
  final actualSyllables = parsePinyinSyllables(actual);
  if (expectedSyllables.isEmpty ||
      expectedSyllables.length != actualSyllables.length) {
    return null;
  }
  for (var i = 0; i < expectedSyllables.length; i++) {
    if (expectedSyllables[i].base != actualSyllables[i].base) return null;
  }

  final notes = <ToneNote>[];
  for (var i = 0; i < expectedSyllables.length; i++) {
    final exp = expectedSyllables[i];
    final act = actualSyllables[i];
    if (exp.isNeutral || act.isNeutral) continue;
    if (exp.tone == act.tone) continue;
    notes.add(
      ToneNote(
        index: i,
        expected: exp.raw,
        actual: act.raw,
        expectedTone: exp.tone,
        actualTone: act.tone,
      ),
    );
  }
  return notes;
}

/// 口頭作文ドリル1問分の「気づいた点」を求める。
///
/// 中国語（[LanguageProfile.readingLabel]が非null）で、[sentence]にピンインが
/// あり、文字起こしがピンイン[spokenReading]を返した場合にのみ[compareTones]を
/// 行う。それ以外（英語・ピンイン無し・音節列不一致）はすべて null で、
/// 呼び出し側は「判定していない」として何も表示しない。
///
/// 模範解答の漢字数と音節数が一致するときだけ、各指摘に対応する漢字を付ける
/// （儿化などで一致しない場合は付けない。位置のずれた漢字を出すより無い方が良い）。
List<ToneNote>? toneNotesFor({
  required LanguageProfile profile,
  required Sentence sentence,
  required String? spokenReading,
}) {
  if (profile.readingLabel == null) return null;
  final expected = sentence.reading;
  if (expected == null || expected.trim().isEmpty) return null;
  if (spokenReading == null || spokenReading.trim().isEmpty) return null;

  final notes = compareTones(expected: expected, actual: spokenReading);
  if (notes == null || notes.isEmpty) return notes;

  final hanzi = _cjkCharacters(sentence.target);
  if (hanzi.length != parsePinyinSyllables(expected).length) return notes;
  return [
    for (final note in notes)
      ToneNote(
        index: note.index,
        hanzi: hanzi[note.index],
        expected: note.expected,
        actual: note.actual,
        expectedTone: note.expectedTone,
        actualTone: note.actualTone,
      ),
  ];
}

// ---------------------------------------------------------------------------
// 内部実装
// ---------------------------------------------------------------------------

/// 声調記号つき母音 → (素の母音, 声調番号)。声調を持たない `ü`/`ê` は null。
/// 文頭が大文字になる教材データ（`Ànzhào`）のために大文字も含める。
const _accents = <String, (String, int?)>{
  'ā': ('a', 1),
  'á': ('a', 2),
  'ǎ': ('a', 3),
  'à': ('a', 4),
  'ē': ('e', 1),
  'é': ('e', 2),
  'ě': ('e', 3),
  'è': ('e', 4),
  'ī': ('i', 1),
  'í': ('i', 2),
  'ǐ': ('i', 3),
  'ì': ('i', 4),
  'ō': ('o', 1),
  'ó': ('o', 2),
  'ǒ': ('o', 3),
  'ò': ('o', 4),
  'ū': ('u', 1),
  'ú': ('u', 2),
  'ǔ': ('u', 3),
  'ù': ('u', 4),
  'ǖ': ('v', 1),
  'ǘ': ('v', 2),
  'ǚ': ('v', 3),
  'ǜ': ('v', 4),
  'ń': ('n', 2),
  'ň': ('n', 3),
  'ǹ': ('n', 4),
  'ê': ('e', null),
  'ü': ('v', null),
  'Ā': ('a', 1),
  'Á': ('a', 2),
  'Ǎ': ('a', 3),
  'À': ('a', 4),
  'Ē': ('e', 1),
  'É': ('e', 2),
  'Ě': ('e', 3),
  'È': ('e', 4),
  'Ī': ('i', 1),
  'Í': ('i', 2),
  'Ǐ': ('i', 3),
  'Ì': ('i', 4),
  'Ō': ('o', 1),
  'Ó': ('o', 2),
  'Ǒ': ('o', 3),
  'Ò': ('o', 4),
  'Ū': ('u', 1),
  'Ú': ('u', 2),
  'Ǔ': ('u', 3),
  'Ù': ('u', 4),
  'Ǖ': ('v', 1),
  'Ǘ': ('v', 2),
  'Ǚ': ('v', 3),
  'Ǜ': ('v', 4),
  'Ê': ('e', null),
  'Ü': ('v', null),
};

/// 結合文字（NFD形式）の声調記号。母音の直後に付く。
const _combiningTones = <int, int>{
  0x0304: 1, // macron
  0x0301: 2, // acute
  0x030C: 3, // caron
  0x0300: 4, // grave
};

/// 結合文字のウムラウト（`u` + U+0308 = `ü`）。
const _combiningDiaeresis = 0x0308;

/// 声母。長いものを先に試す。空文字（声母なし）は最後。
const _initials = [
  'zh',
  'ch',
  'sh',
  'b',
  'p',
  'm',
  'f',
  'd',
  't',
  'n',
  'l',
  'g',
  'k',
  'h',
  'j',
  'q',
  'x',
  'r',
  'z',
  'c',
  's',
  'y',
  'w',
  '',
];

/// 韻母。長いものから貪欲にマッチさせる（`_initFinals`で長さ順に整列）。
/// j/q/x/y の後ろでは ü を u と綴るため、`üe` に加えて `ue` も含める
/// （`üan`→`uan`、`ün`→`un` は既存の綴りと同形）。`v` は ü の内部表記。
const _finalsUnsorted = [
  'iang',
  'iong',
  'uang',
  'ueng',
  'van',
  'uai',
  'uan',
  'ian',
  'iao',
  'ang',
  'eng',
  'ing',
  'ong',
  've',
  'ue',
  'ai',
  'ei',
  'ao',
  'ou',
  'an',
  'en',
  'er',
  'ia',
  'ie',
  'iu',
  'in',
  'ua',
  'uo',
  'ui',
  'un',
  'vn',
  'io',
  'a',
  'o',
  'e',
  'i',
  'u',
  'v',
];

final List<String> _finals = List.of(_finalsUnsorted)
  ..sort((a, b) => b.length.compareTo(a.length));

const _vowels = 'aeiouv';

/// 1文字分の正規化結果（元の表記・素の文字・声調）。
class _Char {
  _Char({required this.raw, required this.plain, required this.tone});

  String raw;
  String plain;
  int? tone;
}

/// 文字列を「語」に分割する。空白・句読点・アポストロフィ・ハイフンなど、
/// ピンインの綴りに使わない文字はすべて区切りとみなす。
/// 各語は[_Char]の列（声調記号を素の文字＋声調に分解済み）になる。
List<List<_Char>> _splitWords(String text) {
  final words = <List<_Char>>[];
  var current = <_Char>[];

  void flush() {
    if (current.isNotEmpty) words.add(current);
    current = <_Char>[];
  }

  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    final accent = _accents[ch];
    if (accent != null) {
      current.add(_Char(raw: ch, plain: accent.$1, tone: accent.$2));
    } else if (_combiningTones.containsKey(rune)) {
      // NFD形式: 直前の文字に声調を付ける
      if (current.isNotEmpty) {
        current.last
          ..raw += ch
          ..tone = _combiningTones[rune];
      }
    } else if (rune == _combiningDiaeresis) {
      if (current.isNotEmpty) {
        current.last.raw += ch;
        if (current.last.plain == 'u') current.last.plain = 'v';
      }
    } else if ((rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A)) {
      final lower = ch.toLowerCase();
      current.add(_Char(raw: lower, plain: lower, tone: null));
    } else if (rune >= 0x31 && rune <= 0x35) {
      // 声調番号表記（wen4）。区切りではなく語の一部
      current.add(_Char(raw: ch, plain: ch, tone: null));
    } else {
      flush();
    }
  }
  flush();
  return words;
}

/// 1語を音節に切る（声母＋最長の韻母の貪欲マッチ）。
List<PinyinSyllable> _splitWord(List<_Char> chars) {
  final out = <PinyinSyllable>[];
  var i = 0;

  bool matches(int at, String s) {
    if (at + s.length > chars.length) return false;
    for (var k = 0; k < s.length; k++) {
      if (chars[at + k].plain != s[k]) return false;
    }
    return true;
  }

  bool isToneDigit(int at) => at < chars.length && _isDigit(chars[at].plain);

  while (i < chars.length) {
    int? end;
    for (final initial in _initials) {
      if (!matches(i, initial)) continue;
      final j = i + initial.length;
      for (final finalPart in _finals) {
        if (!matches(j, finalPart)) continue;
        var k = j + finalPart.length;
        // 儿化: 後ろに r が続き、その次が母音でなければ取り込む
        if (finalPart != 'er' &&
            k < chars.length &&
            chars[k].plain == 'r' &&
            (k + 1 >= chars.length || !_vowels.contains(chars[k + 1].plain))) {
          k++;
        }
        // 声調番号表記（wen4）を同じ音節に取り込む
        if (isToneDigit(k)) k++;
        end = k;
        break;
      }
      if (end != null) break;
    }
    // 切れない文字はそのまま1音節扱いにして前進する
    end ??= i + 1;

    final slice = chars.sublist(i, end);
    final syllable = _toSyllable(slice);
    if (syllable != null) out.add(syllable);
    i = end;
  }
  return out;
}

PinyinSyllable? _toSyllable(List<_Char> chars) {
  final base = StringBuffer();
  final raw = StringBuffer();
  var tone = neutralTone;
  for (final c in chars) {
    raw.write(c.raw);
    if (_isDigit(c.plain)) {
      tone = int.parse(c.plain);
      continue;
    }
    base.write(c.plain);
    if (c.tone != null) tone = c.tone!;
  }
  if (base.isEmpty) return null;
  return PinyinSyllable(base: base.toString(), tone: tone, raw: raw.toString());
}

bool _isDigit(String s) =>
    s.length == 1 && s.codeUnitAt(0) >= 0x31 && s.codeUnitAt(0) <= 0x35;

final _cjk = RegExp(r'[㐀-䶿一-鿿]');

/// 文中のCJK漢字だけを1文字ずつ取り出す（句読点・数字は除く）。
List<String> _cjkCharacters(String text) =>
    _cjk.allMatches(text).map((m) => m.group(0)!).toList();
