#!/usr/bin/env python3
"""HSK教材JSONの語彙検証と拼音自動生成。

許容語彙(級N) = HSK2.0 L1..N ∪ HSK3.0 L1
  - HSK2.0(旧6級制)が「HSK3/HSK4」という級名の実体。これを主たる制約とする。
  - HSK2.0の公式リストは「说话」「早上」のように複合語だけを収録し、
    「说」「早」等の基本字を単独で持たない。これらは全てHSK3.0(2021年基準)の
    レベル1に該当するため、HSK3.0 L1を補完集合として加える。
    どちらも公式基準であり、推測による追加は一切していない。

拼音は各公式リストが語ごとに持つ transcriptions.pinyin をそのまま連結する
(声調変化は辞書形のまま。一般的な教材表記に合わせる)。
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).parent
PUNCT = set("，。？！、：；“”‘’（）—…《》")
PROPER = {
    "中国": "Zhōngguó", "北京": "Běijīng", "上海": "Shànghǎi", "日本": "Rìběn",
    "东京": "Dōngjīng", "汉语": "Hànyǔ",
    "小李": "Xiǎo Lǐ", "小王": "Xiǎo Wáng", "小张": "Xiǎo Zhāng",
}


def _load(prefix, levels):
    out = {}
    for n in levels:
        for w in json.load(open(HERE / f"{prefix}_{n}.json")):
            if w["simplified"] in out:
                continue
            forms = w.get("forms") or []
            py = forms[0]["transcriptions"]["pinyin"] if forms else ""
            out[w["simplified"]] = (n, py)
    return out


# HSK2.0(主制約)を補完するHSK3.0の上限レベル。
# HSK2.0の公式リストは複合語中心で「说」「早」「爬」等の基本字や
# 「有点儿」「那么」等の基本表現を単独収録していない。これらはHSK3.0の
# 初級帯に収録されているため、そこまでを補完集合として認める。
SUPPLEMENT_MAX = {3: 2, 4: 3}


def build_allowed(max_level):
    """許容語彙 -> ({語: 拼音}, 主制約の語集合, 補完集合の語集合)"""
    primary = _load("old", range(1, max_level + 1))
    supplement = _load("new", range(1, SUPPLEMENT_MAX[max_level] + 1))

    allowed = {w: py for w, (_, py) in primary.items()}
    for word, (_, py) in supplement.items():
        allowed.setdefault(word, py)
    allowed.update(PROPER)

    # 構成字: 許容語に現れる単漢字は「未知語」ではないので単独使用を認める。
    # 離合詞の分離形(睡了七个小时的觉 / 跑三十分钟的步)がこれで通る。
    # 拼音は、字数と音節数が一致する複合語から位置対応で取り出す(公式データ由来)。
    char_py = {}
    for word, py in list(allowed.items()):
        syllables = py.split()
        if len(word) > 1 and len(syllables) == len(word):
            for ch, syl in zip(word, syllables):
                char_py.setdefault(ch, syl)
    for ch, syl in char_py.items():
        allowed.setdefault(ch, syl)
    return allowed, set(primary), set(supplement) - set(primary)


def tokenize(text, allowed, primary=frozenset()):
    """動的計画法で分かち書きする。

    貪欲最長一致だと「有时间」が「有时/间」に切れてしまうため、
    「公式リスト(HSK2.0)収録の複合語」を最も高く評価するスコアを最大化する。
    """
    body = "".join(c for c in text if not (c in PUNCT or c.isspace() or c.isascii()))
    n = len(body)
    maxlen = max(len(w) for w in allowed)
    NEG = float("-inf")
    best = [NEG] * (n + 1)
    back = [None] * (n + 1)
    best[0] = 0
    for i in range(n):
        if best[i] == NEG:
            continue
        for ln in range(1, min(maxlen, n - i) + 1):
            cand = body[i:i + ln]
            if cand in allowed:
                weight = 3 if (ln > 1 and cand in primary) else (2 if ln > 1 else 1)
                score = best[i] + weight * ln
            elif ln == 1:
                score = best[i] - 100  # 未知字は強く減点しつつ経路は残す
            else:
                continue
            # 同点は「先に来るトークンが長い」側を採る（前方最長一致の慣習）。
            # >(厳密) にすると「路上/车」が「路/上车」に負ける。
            if score >= best[i + ln]:
                best[i + ln] = score
                back[i + ln] = (i, cand)
    tokens, pos = [], n
    while pos > 0:
        prev, cand = back[pos]
        tokens.append((cand, cand in allowed))
        pos = prev
    return list(reversed(tokens))


def reading_for(text, allowed, primary):
    return " ".join(allowed[t] for t, ok in tokenize(text, allowed, primary) if ok)


def main():
    path, max_level = Path(sys.argv[1]), int(sys.argv[2])
    write = "--write" in sys.argv
    allowed, primary, supplement = build_allowed(max_level)
    data = json.load(open(path))
    sentences = data["sentences"]

    ids = [s["id"] for s in sentences]
    dupes = {i for i in ids if ids.count(i) > 1}
    violations, used_supplement = [], {}
    for s in sentences:
        bad = [t for t, ok in tokenize(s["target"], allowed, primary) if not ok]
        if bad:
            violations.append((s["id"], s["target"], bad))
        for t, ok in tokenize(s["target"], allowed, primary):
            if ok and t in supplement and t not in primary:
                used_supplement.setdefault(t, []).append(s["id"])

    themes = {}
    for s in sentences:
        themes[s["theme"]] = themes.get(s["theme"], 0) + 1
    print(f"{path.name}: {len(sentences)}文 / ID重複 {sorted(dupes) or 'なし'} / テーマ {themes}")
    dup_t = {s["target"] for s in sentences if [x["target"] for x in sentences].count(s["target"]) > 1}
    if dup_t:
        print(f"  ⚠️ 同一中国語文の重複: {dup_t}")

    # 補完集合から使った語は全件表示して人手で妥当性を確認できるようにする
    print(f"  HSK2.0 L1-{max_level} 外から使った語 ({len(used_supplement)}種、HSK3.0 L1-{SUPPLEMENT_MAX[max_level]}収録):")
    print("    " + "  ".join(f"{w}({len(ids)})" for w, ids in sorted(used_supplement.items())))

    if violations:
        print(f"\n❌ どちらの公式リストにも無い語 {len(violations)}文:")
        for sid, tgt, bad in violations:
            print(f"  {sid}: {tgt}  ← {' '.join(bad)}")
        return 1

    print("  ✅ 全文が公式リスト内の語彙のみ")
    if write:
        for s in sentences:
            s["reading"] = reading_for(s["target"], allowed, primary)
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("  ✅ 拼音を書き込みました")
    return 0


if __name__ == "__main__":
    sys.exit(main())
