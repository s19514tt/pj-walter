/* 声調検出テストのケース定義。
 *
 * 仕掛け: 「同じ綴り・違う声調」の音声を作るために、対象の漢字を
 * 同音別声調の実在漢字に置き換える（水 shuǐ → 睡 shuì）。TTSはこれを
 * 普通に読むだけで、狙った声調の崩れがそのまま音になる。
 * 置換後の文は意味的に壊れているので、モデルが「文脈から正しい声調に
 * 戻してしまう」圧力が最大にかかる ＝ 一番厳しい条件でのテストになる。
 *
 * idx は pinyin を音節に割ったときの0始まりの位置。
 * fromTone は本来の声調、toTone は崩した先の声調。
 */
"use strict";

const CASES = [
  // ---- セット1: 3声 → 4声（日本人学習者に最も多い崩れ方） ----
  { id:"1-01", set:1, ja:"私はスーパーに行って果物を何個か買います。",
    hanzi:"我去超市买几个水果。", pinyin:"wǒ qù chāo shì mǎi jǐ ge shuǐ guǒ",
    idx:7, fromChar:"水", toChar:"睡", fromTone:3, toTone:4, corrupt:"我去超市买几个睡果。" },
  { id:"1-02", set:1, ja:"水を一杯ください。",
    hanzi:"请给我一杯水。", pinyin:"qǐng gěi wǒ yì bēi shuǐ",
    idx:0, fromChar:"请", toChar:"庆", fromTone:3, toTone:4, corrupt:"庆给我一杯水。" },
  { id:"1-03", set:1, ja:"私は中華料理がとても好きです。",
    hanzi:"我很喜欢中国菜。", pinyin:"wǒ hěn xǐ huān zhōng guó cài",
    idx:1, fromChar:"很", toChar:"恨", fromTone:3, toTone:4, corrupt:"我恨喜欢中国菜。" },
  { id:"1-04", set:1, ja:"彼は毎朝ジョギングをします。",
    hanzi:"他每天早上跑步。", pinyin:"tā měi tiān zǎo shàng pǎo bù",
    idx:3, fromChar:"早", toChar:"造", fromTone:3, toTone:4, corrupt:"他每天造上跑步。" },
  { id:"1-05", set:1, ja:"お名前を書いてください。",
    hanzi:"请写下你的名字。", pinyin:"qǐng xiě xià nǐ de míng zi",
    idx:1, fromChar:"写", toChar:"谢", fromTone:3, toTone:4, corrupt:"请谢下你的名字。" },
  { id:"1-06", set:1, ja:"これはとても小さいです。",
    hanzi:"这个东西很小。", pinyin:"zhè ge dōng xi hěn xiǎo",
    idx:5, fromChar:"小", toChar:"笑", fromTone:3, toTone:4, corrupt:"这个东西很笑。" },
  { id:"1-07", set:1, ja:"私たちは何時に始めますか。",
    hanzi:"我们几点开始？", pinyin:"wǒ men jǐ diǎn kāi shǐ",
    idx:3, fromChar:"点", toChar:"电", fromTone:3, toTone:4, corrupt:"我们几电开始？" },
  { id:"1-08", set:1, ja:"姉は銀行で働いています。",
    hanzi:"我姐姐在银行工作。", pinyin:"wǒ jiě jie zài yín háng gōng zuò",
    idx:1, fromChar:"姐", toChar:"借", fromTone:3, toTone:4, corrupt:"我借姐在银行工作。" },
  { id:"1-09", set:1, ja:"新しい仕事を探したいです。",
    hanzi:"我想找一个新工作。", pinyin:"wǒ xiǎng zhǎo yí ge xīn gōng zuò",
    idx:2, fromChar:"找", toChar:"照", fromTone:3, toTone:4, corrupt:"我想照一个新工作。" },
  { id:"1-10", set:1, ja:"彼には子供が2人います。",
    hanzi:"他有两个孩子。", pinyin:"tā yǒu liǎng ge hái zi",
    idx:1, fromChar:"有", toChar:"又", fromTone:3, toTone:4, corrupt:"他又两个孩子。" },

  // ---- セット2: 4声 → 2声 ----
  { id:"2-01", set:2, ja:"ちょっとお聞きしたいことがあります。",
    hanzi:"我想问你一件事情。", pinyin:"wǒ xiǎng wèn nǐ yí jiàn shì qing",
    idx:2, fromChar:"问", toChar:"文", fromTone:4, toTone:2, corrupt:"我想文你一件事情。" },
  { id:"2-02", set:2, ja:"これは私の本です。",
    hanzi:"这是我的书。", pinyin:"zhè shì wǒ de shū",
    idx:1, fromChar:"是", toChar:"十", fromTone:4, toTone:2, corrupt:"这十我的书。" },
  { id:"2-03", set:2, ja:"今日の宿題はとても難しいです。",
    hanzi:"今天的作业很难。", pinyin:"jīn tiān de zuò yè hěn nán",
    idx:3, fromChar:"作", toChar:"昨", fromTone:4, toTone:2, corrupt:"今天的昨业很难。" },
  { id:"2-04", set:2, ja:"一緒にご飯を食べましょう。",
    hanzi:"我们一起吃饭吧。", pinyin:"wǒ men yì qǐ chī fàn ba",
    idx:5, fromChar:"饭", toChar:"烦", fromTone:4, toTone:2, corrupt:"我们一起吃烦吧。" },
  { id:"2-05", set:2, ja:"中国語が話せますか。",
    hanzi:"你会说中文吗？", pinyin:"nǐ huì shuō zhōng wén ma",
    idx:1, fromChar:"会", toChar:"回", fromTone:4, toTone:2, corrupt:"你回说中文吗？" },
  { id:"2-06", set:2, ja:"この件はとても重要です。",
    hanzi:"这件事很重要。", pinyin:"zhè jiàn shì hěn zhòng yào",
    idx:2, fromChar:"事", toChar:"时", fromTone:4, toTone:2, corrupt:"这件时很重要。" },
  { id:"2-07", set:2, ja:"手伝ってくれてありがとう。",
    hanzi:"谢谢你的帮助。", pinyin:"xiè xie nǐ de bāng zhù",
    idx:0, fromChar:"谢", toChar:"鞋", fromTone:4, toTone:2, corrupt:"鞋谢你的帮助。" },
  { id:"2-08", set:2, ja:"彼とは長年の知り合いです。",
    hanzi:"我认识他很多年了。", pinyin:"wǒ rèn shi tā hěn duō nián le",
    idx:1, fromChar:"认", toChar:"人", fromTone:4, toTone:2, corrupt:"我人识他很多年了。" },
  { id:"2-09", set:2, ja:"彼は北京に住んでいます。",
    hanzi:"他住在北京。", pinyin:"tā zhù zài běi jīng",
    idx:1, fromChar:"住", toChar:"竹", fromTone:4, toTone:2, corrupt:"他竹在北京。" },
  { id:"2-10", set:2, ja:"この問題は大きいです。",
    hanzi:"这个问题很大。", pinyin:"zhè ge wèn tí hěn dà",
    idx:5, fromChar:"大", toChar:"答", fromTone:4, toTone:2, corrupt:"这个问题很答。" },

  // ---- セット3: 1声 → 4声 ----
  { id:"3-01", set:3, ja:"本を一冊買いたいです。",
    hanzi:"我要买一本书。", pinyin:"wǒ yào mǎi yì běn shū",
    idx:5, fromChar:"书", toChar:"树", fromTone:1, toTone:4, corrupt:"我要买一本树。" },
  { id:"3-02", set:3, ja:"彼は出かけました。",
    hanzi:"他出去了。", pinyin:"tā chū qù le",
    idx:1, fromChar:"出", toChar:"处", fromTone:1, toTone:4, corrupt:"他处去了。" },
  { id:"3-03", set:3, ja:"うちは3人家族です。",
    hanzi:"我家有三口人。", pinyin:"wǒ jiā yǒu sān kǒu rén",
    idx:1, fromChar:"家", toChar:"架", fromTone:1, toTone:4, corrupt:"我架有三口人。" },
  { id:"3-04", set:3, ja:"土曜日は時間があります。",
    hanzi:"星期六我有空。", pinyin:"xīng qī liù wǒ yǒu kòng",
    idx:0, fromChar:"星", toChar:"姓", fromTone:1, toTone:4, corrupt:"姓期六我有空。" },
  { id:"3-05", set:3, ja:"彼らはみんな学生です。",
    hanzi:"他们都是学生。", pinyin:"tā men dōu shì xué sheng",
    idx:2, fromChar:"都", toChar:"豆", fromTone:1, toTone:4, corrupt:"他们豆是学生。" },
  { id:"3-06", set:3, ja:"果物をいくつか買いました。",
    hanzi:"我买了一些水果。", pinyin:"wǒ mǎi le yì xiē shuǐ guǒ",
    idx:4, fromChar:"些", toChar:"谢", fromTone:1, toTone:4, corrupt:"我买了一谢水果。" },
  { id:"3-07", set:3, ja:"この学生は背が高いです。",
    hanzi:"这个学生很高。", pinyin:"zhè ge xué sheng hěn gāo",
    idx:5, fromChar:"高", toChar:"告", fromTone:1, toTone:4, corrupt:"这个学生很告。" },
  { id:"3-08", set:3, ja:"病院に診てもらいに行きます。",
    hanzi:"我去医院看病。", pinyin:"wǒ qù yī yuàn kàn bìng",
    idx:2, fromChar:"医", toChar:"意", fromTone:1, toTone:4, corrupt:"我去意院看病。" },
  { id:"3-09", set:3, ja:"3組に分かれてください。",
    hanzi:"请分成三组。", pinyin:"qǐng fēn chéng sān zǔ",
    idx:1, fromChar:"分", toChar:"份", fromTone:1, toTone:4, corrupt:"请份成三组。" },
  { id:"3-10", set:3, ja:"私の誕生日は明日です。",
    hanzi:"我的生日是明天。", pinyin:"wǒ de shēng rì shì míng tiān",
    idx:2, fromChar:"生", toChar:"剩", fromTone:1, toTone:4, corrupt:"我的剩日是明天。" },

  // ---- セット4: 2声 → 4声 ----
  { id:"4-01", set:4, ja:"彼は来年北京に来ます。",
    hanzi:"他明年来北京。", pinyin:"tā míng nián lái běi jīng",
    idx:3, fromChar:"来", toChar:"赖", fromTone:2, toTone:4, corrupt:"他明年赖北京。" },
  { id:"4-02", set:4, ja:"お名前は何ですか。",
    hanzi:"你叫什么名字？", pinyin:"nǐ jiào shén me míng zi",
    idx:4, fromChar:"名", toChar:"命", fromTone:2, toTone:4, corrupt:"你叫什么命字？" },
  { id:"4-03", set:4, ja:"来年中国に行きます。",
    hanzi:"我明年去中国。", pinyin:"wǒ míng nián qù zhōng guó",
    idx:2, fromChar:"年", toChar:"念", fromTone:2, toTone:4, corrupt:"我明念去中国。" },
  { id:"4-04", set:4, ja:"私の部屋はきれいです。",
    hanzi:"我的房间很干净。", pinyin:"wǒ de fáng jiān hěn gān jìng",
    idx:2, fromChar:"房", toChar:"放", fromTone:2, toTone:4, corrupt:"我的放间很干净。" },
  { id:"4-05", set:4, ja:"この単語はどういう意味ですか。",
    hanzi:"这个词是什么意思？", pinyin:"zhè ge cí shì shén me yì si",
    idx:2, fromChar:"词", toChar:"次", fromTone:2, toTone:4, corrupt:"这个次是什么意思？" },
  { id:"4-06", set:4, ja:"彼はよく図書館に行きます。",
    hanzi:"他常常去图书馆。", pinyin:"tā cháng cháng qù tú shū guǎn",
    idx:1, fromChar:"常", toChar:"唱", fromTone:2, toTone:4, corrupt:"他唱常去图书馆。" },
  { id:"4-07", set:4, ja:"私たちは同級生です。",
    hanzi:"我们是同学。", pinyin:"wǒ men shì tóng xué",
    idx:3, fromChar:"同", toChar:"痛", fromTone:2, toTone:4, corrupt:"我们是痛学。" },
  { id:"4-08", set:4, ja:"この人は私の友達です。",
    hanzi:"这个人是我朋友。", pinyin:"zhè ge rén shì wǒ péng you",
    idx:2, fromChar:"人", toChar:"认", fromTone:2, toTone:4, corrupt:"这个认是我朋友。" },
  { id:"4-09", set:4, ja:"銀行にお金を下ろしに行きます。",
    hanzi:"我去银行取钱。", pinyin:"wǒ qù yín háng qǔ qián",
    idx:2, fromChar:"银", toChar:"印", fromTone:2, toTone:4, corrupt:"我去印行取钱。" },
  { id:"4-10", set:4, ja:"この問題は難しいです。",
    hanzi:"这个题很难。", pinyin:"zhè ge tí hěn nán",
    idx:2, fromChar:"题", toChar:"替", fromTone:2, toTone:4, corrupt:"这个替很难。" },
];

