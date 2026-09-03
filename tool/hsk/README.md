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

# ピンイン生成（reading フィールドを上書き）。引数は「ファイル 級」の組。
# topics.json は級をまたいで使うので、狭いほうの3を指定する。
pip install pypinyin
python3 generate_reading.py ../../assets/data/zh/sentences_3.json 3 \
                            ../../assets/data/zh/sentences_4.json 4 \
                            ../../assets/data/zh/topics.json 3
```

`generate_reading.py` は pypinyin の素の出力をそのまま使わない。pypinyin は
「一」「不」の変調をほぼ行わず、頻出語の軽声も反映しないため、そのままでは
音読教材として成立しないからである。以下を規則で補正している。

| 補正 | 例 |
|---|---|
| 軽声 | 事情 shìqing / 时候 shíhou / 谢谢 xièxie / 对不起 duìbuqǐ |
| 「一」の変調 | 一下 yíxià（第4声の前）/ 一天 yìtiān（第1〜3声の前）/ 说一说 shuō yi shuō（動詞重ね型は軽声） |
| 「不」の変調 | 不太 bútài（第4声の前）/ 能不能 néng bu néng（反復疑問は軽声） |
| 構造助詞 | 说得很快 shuō de（様態補語の得は軽声。ただし 值得 は zhídé） |
| 多音字 | 请两天假 jià / 看行李 kān / 电話の喂 wéi / 睡了…的觉 jiào |
| 儿化 | 一点儿 yìdiǎnr |
| 語単位の結合 | Wǒ xiǎng wèn nǐ yí jiàn shìqing（漢語拼音正詞法にならう） |

分かち書きは `verify_vocabulary.py` の分かち書き器を流用している。HSK公式リストに
基づく最長一致なので、学習者が知っているべき語の単位で切れ、ピンインのまとまりが
そのまま語彙の手掛かりになる。

教材に新しい多音字・軽声語のパターンが出たら `CONTEXT_FIXES` / `NEUTRAL_TONE` に
追加すること。**ピンインを手で直さないこと**（また揺れる）。
