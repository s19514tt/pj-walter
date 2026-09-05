/* 音声→ピンイン検証POCの共通ロジック。index.html（録音版）と autotest.html（TTS自動テスト版）が読む。 */
"use strict";

/* ============================================================
   ピンインのユーティリティ
   ============================================================ */

const ACCENTS = {
  "ā":["a",1],"á":["a",2],"ǎ":["a",3],"à":["a",4],
  "ē":["e",1],"é":["e",2],"ě":["e",3],"è":["e",4],
  "ī":["i",1],"í":["i",2],"ǐ":["i",3],"ì":["i",4],
  "ō":["o",1],"ó":["o",2],"ǒ":["o",3],"ò":["o",4],
  "ū":["u",1],"ú":["u",2],"ǔ":["u",3],"ù":["u",4],
  "ǖ":["v",1],"ǘ":["v",2],"ǚ":["v",3],"ǜ":["v",4],
  "ń":["n",2],"ň":["n",3],"ǹ":["n",4],
  "ê":["e",5],"ü":["v",5]
};

// 声調番号 → 声調記号つきの母音。retone() が使う。
const TONE_MARKS = {
  a:["ā","á","ǎ","à","a"], o:["ō","ó","ǒ","ò","o"], e:["ē","é","ě","è","e"],
  i:["ī","í","ǐ","ì","i"], u:["ū","ú","ǔ","ù","u"], v:["ǖ","ǘ","ǚ","ǜ","ü"]
};

/** 声調記号の付いた音節の、声調だけを差し替える（shuǐ + 4 → shuì）。
 *
 * 記号の位置は変えずに置き換えるだけなので、元が軽声（記号なし）の音節には
 * 使えない。声調を崩すテストの対象は必ず1〜4声なので実用上は足りる。 */
function retone(raw, tone){
  return [...String(raw).normalize("NFC")].map(ch => {
    const hit = ACCENTS[ch];
    if (!hit || hit[1] === 5) return ch;
    return TONE_MARKS[hit[0]] ? TONE_MARKS[hit[0]][tone-1] : ch;
  }).join("");
}

// 声調番号つき表記（wen4 形式）も受け付ける
function parseSyllable(raw){
  let tone = 5, base = "";
  const s = raw.normalize("NFC");
  for (const ch of s){
    const hit = ACCENTS[ch];
    if (hit){ base += hit[0]; if (hit[1] !== 5) tone = hit[1]; }
    else if (ch >= "1" && ch <= "5"){ tone = Number(ch); }
    else base += ch.toLowerCase();
  }
  return { base, tone, raw: s };
}

// 音節の切り出し（長い韻母から貪欲マッチ）
const INITIALS = ["zh","ch","sh","b","p","m","f","d","t","n","l","g","k","h","j","q","x","r","z","c","s","y","w",""];
// j/q/x/y の後ろでは ü を u と綴るため、üe に加えて ue も受け付ける
//（üan→uan, ün→un は既存の綴りと同形なのでそのまま使える）
const FINALS = ["iang","iong","uang","ueng","üan","van","uai","uan","ian","iao","üe","ue","ve","ang","eng","ing","ong","ai","ei","ao","ou","an","en","er","ia","ie","iu","in","ua","uo","ui","un","ün","vn","io","a","o","e","i","u","ü","v"]
  .sort((a,b)=>b.length-a.length);

function splitWord(word){
  const out = [];
  let i = 0;
  const plain = [...word].map(c => ACCENTS[c] ? ACCENTS[c][0] : c.toLowerCase());
  const marks = [...word];
  while (i < plain.length){
    let matched = null;
    for (const ini of INITIALS){
      if (plain.slice(i, i+ini.length).join("") !== ini) continue;
      for (const fin of FINALS){
        const j = i + ini.length;
        if (plain.slice(j, j+fin.length).join("") !== fin) continue;
        let end = j + fin.length;
        // 儿化: 後ろに r が続き、その次が母音でなければ取り込む
        if (plain[end] === "r" && fin !== "er"){
          const nx = plain[end+1];
          if (nx === undefined || !"aeiouv".includes(nx)) end++;
        }
        // 数字による声調表記（wen4 形式）を同じ音節に取り込む
        if (plain[end] >= "1" && plain[end] <= "5") end++;
        matched = end;
        break;
      }
      if (matched) break;
    }
    if (!matched){ // 切れない文字はそのまま1音節扱いにして前進
      matched = i + 1;
    }
    out.push(marks.slice(i, matched).join(""));
    i = matched;
  }
  return out;
}

