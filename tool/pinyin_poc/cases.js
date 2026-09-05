/* 声調識別テストの最小対（ミニマルペア）。
 *
 * 前の版は「同音別声調の漢字に置き換えて不自然な文を作る」方式だったが、
 * 意味の壊れた文（睡果＝寝る果物）はTTS側が正しく読んでくれない。実際、
 * 対象と関係ない音節が別の音に化ける事故が起きた。そうなると「崩していない
 * 音節への誤指摘」を数えても、それがモデルの嘘なのかTTSの事故なのか
 * 区別がつかず、測定として成立しない。
 *
 * この版は、**両方とも自然な実在の文**からなる最小対だけを使う。
 * 綴りは完全に同じで、1音節の声調だけが違う。
 *
 *   我要水。 wǒ yào shuǐ   （水がほしい）
 *   我要睡。 wǒ yào shuì   （寝たい）
 *
 * どちらもTTSは普通に読める。どちらも「正しい文」なので、正解／不正解では
 * なく **モデルが2つを聞き分けられるか** を両方向で見る識別テストになる。
 * 対象以外の音節はどちらの文でも同じ発音なので、そこでの声調ちがいの指摘は
 * 今度こそ純粋にモデルの嘘として数えられる。
 *
 * idx は pinyin を音節に割ったときの0始まりの位置。a と b は idx の声調だけが
 * 異なり、それ以外の音節は完全に同一であること（cases_test で機械検証する）。
 */
"use strict";

