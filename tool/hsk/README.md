# 中国語教材の検証ツール

`assets/data/zh/` の教材が **HSKの級に対して語彙的に妥当か** を機械的に検証し、
ピンイン（`reading`）を生成するためのスクリプト。教材を追加・修正したら必ず通すこと。

## なぜ必要か

教材文を勘で書くと、HSK3のデッキにHSK5の語が混ざる、といったことが簡単に起きる。
「そのレベルの学習者が話せるようになるべきこと」を出発点にしつつ、
**使う語彙は公式リストの外に出ない** ことを機械的に担保するのがこのツールの役割。

## 語彙データの取得

公式語彙リストはリポジトリに含めていない（数MBあるため）。次のコマンドで取得する。

```bash
cd tool/hsk
for n in 1 2 3 4; do
  curl -sS -o "old_$n.json" \
    "https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/main/wordlists/exclusive/old/$n.json"
  curl -sS -o "new_$n.json" \
    "https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/main/wordlists/exclusive/new/$n.json"
done
```

- `old_*.json` … **HSK 2.0**（旧6級制）の級別新出語。L1=150 / L2=147 / L3=298 / L4=598 語で、
  累計は L1-3 が 595語、L1-4 が 1193語。公式スペックの「600語 / 1200語」と一致する。
- `new_*.json` … **HSK 3.0**（2021年の国際中文教育中文水平等級標準）の級別新出語。

## 許容語彙の定義

「HSK3」「HSK4」という級名の実体は **HSK 2.0** なので、これを主たる制約とする。
ただしHSK 2.0の公式リストは複合語中心で、`说`（`说话`のみ収録）、`早`（`早上`のみ）、
`爬`（`爬山`のみ）、`有点儿`、`那么` といった基本語を単独で持たない。
これらはいずれもHSK 3.0の初級帯に収録されているため、補完集合として認める。

```
許容語彙(HSK3) = HSK2.0 L1-3 ∪ HSK3.0 L1-2 ∪ 構成字
許容語彙(HSK4) = HSK2.0 L1-4 ∪ HSK3.0 L1-3 ∪ 構成字
```

「構成字」は許容語に現れる単漢字。離合詞が分離した形（`睡了七个小时的觉` の `觉`、
`跑三十分钟的步` の `步`）を通すために必要で、学習者が既に語の中で出会っている字なので
「未知語」ではない。

補完集合から使った語は実行時に全件表示されるので、目視で妥当性を確認できる。
推測で語を足すことはしていない。

## 実行

```bash
# 語彙検証（級外の語があれば exit 1）
python3 verify_vocabulary.py ../../assets/data/zh/sentences_3.json 3
python3 verify_vocabulary.py ../../assets/data/zh/sentences_4.json 4

# ピンイン生成（reading フィールドを上書き）
pip install pypinyin
python3 generate_reading.py ../../assets/data/zh/sentences_3.json \
                            ../../assets/data/zh/sentences_4.json \
                            ../../assets/data/zh/topics.json
```

`generate_reading.py` は pypinyin の語句単位の多音字解決を使ったうえで、
構造助詞の「得」（軽声 de）、離合詞の分離形、可能補語の `睡不着`（zháo）、
儿化を文脈規則で補正する。教材に新しい多音字パターンが出たら
`CONTEXT_FIXES` に追加すること。
