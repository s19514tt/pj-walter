import 'package:flutter/foundation.dart';

import '../../../core/language/learning_language.dart';
import '../../content/domain/sentence.dart';
import 'drill_result.dart';
import 'tone_note.dart';

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

  /// 表示用の表記（声調記号つき、小文字化済み）。
  /// 声調番号表記（`wo3`）で入力された音節は記号付き（`wǒ`）に直してある
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
/// 綴りが同じで声調だけが違う音節を返す。
///
/// 2つの音節列を**声調記号を外した綴り**で最長共通部分列（LCS）整列し、
/// 対応が取れた音節どうしだけ声調を比べる（`tool/pinyin_poc` の
/// `alignSyllables` と同じ）。語順や語数が模範解答と違っても、綴りが一致した
/// 音節については声調を見られる。
///
/// - 対応が取れない音節（聞き取りの崩れ・言い回しの違い）には何も言わない
///   （ガード1: 綴りが違う音節に声調の指摘を乗せない）
/// - どちらかが軽声の音節は比較しない（ガード2: 軽声かどうかは辞書でも
///   話者でも揺れる）
/// - どちらかが空なら null（判定していない）。不一致が無ければ空リスト
///   （呼び出し側はカードを出さない: ガード3）
List<ToneNote>? compareTones({
  required String expected,
  required String actual,
}) {
  final exp = parsePinyinSyllables(expected);
  final act = parsePinyinSyllables(actual);
  if (exp.isEmpty || act.isEmpty) return null;

  // dp[i][j] = exp[i..] と act[j..] の綴りのLCS長（utils/word_diff.dart と同じ形）
  final n = exp.length;
  final m = act.length;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      dp[i][j] = exp[i].base == act[j].base
          ? dp[i + 1][j + 1] + 1
          : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }

  final notes = <ToneNote>[];
  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (exp[i].base == act[j].base) {
      final e = exp[i];
      final a = act[j];
      if (!e.isNeutral && !a.isNeutral && e.tone != a.tone) {
        notes.add(
          ToneNote(
            index: i,
            spokenIndex: j,
            expected: e.raw,
            actual: a.raw,
            expectedTone: e.tone,
            actualTone: a.tone,
          ),
        );
      }
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return notes;
}

/// 口頭作文ドリル1問分の「気づいた点」を求める。
///
/// 中国語（[LanguageProfile.readingLabel]が非null）で、[sentence]にピンインが
/// あり、文字起こしがピンイン[spokenReading]を返した場合にのみ[compareTones]を
/// 行う。それ以外（英語・ピンイン無し）は null で、呼び出し側は
/// 「判定していない」として何も表示しない。
///
/// 模範解答の漢字数と音節数が一致するときだけ、各指摘に対応する漢字を付ける
/// （儿化などで一致しない場合は付けない。位置のずれた漢字を出すより無い方が良い）。
List<ToneNote>? toneNotesFor({
  required LanguageProfile profile,
  required Sentence sentence,
  required String? spokenReading,
}) {
  if (!profile.hasReading) return null;
  final expected = sentence.reading;
  if (expected == null || expected.trim().isEmpty) return null;
  if (spokenReading == null || spokenReading.trim().isEmpty) return null;

  final notes = compareTones(expected: expected, actual: spokenReading);
  if (notes == null || notes.isEmpty) return notes;

  final characters = _cjkCharacters(sentence.target);
  final aligned = alignReading(tokens: characters, reading: expected);
  if (aligned == null) return notes;
  return [
    for (final note in notes)
      ToneNote(
        index: note.index,
        spokenIndex: note.spokenIndex,
        hanzi: [
          for (var i = 0; i < characters.length; i++)
            if (aligned[i]?.syllableIndex == note.index) characters[i],
        ].join(),
        expected: note.expected,
        actual: note.actual,
        expectedTone: note.expectedTone,
        actualTone: note.actualTone,
      ),
  ];
}

/// [alignReading]の結果1件: あるトークン（漢字）に付けるルビ。
@immutable
class TokenReading {
  const TokenReading({required this.reading, required this.syllableIndex});

  /// ルビとして表示するピンイン（声調記号つき）。儿化の「儿」には `r` だけが付く
  final String reading;

  /// 対応する音節の位置（[parsePinyinSyllables]の添字）。
  /// 儿化では「点」と「儿」が同じ音節を指す。
  final int syllableIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenReading &&
          reading == other.reading &&
          syllableIndex == other.syllableIndex;

  @override
  int get hashCode => Object.hash(reading, syllableIndex);

  @override
  String toString() => 'TokenReading($reading #$syllableIndex)';
}

/// トークン列（`utils/word_diff.dart` と同じく漢字1文字1トークン）に
/// ピンイン[reading]の音節をルビとして割り当てる。
///
/// 漢字トークンだけが音節を消費し、句読点などは null。儿化（`diǎnr`）は
/// 「点」に `diǎn`、「儿」に `r` を付けて同じ音節番号にする。
/// 漢字の数と音節の数が合わない場合は位置のずれたルビを出さず null を返す。
List<TokenReading?>? alignReading({
  required List<String> tokens,
  required String reading,
}) {
  final syllables = parsePinyinSyllables(reading);
  if (syllables.isEmpty) return null;
  final out = List<TokenReading?>.filled(tokens.length, null);
  var next = 0;
  for (var i = 0; i < tokens.length; i++) {
    if (!isCjkCharacter(tokens[i])) continue;
    if (next >= syllables.length) return null;
    final syllable = syllables[next];
    final following = _nextCjkIndex(tokens, i + 1);
    if (following != null && tokens[following] == '儿' && _isErhua(syllable)) {
      out[i] = TokenReading(
        reading: syllable.raw.substring(0, syllable.raw.length - 1),
        syllableIndex: next,
      );
      out[following] = TokenReading(reading: 'r', syllableIndex: next);
      i = following;
    } else {
      out[i] = TokenReading(reading: syllable.raw, syllableIndex: next);
    }
    next++;
  }
  if (next != syllables.length) return null;
  return out;
}

