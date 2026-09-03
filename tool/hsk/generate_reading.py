#!/usr/bin/env python3
"""教材JSONに拼音(reading)を書き込む。

pypinyin の語句単位の多音字解決を土台に、中国語教育上まちがえられない
以下を規則で補正する。pypinyin の素の出力は「一」「不」の変調をほぼ行わず、
頻出語の軽声も反映しないため、そのままでは音読教材に使えない。

  1. 軽声（事情 shìqing / 时候 shíhou / 谢谢 xièxie …）
  2. 「一」の変調
       - 動詞重ね型 A一A（说一说・想一想）→ 軽声 yi
       - 第4声の前 → yí（一下 yíxià・一个 yígè）
       - 第1〜3声の前 → yì（一天 yìtiān・一年 yìnián）
       - 数詞そのもの・文末 → yī
  3. 「不」の変調
       - 可能補語・反復疑問の中 → 軽声 bu（来不及 láibují・能不能 néngbunéng）
       - 第4声の前 → bú（不太 bútài・不去 búqù）
       - それ以外 → bù
  4. 多音字の文脈補正（请两天假 jià / 看行李 kān / 电话の喂 wéi …）
  5. 儿化（一点儿 yìdiǎnr）
  6. 語単位の結合（Wǒ xiǎng wèn nǐ yí jiàn shìqing）

分かち書きは verify_vocabulary の分かち書き器（HSK公式リストに基づく最長一致）を
そのまま使う。学習者が知っているべき語の単位で切れるため、ピンインのまとまりが
そのまま語彙の手掛かりになる。

新しい語・パターンが教材に出たら NEUTRAL_TONE か CONTEXT_FIXES に足すこと。
"""
import json
import re
import sys
from pathlib import Path

from pypinyin import Style, pinyin

from verify_vocabulary import build_allowed, tokenize

PUNCT = re.compile(r"[，。？！、：；\s]")

# 軽声で読む語。pypinyin は本来の声調を返すため、ここで上書きする。
# (語, その語の正しい音節列)
NEUTRAL_TONE = {
    "事情": "shì qing",
    "时候": "shí hou",
    "东西": "dōng xi",
    "喜欢": "xǐ huan",
    "谢谢": "xiè xie",
    "麻烦": "má fan",
    "路上": "lù shang",
    "休息": "xiū xi",
    "地方": "dì fang",
    "告诉": "gào su",
    "朋友": "péng you",
    "多少": "duō shao",
    "行李": "xíng li",
    "关系": "guān xi",
    "明白": "míng bai",
    "消息": "xiāo xi",
    "商量": "shāng liang",
    "部分": "bù fen",
    "早上": "zǎo shang",
    "晚上": "wǎn shang",
    "姐姐": "jiě jie",
    "妈妈": "mā ma",
    "爸爸": "bà ba",
    "弟弟": "dì di",
    "认识": "rèn shi",
    "客气": "kè qi",
    "衣服": "yī fu",
    "先生": "xiān sheng",
    "打扮": "dǎ ban",
    "暖和": "nuǎn huo",
    "凉快": "liáng kuai",
    "厉害": "lì hai",
    "便宜": "pián yi",
    "意思": "yì si",
    "干净": "gān jing",
    "舒服": "shū fu",
    "打扰": "dǎ rǎo",
    "亲戚": "qīn qi",
    "力气": "lì qi",
    "记得": "jì de",
    "觉得": "jué de",
    "太阳": "tài yáng",
}

# (文脈パターン, パターン内で直す文字, 正しい音節)
CONTEXT_FIXES = [
    ("值得", "得", "dé"),        # 「值得」の得だけは dé
    ("的觉", "觉", "jiào"),      # 睡了…的觉（離合詞の分離形）
    ("张相", "相", "xiàng"),     # 照张相
    ("照相", "相", "xiàng"),
    ("天假", "假", "jià"),       # 请两天假（休暇の假は第4声）
    ("请假", "假", "jià"),
    ("睡不着", "着", "zháo"),    # 可能補語
    ("看一下行李", "看", "kān"), # 「番をする」の看は第1声
    ("喂，", "喂", "wéi"),       # 電話の呼びかけ
]

# 公式リストに単独項目が無いために分かち書きで割れてしまうが、
# 1語として読ませたい単位。拼音の見た目だけの調整で、語彙検証には影響しない。
GROUPING_EXTRA = {"一下", "行李", "一天天", "一起", "什么样"}

TONE_MARKS = {
    "ā": 1, "ē": 1, "ī": 1, "ō": 1, "ū": 1, "ǖ": 1,
    "á": 2, "é": 2, "í": 2, "ó": 2, "ú": 2, "ǘ": 2,
    "ǎ": 3, "ě": 3, "ǐ": 3, "ǒ": 3, "ǔ": 3, "ǚ": 3,
    "à": 4, "è": 4, "ì": 4, "ò": 4, "ù": 4, "ǜ": 4,
}