const PAIRS = [
  // ---- セット1: 3声 ⇄ 4声（日本人学習者が最も混同する組み合わせ） ----
  { id:"1-1", set:1, idx:2,
    a:{ hanzi:"我要水。",       pinyin:"wǒ yào shuǐ",          ja:"水がほしい。" },
    b:{ hanzi:"我要睡。",       pinyin:"wǒ yào shuì",          ja:"寝たい。" } },
  { id:"1-2", set:1, idx:2,
    a:{ hanzi:"他要买房子。",   pinyin:"tā yào mǎi fáng zi",   ja:"彼は家を買いたい。" },
    b:{ hanzi:"他要卖房子。",   pinyin:"tā yào mài fáng zi",   ja:"彼は家を売りたい。" } },
  { id:"1-3", set:1, idx:5,
    a:{ hanzi:"他是我的老板。", pinyin:"tā shì wǒ de lǎo bǎn", ja:"彼は私の上司です。" },
    b:{ hanzi:"他是我的老伴。", pinyin:"tā shì wǒ de lǎo bàn", ja:"彼は私の連れ合いです。" } },
  { id:"1-4", set:1, idx:2,
    a:{ hanzi:"他很想我。",     pinyin:"tā hěn xiǎng wǒ",      ja:"彼は私をとても恋しがっている。" },
    b:{ hanzi:"他很像我。",     pinyin:"tā hěn xiàng wǒ",      ja:"彼は私にとてもよく似ている。" } },
  { id:"1-5", set:1, idx:2,
    a:{ hanzi:"我想问他。",     pinyin:"wǒ xiǎng wèn tā",      ja:"彼に聞きたい。" },
    b:{ hanzi:"我想吻他。",     pinyin:"wǒ xiǎng wěn tā",      ja:"彼にキスしたい。" } },
  { id:"1-6", set:1, idx:3,
    a:{ hanzi:"这个很近。",     pinyin:"zhè ge hěn jìn",       ja:"これはとても近い。" },
    b:{ hanzi:"这个很紧。",     pinyin:"zhè ge hěn jǐn",       ja:"これはとてもきつい。" } },
  { id:"1-7", set:1, idx:3,
    a:{ hanzi:"这个很慢。",     pinyin:"zhè ge hěn màn",       ja:"これはとても遅い。" },
    b:{ hanzi:"这个很满。",     pinyin:"zhè ge hěn mǎn",       ja:"これはとても満杯だ。" } },
  { id:"1-8", set:1, idx:4,
    a:{ hanzi:"这是一种语言。", pinyin:"zhè shì yì zhǒng yǔ yán", ja:"これは一種の言語です。" },
    b:{ hanzi:"这是一种预言。", pinyin:"zhè shì yì zhǒng yù yán", ja:"これは一種の予言です。" } },

  // ---- セット2: 1声 ⇄ 4声 ----
  { id:"2-1", set:2, idx:3,
    a:{ hanzi:"我的眼睛很大。", pinyin:"wǒ de yǎn jīng hěn dà", ja:"私の目は大きい。" },
    b:{ hanzi:"我的眼镜很大。", pinyin:"wǒ de yǎn jìng hěn dà", ja:"私のメガネは大きい。" } },
  { id:"2-2", set:2, idx:2,
    a:{ hanzi:"这是包子。",     pinyin:"zhè shì bāo zi",       ja:"これは肉まんです。" },
    b:{ hanzi:"这是豹子。",     pinyin:"zhè shì bào zi",       ja:"これはヒョウです。" } },
  { id:"2-3", set:2, idx:3,
    a:{ hanzi:"他喜欢花。",     pinyin:"tā xǐ huān huā",       ja:"彼は花が好きです。" },
    b:{ hanzi:"他喜欢画。",     pinyin:"tā xǐ huān huà",       ja:"彼は絵が好きです。" } },
  { id:"2-4", set:2, idx:5,
    a:{ hanzi:"那边有很多书。", pinyin:"nà biān yǒu hěn duō shū", ja:"あそこには本がたくさんある。" },
    b:{ hanzi:"那边有很多树。", pinyin:"nà biān yǒu hěn duō shù", ja:"あそこには木がたくさんある。" } },
  { id:"2-5", set:2, idx:2,
    a:{ hanzi:"这是杯子。",     pinyin:"zhè shì bēi zi",       ja:"これはコップです。" },
    b:{ hanzi:"这是被子。",     pinyin:"zhè shì bèi zi",       ja:"これは布団です。" } },
  { id:"2-6", set:2, idx:3,
    a:{ hanzi:"这是教师。",     pinyin:"zhè shì jiào shī",     ja:"これは教師です。" },
    b:{ hanzi:"这是教室。",     pinyin:"zhè shì jiào shì",     ja:"これは教室です。" } },

  // ---- セット3: 1声 ⇄ 2声 / 1声 ⇄ 3声 ----
  { id:"3-1", set:3, idx:5,
    a:{ hanzi:"请给我一点汤。", pinyin:"qǐng gěi wǒ yì diǎn tāng", ja:"スープを少しください。" },
    b:{ hanzi:"请给我一点糖。", pinyin:"qǐng gěi wǒ yì diǎn táng", ja:"砂糖を少しください。" } },
  { id:"3-2", set:3, idx:2,
    a:{ hanzi:"这是猪。",       pinyin:"zhè shì zhū",          ja:"これはブタです。" },
    b:{ hanzi:"这是竹。",       pinyin:"zhè shì zhú",          ja:"これは竹です。" } },
  { id:"3-3", set:3, idx:2,
    a:{ hanzi:"这是窗。",       pinyin:"zhè shì chuāng",       ja:"これは窓です。" },
    b:{ hanzi:"这是床。",       pinyin:"zhè shì chuáng",       ja:"これはベッドです。" } },
  { id:"3-4", set:3, idx:2,
    a:{ hanzi:"这是烟。",       pinyin:"zhè shì yān",          ja:"これはタバコです。" },
    b:{ hanzi:"这是盐。",       pinyin:"zhè shì yán",          ja:"これは塩です。" } },
  { id:"3-5", set:3, idx:4,
    a:{ hanzi:"这是我的妈。",   pinyin:"zhè shì wǒ de mā",     ja:"これは私の母です。" },
    b:{ hanzi:"这是我的马。",   pinyin:"zhè shì wǒ de mǎ",     ja:"これは私の馬です。" } },

  // ---- セット4: 2声 ⇄ 4声 ----
  { id:"4-1", set:4, idx:3,
    a:{ hanzi:"我在学韩语。",   pinyin:"wǒ zài xué hán yǔ",    ja:"私は韓国語を学んでいます。" },
    b:{ hanzi:"我在学汉语。",   pinyin:"wǒ zài xué hàn yǔ",    ja:"私は中国語を学んでいます。" } },
  { id:"4-2", set:4, idx:3,
    a:{ hanzi:"他喜欢骑车。",   pinyin:"tā xǐ huān qí chē",    ja:"彼は自転車に乗るのが好きです。" },
    b:{ hanzi:"他喜欢汽车。",   pinyin:"tā xǐ huān qì chē",    ja:"彼は自動車が好きです。" } },
  { id:"4-3", set:4, idx:4,
    a:{ hanzi:"这是一个实验。", pinyin:"zhè shì yí ge shí yàn", ja:"これは一つの実験です。" },
    b:{ hanzi:"这是一个试验。", pinyin:"zhè shì yí ge shì yàn", ja:"これは一つの試験・テストです。" } },

  // ---- セット5: 2声 ⇄ 3声 ----
  { id:"5-1", set:5, idx:4,
    a:{ hanzi:"我喜欢大学。",   pinyin:"wǒ xǐ huān dà xué",    ja:"私は大学が好きです。" },
    b:{ hanzi:"我喜欢大雪。",   pinyin:"wǒ xǐ huān dà xuě",    ja:"私は大雪が好きです。" } },
  { id:"5-2", set:5, idx:3,
    a:{ hanzi:"今天有鱼。",     pinyin:"jīn tiān yǒu yú",      ja:"今日は魚があります。" },
    b:{ hanzi:"今天有雨。",     pinyin:"jīn tiān yǒu yǔ",      ja:"今日は雨が降ります。" } },
  { id:"5-3", set:5, idx:3,
    a:{ hanzi:"这个很圆。",     pinyin:"zhè ge hěn yuán",      ja:"これはとても丸い。" },
    b:{ hanzi:"这个很远。",     pinyin:"zhè ge hěn yuǎn",      ja:"これはとても遠い。" } },
];

/** その組で問われている声調のペア（例: "3声 ⇄ 4声"）。 */
function tonePairLabel(p){
  const t = r => toSyllables(p[r].pinyin)[p.idx].tone;
  return `${t("a")}声 ⇄ ${t("b")}声`;
}

/** 対象音節の綴り（声調記号なし）。 */
function pairBase(p){ return toSyllables(p.a.pinyin)[p.idx].base; }

const SETS = [
  { set:1, title:"セット1: 3声 ⇄ 4声", desc:"日本人学習者が最も混同する組み合わせ。" },
  { set:2, title:"セット2: 1声 ⇄ 4声", desc:"平らな高音と下降調。" },
  { set:3, title:"セット3: 1声 ⇄ 2声 / 1声 ⇄ 3声", desc:"平らな高音と、上昇・低降の対立。" },
  { set:4, title:"セット4: 2声 ⇄ 4声", desc:"上昇調と下降調。向きが逆なので本来は最も聞き分けやすいはず。" },
  { set:5, title:"セット5: 2声 ⇄ 3声", desc:"上昇調と低く沈む調。母語話者でも文脈依存が大きい組み合わせ。" },
].map(s => ({ ...s, pairs: PAIRS.filter(p => p.set === s.set) }));