/* セット5は対照群。セット1〜4から10文を選び、声調を崩さずそのまま読ませる。
 * ここで「声調ちがい」が出たら、それはモデルの誤検出（偽陽性）。 */
const CONTROL_IDS = ["1-01","1-03","1-07","2-01","2-05","2-10","3-01","3-05","4-01","4-04"];

const CONTROL_CASES = CONTROL_IDS.map(id => {
  const src = CASES.find(c => c.id === id);
  return { ...src, id: "5-" + id, set: 5, control: true,
           toChar: src.fromChar, toTone: src.fromTone, corrupt: src.hanzi, sourceId: id };
});

const SETS = [
  { set:1, title:"セット1: 3声 → 4声", desc:"日本人学習者に最も多い崩れ方。第3声の下降を第4声に振ってしまうケース。" },
  { set:2, title:"セット2: 4声 → 2声", desc:"下降調を上昇調に取り違えるケース。" },
  { set:3, title:"セット3: 1声 → 4声", desc:"平らな高音を下降させてしまうケース。" },
  { set:4, title:"セット4: 2声 → 4声", desc:"上昇調を下降調に取り違えるケース。" },
  { set:5, title:"セット5: 対照群（崩さない）", desc:"セット1〜4から10文を選び、正しい声調のまま読ませる。ここで声調ちがいが出たら誤検出（偽陽性）。" },
].map(s => ({ ...s, cases: (s.set === 5 ? CONTROL_CASES : CASES.filter(c => c.set === s.set)) }));
