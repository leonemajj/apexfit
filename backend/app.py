import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS

import google.generativeai as genai

# -----------------------------
# App setup
# -----------------------------
app = Flask(__name__)
CORS(app)

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_API_KEY:
  # 起動自体はするが、API実行時にエラーを返す
  print("⚠️ GEMINI_API_KEY is not set")

genai.configure(api_key=GEMINI_API_KEY)

# モデルは安定運用しやすいものを選択（必要なら後で変更OK）
MODEL_NAME = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash")
model = genai.GenerativeModel(MODEL_NAME)

# -----------------------------
# Helpers
# -----------------------------
def _bad_request(msg: str):
  return jsonify({"error": msg}), 400

def _server_error(msg: str):
  return jsonify({"error": msg}), 500

def _parse_json_body():
  if not request.data:
    return None
  try:
    return request.get_json(force=True)
  except Exception:
    return None

def _safe_json_loads(s: str):
  try:
    return json.loads(s)
  except Exception:
    return None

def _extract_json_from_text(text: str):
  """
  Geminiが余計な文章を返しても、最初に出てくるJSON配列/JSONオブジェクトを抽出する。
  """
  if not text:
    return None

  text = text.strip()

  # そのままJSONとして読めるか
  parsed = _safe_json_loads(text)
  if parsed is not None:
    return parsed

  # ```json ... ``` を除去して再トライ
  if "```" in text:
    cleaned = []
    in_fence = False
    for line in text.splitlines():
      if line.strip().startswith("```"):
        in_fence = not in_fence
        continue
      cleaned.append(line)
    cleaned_text = "\n".join(cleaned).strip()
    parsed = _safe_json_loads(cleaned_text)
    if parsed is not None:
      return parsed

  # JSON開始/終了っぽいところを探す（配列 or オブジェクト）
  candidates = []
  for start_char, end_char in [("[", "]"), ("{", "}")]:
    start = text.find(start_char)
    end = text.rfind(end_char)
    if start != -1 and end != -1 and end > start:
      candidates.append(text[start : end + 1])

  for c in candidates:
    parsed = _safe_json_loads(c)
    if parsed is not None:
      return parsed

  return None


def _gemini_generate_json(prompt: str):
  """
  Geminiに「JSONだけ返せ」を強制しつつ、抽出にも対応。
  """
  if not GEMINI_API_KEY:
    return None, "GEMINI_API_KEY が未設定です（RenderのEnvironmentで設定してください）"

  try:
    resp = model.generate_content(
      prompt,
      generation_config={
        "temperature": 0.7,
        "max_output_tokens": 2048,
      },
    )

    text = (resp.text or "").strip()
    parsed = _extract_json_from_text(text)
    if parsed is None:
      return None, f"GeminiがJSONを返しませんでした: {text[:200]}..."
    return parsed, None

  except Exception as e:
    return None, str(e)


# -----------------------------
# Routes
# -----------------------------
@app.get("/")
def health():
  return jsonify({"ok": True, "service": "APEXFIT Gemini Relay", "model": MODEL_NAME})


@app.post("/generate_meal_plan")
def generate_meal_plan():
  body = _parse_json_body()
  if body is None:
    return _bad_request("JSON body が必要です")

  daily_calories = body.get("daily_calories")
  meal_count = body.get("meal_count", 3)
  pfc_ratio = body.get("pfc_ratio", {"protein": 0.3, "fat": 0.2, "carbs": 0.5})
  past_meal_summary = body.get("past_meal_summary")  # 文字列JSONでもOK
  is_premium = bool(body.get("is_premium", False))

  if not is_premium:
    # ここで有料ガード（Flutter側でもUI制御するが、サーバ側でも止める）
    return jsonify({"error": "Meal AI はプレミアム限定です"}), 402

  if daily_calories is None:
    return _bad_request("daily_calories が必要です")

  prompt = f"""
あなたは日本の栄養士です。次の条件で「日本語」の食事プランを作ってください。

## 条件
- 1日の目標カロリー: {daily_calories}
- 食事回数: {meal_count}
- PFC比率(目安): protein={pfc_ratio.get("protein")}, fat={pfc_ratio.get("fat")}, carbs={pfc_ratio.get("carbs")}
- 過去の食事要約(参考): {past_meal_summary}

## 出力ルール（重要）
- **JSON配列のみ**を返す（説明文や見出しは一切不要）
- 各要素は次のキーを必ず持つ:
  - meal_name: string（例: 朝食 / 昼食 / 夕食）
  - dishes: string[]（具体的な料理名）
  - estimated_protein: number（g）
  - estimated_fat: number（g）
  - estimated_carbs: number（g）
  - estimated_calories: number（kcal）
"""

  parsed, err = _gemini_generate_json(prompt)
  if err:
    return _server_error(err)

  if not isinstance(parsed, list):
    return _server_error("JSON配列ではありませんでした")

  return jsonify(parsed)


@app.post("/generate_workout_plan")
def generate_workout_plan():
  body = _parse_json_body()
  if body is None:
    return _bad_request("JSON body が必要です")

  level = body.get("level", "beginner")
  frequency = body.get("frequency", 3)
  goal = body.get("goal", "maintain_weight")
  gender = body.get("gender", "prefer_not_to_say")
  past_workout_summary = body.get("past_workout_summary")

  prompt = f"""
あなたは日本語で答えるパーソナルトレーナーです。
次の条件で「1週間のワークアウトメニュー」を作ってください。

## 条件
- レベル: {level}
- 頻度: 週{frequency}回
- 目的: {goal}
- 性別(参考): {gender}
- 過去のワークアウト要約(参考): {past_workout_summary}

## 出力ルール（重要）
- **JSON配列のみ**を返す（説明文や見出しは一切不要）
- 配列要素は次のキーを必ず持つ:
  - day: string（例: Day1 / 火曜 など）
  - focus: string（例: 胸・三頭 / 下半身 / 有酸素 など）
  - exercises: array（各要素に必須キー）
      - name: string
      - sets: number
      - reps: number または duration: string（例 "20分"）
"""

  parsed, err = _gemini_generate_json(prompt)
  if err:
    return _server_error(err)

  if not isinstance(parsed, list):
    return _server_error("JSON配列ではありませんでした")

  return jsonify(parsed)


if __name__ == "__main__":
  port = int(os.environ.get("PORT", "5000"))
  app.run(host="0.0.0.0", port=port)