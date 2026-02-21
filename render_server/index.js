import express from "express";
import cors from "cors";

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

const PORT = process.env.PORT || 3000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

function requireKey(res) {
  if (!GEMINI_API_KEY) {
    res.status(500).json({ error: "GEMINI_API_KEY is not set" });
    return false;
  }
  return true;
}

async function gemini(prompt) {
  const url =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" +
    encodeURIComponent(GEMINI_API_KEY);

  const body = {
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.6, maxOutputTokens: 1024 }
  };

  const r = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });

  const j = await r.json();
  if (!r.ok) {
    throw new Error(JSON.stringify(j));
  }
  const text =
    j?.candidates?.[0]?.content?.parts?.map((p) => p.text).join("") ?? "";
  return text;
}

function buildMealPrompt(payload) {
  return `
あなたはフィットネスアプリAPEXFITの食事プランAIです。
出力は必ずJSON配列のみ。各要素は { "title": string, "detail": string }。
日本語、簡潔、現実的。

ユーザー情報: ${JSON.stringify(payload.user)}
直近サマリー: ${JSON.stringify(payload.summary)}
要望: ${JSON.stringify(payload.request)}

制約:
- 1日の食事案（朝/昼/夜/間食）を提案
- カロリー目標に寄せる（指定がなければ2000kcal目安）
- アレルギー等は不明なので注意文をdetail末尾に1行入れる
`.trim();
}

function buildWorkoutPrompt(payload) {
  return `
あなたはフィットネスアプリAPEXFITのワークアウトAIです。
出力は必ずJSON配列のみ。各要素は { "title": string, "detail": string }。
日本語、簡潔、現実的。

ユーザー情報: ${JSON.stringify(payload.user)}
直近サマリー: ${JSON.stringify(payload.summary)}
要望: ${JSON.stringify(payload.request)}

制約:
- 1回分のメニュー（準備運動→メイン→クールダウン）
- 初心者〜中級者向け、無理しない注意をdetail末尾に1行
`.trim();
}

async function respondJsonArray(res, text) {
  // try to extract JSON array
  const m = text.match(/\[[\s\S]*\]/);
  const raw = m ? m[0] : text;
  try {
    const arr = JSON.parse(raw);
    if (!Array.isArray(arr)) throw new Error("Not array");
    res.json(arr);
  } catch (e) {
    res.status(500).json({ error: "AI output parse failed", raw: text.slice(0, 800) });
  }
}

app.get("/", (_, res) => res.send("APEXFIT AI Proxy OK"));

app.post("/generate_meal_plan", async (req, res) => {
  if (!requireKey(res)) return;
  try {
    const prompt = buildMealPrompt(req.body ?? {});
    const text = await gemini(prompt);
    await respondJsonArray(res, text);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.post("/generate_workout_plan", async (req, res) => {
  if (!requireKey(res)) return;
  try {
    const prompt = buildWorkoutPrompt(req.body ?? {});
    const text = await gemini(prompt);
    await respondJsonArray(res, text);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.listen(PORT, () => console.log("Listening on", PORT));