function toSyllables(pinyin){
  if (!pinyin) return [];
  return pinyin
    .replace(/[，。！？、,.!?;:"'()（）]/g, " ")
    .split(/[\s\-']+/)
    .filter(Boolean)
    .flatMap(splitWord)
    .map(parseSyllable)
    .filter(s => s.base);
}

/* 素の音節（声調無視）でLCSを取り、声調だけの差を分離する */
function alignSyllables(expected, actual){
  const n = expected.length, m = actual.length;
  const dp = Array.from({length:n+1}, () => new Int32Array(m+1));
  for (let i=n-1;i>=0;i--)
    for (let j=m-1;j>=0;j--)
      dp[i][j] = expected[i].base === actual[j].base
        ? dp[i+1][j+1] + 1
        : Math.max(dp[i+1][j], dp[i][j+1]);

  // ei/ai は元の配列での位置。特定の音節の対応先を引くのに使う。
  const rows = [];
  let i=0, j=0;
  while (i<n && j<m){
    if (expected[i].base === actual[j].base){
      rows.push({ kind: expected[i].tone === actual[j].tone ? "ok" : "tone",
                  exp: expected[i], act: actual[j], ei:i, ai:j });
      i++; j++;
    } else if (dp[i+1][j] >= dp[i][j+1]){
      rows.push({ kind:"del", exp: expected[i], act:null, ei:i, ai:null }); i++;
    } else {
      rows.push({ kind:"ins", exp:null, act: actual[j], ei:null, ai:j }); j++;
    }
  }
  while (i<n){ rows.push({ kind:"del", exp: expected[i], act:null, ei:i, ai:null }); i++; }
  while (j<m){ rows.push({ kind:"ins", exp:null, act: actual[j], ei:null, ai:j }); j++; }

  // 隣り合う del/ins は「置換」にまとめる
  const merged = [];
  for (let k=0;k<rows.length;k++){
    const a = rows[k], b = rows[k+1];
    if (a && b && ((a.kind==="del"&&b.kind==="ins")||(a.kind==="ins"&&b.kind==="del"))){
      merged.push({ kind:"sub", exp:(a.exp||b.exp), act:(a.act||b.act),
                    ei:(a.ei ?? b.ei), ai:(a.ai ?? b.ai) });
      k++;
    } else merged.push(a);
  }
  return merged;
}

/* ============================================================
   WAV（録音とTTSの両方が使う）
   ============================================================ */

/** 生PCM16（リトルエンディアン・モノラル）にWAVヘッダーを付ける。 */
function wavFromPcm16(pcm, rate){
  const out = new Uint8Array(44 + pcm.length);
  const v = new DataView(out.buffer);
  const str = (off, s) => { for (let i=0;i<s.length;i++) v.setUint8(off+i, s.charCodeAt(i)); };
  str(0,"RIFF"); v.setUint32(4, 36+pcm.length, true); str(8,"WAVE");
  str(12,"fmt "); v.setUint32(16,16,true); v.setUint16(20,1,true); v.setUint16(22,1,true);
  v.setUint32(24,rate,true); v.setUint32(28,rate*2,true); v.setUint16(32,2,true); v.setUint16(34,16,true);
  str(36,"data"); v.setUint32(40, pcm.length, true);
  out.set(pcm, 44);
  return out;
}

/** Float32のサンプル列を16bit PCMのWAVにする。 */
function encodeWav(samples, rate){
  const pcm = new Uint8Array(samples.length*2);
  const v = new DataView(pcm.buffer);
  for (let i=0;i<samples.length;i++){
    const s = Math.max(-1, Math.min(1, samples[i]));
    v.setInt16(i*2, s<0 ? s*0x8000 : s*0x7FFF, true);
  }
  return wavFromPcm16(pcm, rate);
}

function resample(input, from, to){
  if (from === to) return input;
  const ratio = from / to;
  const out = new Float32Array(Math.floor(input.length / ratio));
  for (let i=0;i<out.length;i++){
    const pos = i * ratio, lo = Math.floor(pos), hi = Math.min(lo+1, input.length-1);
    out[i] = input[lo] + (input[hi]-input[lo]) * (pos-lo);
  }
  return out;
}

function bytesToB64(bytes){
  let s = "";
  for (let i=0;i<bytes.length;i+=0x8000) s += String.fromCharCode.apply(null, bytes.subarray(i, i+0x8000));
  return btoa(s);
}

function b64ToBytes(b64){
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i=0;i<bin.length;i++) out[i] = bin.charCodeAt(i);
  return out;
}

/* ============================================================
   Gemini
   ============================================================ */

const PRICE_IN = 0.75, PRICE_OUT = 3.75; // USD / 1M tokens（DESIGN.md の導入価格）
const API_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

const zeroUsage = () => ({ prompt:0, candidates:0, thoughts:0 });
const addUsage = (a,b) => ({ prompt:a.prompt+b.prompt, candidates:a.candidates+b.candidates, thoughts:a.thoughts+b.thoughts });
const costOf = u => (u.prompt*PRICE_IN + (u.candidates+u.thoughts)*PRICE_OUT) / 1e6;

function readUsage(data){
  const um = data.usageMetadata || {};
  return { prompt: um.promptTokenCount||0, candidates: um.candidatesTokenCount||0, thoughts: um.thoughtsTokenCount||0 };
}

async function postGemini({ apiKey, model, body }){
  if (!apiKey) throw new Error("APIキーが未入力です。");
  const res = await fetch(`${API_BASE}/${encodeURIComponent(model)}:generateContent`,
    { method:"POST", headers:{ "Content-Type":"application/json", "x-goog-api-key": apiKey }, body: JSON.stringify(body) });
  const text = await res.text();
  if (!res.ok) throw new Error(`Gemini API ${res.status}: ${text.slice(0,400)}`);
  return JSON.parse(text);
}

/** 構造化出力でテキスト生成。schema を省くとプレーンテキスト。 */
async function callGemini({ apiKey, model, thinking, parts, schema, ordering }){
  const generationConfig = {};
  if (schema){
    generationConfig.responseMimeType = "application/json";
    generationConfig.responseSchema = {
      type:"OBJECT", properties: schema, required: Object.keys(schema),
      // 生成順を固定する。ピンインと漢字のどちらを先に出させるかがこの実験の肝。
      propertyOrdering: ordering || Object.keys(schema)
    };
  }
  if (thinking) generationConfig.thinkingConfig = { thinkingLevel: "low" };
  const data = await postGemini({ apiKey, model, body:{ contents:[{ parts }], generationConfig } });
  const raw = (data.candidates?.[0]?.content?.parts || []).map(p => p.text || "").join("").trim();
  return { raw, json: schema ? JSON.parse(raw) : null, usage: readUsage(data) };
}

/** テキストを読み上げてWAVにする。Gemini TTSは 24kHz モノラルの生PCM16を返す。 */
async function synthesize({ apiKey, model, voice, text }){
  const data = await postGemini({ apiKey, model, body:{
    contents:[{ parts:[{ text }] }],
    generationConfig:{
      responseModalities:["AUDIO"],
      speechConfig:{ voiceConfig:{ prebuiltVoiceConfig:{ voiceName: voice } } }
    }
  }});
  const part = (data.candidates?.[0]?.content?.parts || []).find(p => p.inlineData || p.inline_data);
  const inline = part && (part.inlineData || part.inline_data);
  if (!inline) throw new Error("TTSが音声を返しませんでした: " + JSON.stringify(data).slice(0,300));
  const mime = inline.mimeType || inline.mime_type || "";
  const rate = Number(/rate=(\d+)/.exec(mime)?.[1] || 24000);
  return { audio: { bytes: wavFromPcm16(b64ToBytes(inline.data), rate), mime:"audio/wav" },
           usage: readUsage(data), rate, sourceMime: mime };
}

const audioPart = audio => ({ inline_data: { mime_type: audio.mime, data: bytesToB64(audio.bytes) } });

const PINYIN_RULES = `あなたは中国語の音声を音声学的に書き起こす専門家です。話者は中国語学習者（日本語母語）で、声調を間違えている可能性があります。
最重要ルール:
- ピンインは「実際に聞こえた音」をそのまま書くこと。声調記号は聞こえたピッチのとおりに付ける。
- 語彙的に正しい声調に直してはいけない。単語として不自然な声調になっても、聞こえたままを書く。
- 意味や文脈から声調を推測しないこと。ピッチの高さ・変化だけを根拠にする。
- 声調が判断できない音節は軽声（記号なし）とする。
- 変調（3声連続・一・不）は実際に発音されたとおりに書く。
- 中国語の発話が聞き取れない場合は空文字を返す。聞こえない語を推測して補ってはいけない。`;

const SCHEMA_PINYIN = { pinyin: { type:"STRING", description:"実際に聞こえたとおりの声調付きピンイン。音節ごとに半角スペース区切り。" } };
const SCHEMA_HANZI  = { hanzi:  { type:"STRING", description:"発話の簡体字書き起こし。" } };

/** モードに応じて音声を書き起こし、{pinyin, hanzi, calls} を返す。 */
async function transcribeByMode({ apiKey, model, thinking, mode, audio }){
  const calls = [];
  const cfg = { apiKey, model, thinking };

  if (mode === "twoPass"){
    const p = await callGemini({ ...cfg, schema: SCHEMA_PINYIN,
      parts:[{ text: PINYIN_RULES + "\n\nこの音声をピンインのみで書き起こしてください。漢字は書かないこと。" }, audioPart(audio)] });
    calls.push({ label:"ピンイン専用コール", ...p });
    const h = await callGemini({ ...cfg, schema: SCHEMA_HANZI,
      parts:[{ text:"この中国語の発話を簡体字で verbatim に書き起こしてください。聞き取れない場合は空文字。聞こえない語を推測して補わないこと。" }, audioPart(audio)] });
    calls.push({ label:"漢字コール", ...h });
    return { pinyin: p.json.pinyin, hanzi: h.json.hanzi, calls };
  }

  const pinyinFirst = mode === "pinyinFirst";
  const ordering = pinyinFirst ? ["pinyin","hanzi"] : ["hanzi","pinyin"];
  const r = await callGemini({ ...cfg, ordering,
    schema: pinyinFirst ? { ...SCHEMA_PINYIN, ...SCHEMA_HANZI } : { ...SCHEMA_HANZI, ...SCHEMA_PINYIN },
    parts:[{ text: PINYIN_RULES + `\n\nこの音声を書き起こし、pinyin と hanzi の両方を返してください。${
      pinyinFirst ? "pinyin を先に、音だけを根拠に確定させてから hanzi を書くこと。"
                  : "hanzi を先に確定させてから pinyin を書くこと。"}` }, audioPart(audio)] });
  calls.push({ label:`1コール（${ordering.join(" → ")}）`, ...r });
  return { pinyin: r.json.pinyin, hanzi: r.json.hanzi, calls };
}

/** 漢字から標準ピンインを出す。音声を渡さないので、聞こえた音が混入しない。 */
async function canonicalPinyin({ apiKey, model, thinking, hanzi }){
  return await callGemini({ apiKey, model, thinking, ordering:["pinyin","notes"],
    schema:{ pinyin:{ type:"STRING" }, notes:{ type:"STRING", description:"変調を適用した箇所があれば日本語で簡潔に。無ければ空文字。" } },
    parts:[{ text:`次の中国語の文の標準的なピンインを、実際の発音どおりに（変調を適用して）書いてください。
- 3声の連続は 2声+3声 に、「一」「不」の変調も実際の発音に合わせる。
- 音節ごとに半角スペースで区切る。
- 軽声は声調記号なし。
文: ${hanzi}` }] });
}