def tone_of(syllable):
    """音節の声調を返す。軽声・不明は0。"""
    for ch in syllable:
        if ch in TONE_MARKS:
            return TONE_MARKS[ch]
    return 0


def apply_neutral_tone(chars, syllables):
    text = "".join(chars)
    for word, reading in NEUTRAL_TONE.items():
        target = reading.split()
        if len(target) != len(word):
            raise ValueError(f"NEUTRAL_TONEの音節数が字数と一致しない: {word}")
        start = 0
        while True:
            idx = text.find(word, start)
            if idx < 0:
                break
            syllables[idx:idx + len(word)] = target
            start = idx + len(word)


def apply_yi_sandhi(chars, syllables):
    for i, ch in enumerate(chars):
        if ch != "一":
            continue
        # 動詞重ね型 A一A（说一说・想一想・尝一尝）は軽声
        if 0 < i < len(chars) - 1 and chars[i - 1] == chars[i + 1]:
            syllables[i] = "yi"
            continue
        # 「第一」「十一」など数詞そのもの、および文末はそのまま
        if i == len(chars) - 1 or (i > 0 and chars[i - 1] in "第十"):
            syllables[i] = "yī"
            continue
        following = tone_of(syllables[i + 1])
        if following == 4:
            syllables[i] = "yí"
        elif following in (1, 2, 3):
            syllables[i] = "yì"
        else:
            syllables[i] = "yī"


def apply_bu_sandhi(chars, syllables):
    for i, ch in enumerate(chars):
        if ch != "不":
            continue
        # 反復疑問（能不能）と可能補語（来不及・受不了・睡不着）は軽声
        if 0 < i < len(chars) - 1 and chars[i - 1] == chars[i + 1]:
            syllables[i] = "bu"
            continue
        if 0 < i < len(chars) - 1 and chars[i - 1] in "来受睡找买听看对起":
            syllables[i] = "bu"
            continue
        if i == len(chars) - 1:
            syllables[i] = "bù"
            continue
        syllables[i] = "bú" if tone_of(syllables[i + 1]) == 4 else "bù"


def reading_for(text: str) -> str:
    chars = [c for c in text if not PUNCT.match(c)]
    syllables = [
        s[0] for s in pinyin(text, style=Style.TONE) if not PUNCT.match(s[0])
    ]
    if len(chars) != len(syllables):
        raise ValueError(f"字数と音節数が不一致: {text}")

    # 構造助詞の「得」は軽声（様態補語・可能補語のマーカー）。「值得」は後で戻す。
    for i, ch in enumerate(chars):
        if ch == "得":
            syllables[i] = "de"

    apply_neutral_tone(chars, syllables)
    apply_yi_sandhi(chars, syllables)
    apply_bu_sandhi(chars, syllables)

    stripped = "".join(chars)
    for pattern, target_char, correct in CONTEXT_FIXES:
        pattern_text = pattern.replace("，", "")
        offset = pattern_text.index(target_char)
        start = 0
        while True:
            idx = stripped.find(pattern_text, start)
            if idx < 0:
                break
            syllables[idx + offset] = correct
            start = idx + 1

    # 儿化: 直前の音節に r を付けて 1 音節にまとめる
    merged_chars, merged = [], []
    for ch, syl in zip(chars, syllables):
        if ch == "儿" and merged and syl in ("ér", "er"):
            merged[-1] += "r"
            merged_chars[-1] += ch
        else:
            merged.append(syl)
            merged_chars.append(ch)
    return merged_chars, merged


def group_by_word(merged_chars, merged, allowed, primary):
    """漢語拼音正詞法にならい、語単位で音節を繋ぐ。"""
    grouped, index = [], 0
    for token, _ in tokenize("".join(merged_chars), allowed, primary):
        # 儿化でまとめた分だけ文字数と音節数がずれるので、文字を数えながら進む
        taken, consumed = [], 0
        while index < len(merged) and consumed < len(token):
            consumed += len(merged_chars[index])
            taken.append(merged[index])
            index += 1
        if taken:
            grouped.append("".join(taken))
    grouped.extend(merged[index:])
    text = " ".join(grouped)
    return text[:1].upper() + text[1:] if text else text


def main():
    """usage: generate_reading.py <json> <級> [<json> <級> ...]

    級は分かち書きに使う語彙の範囲。topics.json は級をまたいで使うので3を指定する。
    """
    args = sys.argv[1:]
    for path_arg, level_arg in zip(args[0::2], args[1::2]):
        path, level = Path(path_arg), int(level_arg)
        allowed, primary, _ = build_allowed(level)
        for unit in GROUPING_EXTRA:
            allowed.setdefault(unit, "")
            primary.add(unit)
        data = json.loads(path.read_text(encoding="utf-8"))
        key = "sentences" if "sentences" in data else "topics"
        for item in data[key]:
            chars, syllables = reading_for(item["target"])
            item["reading"] = group_by_word(chars, syllables, allowed, primary)
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print(f"{path.name}: {len(data[key])}件に拼音を書き込みました")


if __name__ == "__main__":
    main()
