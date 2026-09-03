#!/usr/bin/env python3
"""教材JSONに拼音(reading)を書き込む。

pypinyin の語句単位の多音字解決を使い、そのうえで中国語教育上まちがえられない
以下を文脈規則で補正する。

  - 構造助詞「得」(様態・可能補語のマーカー)は軽声 de。pypinyin は動詞と
    切れていると dé を返すことがある。「值得」だけは dé なので除外する。
  - 離合詞が分離した形(睡…的觉 / 照张相)は語として認識されない。
  - 可能補語の「睡不着」は zháo。「不」も軽声 bu。
  - 儿化は直前の音節に r を付けて 1 音節にまとめる。
"""
import json
import re
import sys
from pathlib import Path

from pypinyin import Style, pinyin

PUNCT = re.compile(r"[，。？！、：；\s]")

# (文脈パターン, パターン内で直す文字, 正しい音節)
CONTEXT_FIXES = [
    (re.compile(r"值得"), "得", "dé"),        # 「值得」の得だけは dé
    (re.compile(r"的觉"), "觉", "jiào"),      # 睡了…的觉
    (re.compile(r"张相"), "相", "xiàng"),      # 照张相
    (re.compile(r"睡不着"), "着", "zháo"),     # 可能補語
    (re.compile(r"睡不着"), "不", "bu"),
    (re.compile(r"来不及"), "不", "bu"),
    (re.compile(r"受不了"), "不", "bu"),
    (re.compile(r"找不到"), "不", "bu"),
]


def reading_for(text: str) -> str:
    chars = [c for c in text if not PUNCT.match(c)]
    syllables = [s[0] for s in pinyin(text, style=Style.TONE) if not PUNCT.match(s[0])]
    if len(chars) != len(syllables):
        raise ValueError(f"字数と音節数が不一致: {text}")
    stripped = "".join(chars)

    # 構造助詞の「得」は軽声。「值得」の得だけは dé。
    for i, ch in enumerate(chars):
        if ch == "得" and stripped[max(0, i - 1):i + 1] != "值得":
            syllables[i] = "de"

    for pattern, target_char, correct in CONTEXT_FIXES:
        for m in pattern.finditer(stripped):
            syllables[m.start() + m.group().index(target_char)] = correct

    merged = []
    for ch, syl in zip(chars, syllables):
        if ch == "儿" and merged and syl in ("ér", "er"):
            merged[-1] += "r"
        else:
            merged.append(syl)
    return " ".join(merged)


def main():
    for path in map(Path, sys.argv[1:]):
        data = json.loads(path.read_text(encoding="utf-8"))
        key = "sentences" if "sentences" in data else "topics"
        for item in data[key]:
            item["reading"] = reading_for(item["target"])
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{path.name}: {len(data[key])}件に拼音を書き込みました")


if __name__ == "__main__":
    main()