/// 語ごとにピンインが分かれているとき（添削応答の `corrected_words`）の
/// ルビ割り当て。[tokens]と同じ長さのルビ列を返す。
///
/// [alignReading]は文全体で漢字数と音節数が合わないとルビを丸ごと落とすが、
/// こちらは語ごとに突き合わせるので、合わない語だけルビ無しにできる
/// （モデルのピンインが1音節ずれただけで修正版のルビが全部消えるのを防ぐ）。
/// 語の中でしか位置を見ないので、ずれたルビが出ることはない。
///
/// 語を繋いだ文字列が[tokens]を繋いだものと一致しないとき、また語の境界が
/// トークンの途中に来るときは null（呼び出し側は[alignReading]に戻す）。
///
/// 返り値の[TokenReading.syllableIndex]は**語の中での位置**なので、
/// 声調の気づき（あなたの発話）の突き合わせには使えない。
List<TokenReading?>? alignWordReadings({
  required List<String> tokens,
  required List<WordUnit> words,
}) {
  // ピンインを持たない語区切り（あなたの発話側）ではルビを決められない
  if (!words.any((w) => w.reading != null && w.reading!.trim().isNotEmpty)) {
    return null;
  }
  final texts = [for (final word in words) word.text.replaceAll(_space, '')];
  final joined = tokens.join();
  if (joined.isEmpty || joined != texts.join()) return null;

  final out = List<TokenReading?>.filled(tokens.length, null);
  var next = 0;
  for (var w = 0; w < words.length; w++) {
    final start = next;
    var length = 0;
    while (length < texts[w].length && next < tokens.length) {
      length += tokens[next].length;
      next++;
    }
    // 語の境界がトークンの途中に来た（語区切りとトークン化が食い違う）
    if (length != texts[w].length) return null;
    final reading = words[w].reading;
    if (reading == null || reading.trim().isEmpty) continue;
    final slice = tokens.sublist(start, next);
    final aligned = alignReading(tokens: slice, reading: reading);
    // 合わない語はルビ無し（この語だけ落とす）
    if (aligned == null) continue;
    for (var i = 0; i < slice.length; i++) {
      out[start + i] = aligned[i];
    }
  }
  return out;
}

/// 1文字のCJK漢字かどうか（差分トークンの判定用）。
bool isCjkCharacter(String token) => _cjkToken.hasMatch(token);

int? _nextCjkIndex(List<String> tokens, int from) {
  for (var i = from; i < tokens.length; i++) {
    if (isCjkCharacter(tokens[i])) return i;
  }
  return null;
}

/// 儿化音節（`dianr` / `zher` / `huir`）かどうか。韻母 `er` そのものは除く。
bool _isErhua(PinyinSyllable syllable) =>
    syllable.base.length > 2 &&
    syllable.base != 'er' &&
    syllable.base.endsWith('r') &&
    syllable.raw.endsWith('r');

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
  final baseText = base.toString();
  final hasDigit = chars.any((c) => _isDigit(c.plain));
  return PinyinSyllable(
    base: baseText,
    tone: tone,
    // 番号表記は表示用に記号付きへ直す（ルビに「wo3」を出さない）
    raw: hasDigit ? toneMarked(baseText, tone) : raw.toString(),
  );
}

/// 声調記号を付ける母音の候補（声調番号→記号）。
const _toneMarks = <String, List<String>>{
  'a': ['ā', 'á', 'ǎ', 'à'],
  'o': ['ō', 'ó', 'ǒ', 'ò'],
  'e': ['ē', 'é', 'ě', 'è'],
  'i': ['ī', 'í', 'ǐ', 'ì'],
  'u': ['ū', 'ú', 'ǔ', 'ù'],
  'v': ['ǖ', 'ǘ', 'ǚ', 'ǜ'],
};

/// 素の綴り[base]（`v` は ü）に声調番号[tone]の記号を付けた表記を返す。
///
/// 記号の位置は標準の規則: a・e があればそこ、`ou` なら o、それ以外は最後の母音。
/// 軽声（[neutralTone]）は記号なし。
String toneMarked(String base, int tone) {
  final plain = base.replaceAll('v', 'ü');
  if (tone < 1 || tone > 4) return plain;
  int at;
  if (base.contains('a')) {
    at = base.indexOf('a');
  } else if (base.contains('e')) {
    at = base.indexOf('e');
  } else if (base.contains('ou')) {
    at = base.indexOf('o');
  } else {
    at = base.lastIndexOf(RegExp('[iouv]'));
  }
  if (at < 0) return plain;
  final marked = _toneMarks[base[at]]![tone - 1];
  return '${plain.substring(0, at)}$marked${plain.substring(at + 1)}';
}

bool _isDigit(String s) =>
    s.length == 1 && s.codeUnitAt(0) >= 0x31 && s.codeUnitAt(0) <= 0x35;

final _space = RegExp(r'\s');
final _cjk = RegExp(r'[㐀-䶿一-鿿]');
final _cjkToken = RegExp(r'^[㐀-䶿一-鿿]$');

/// 文中のCJK漢字だけを1文字ずつ取り出す（句読点・数字は除く）。
List<String> _cjkCharacters(String text) =>
    _cjk.allMatches(text).map((m) => m.group(0)!).toList();
