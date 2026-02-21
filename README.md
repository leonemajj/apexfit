<<<<<<< HEAD
# apexfit
=======
# APEXFIT（Flutter + Supabase + Gemini(Render中継)）

このZIPは「完成版の中身（lib/ と設定ファイル）」です。
Flutterプロジェクトの土台（android/iosなど）は **あなたのPCで作成** します。

---

## 0) 必要なもの
- Flutter (あなた: stable 3.35.6 OK)
- Supabase プロジェクト（URL / anon key）
- Render（無料でOK） + Gemini API Key

---

## 1) Flutterプロジェクト作成（Windows）
1. 任意フォルダで:
   ```bash
   flutter create apexfit
   ```
2. 作成された `apexfit/` を開く
3. このZIPの中身を `apexfit/` に **上書きコピー**
   - `pubspec.yaml`
   - `lib/`
   - `assets/`
   - `supabase/`
   - `render_server/`
   - `README.md`

4. 依存取得:
   ```bash
   flutter pub get
   ```

---

## 2) Supabase 設定（DB / RLS / Storage）
### 2-1) SQL実行
Supabase Dashboard → SQL Editor で順番に実行:
- `supabase/sql/01_tables.sql`
- `supabase/sql/02_rls_policies.sql`

### 2-2) Storage（アバター）
1. Dashboard → Storage → Create bucket → **avatars**
2. Bucketを **Public** にする（簡単運用）
3. SQL Editorで:
- `supabase/sql/03_storage.sql`

> すでにポリシーがあると `42710 already exists` が出ます。  
> その場合は、今の設定が生きているので **スキップでOK** です。

### 2-3) Auth
- Dashboard → Authentication → Providers
  - まずは **Email** だけでOK（Apple/Googleは後回しでOK）
- 本番を想定するなら
  - パスワード漏洩保護（HaveIBeenPwned）ON推奨
  - SMTPは本番は外部SMTP推奨（今はそのままでOK）

---

## 3) Flutter側の「入力が必要」な場所（ここだけ）
`lib/core/constants.dart` を開いて、次を入れる:

- `supabaseUrl`
- `supabaseAnonKey`
- `aiProxyBaseUrl`（Renderにデプロイ後のURL）

---

## 4) Render（Gemini中継）設定
### 4-1) GitHubへ上げる
このZIPの `render_server/` フォルダを、あなたのGitHubリポジトリに入れる  
（Flutterと同じrepoでもOK）

### 4-2) RenderでWeb Service作成
Render → New → Web Service
- Root Directory: `render_server`
- Build Command: `npm install`
- Start Command: `npm start`
- Environment Variables:
  - `GEMINI_API_KEY` = あなたのGemini API Key

デプロイ後URLが出るので、それを `aiProxyBaseUrl` に設定。

### 4-3) 動作確認
ブラウザで:
- `https://<render-url>/` にアクセスして `APEXFIT AI Proxy OK` が出ればOK

---

## 5) 実行
```bash
flutter run
```

---

## 6) 画面構成（今の完成版）
- ログイン（メール/パスワード） + 同意チェック
- ホーム：体重折れ線 / 食事タイプ円グラフ / 運動タイプ円グラフ
- 食事プラン：記録、編集、削除、**AI生成（Premium限定・開発用トグル）**
- ワークアウト：記録、編集、削除、**AI生成**、セッション（タイマー）
- 体重：日付入力、記録、履歴
- プロフィール：目標入力、アバターアップロード、Premium(開発用)、規約/ポリシー

---

## 7) よくあるエラー
### 「lib/main.dart がない」
このZIPは `lib/main.dart` を含みます。  
ただし **flutter create したプロジェクト**に上書きコピーしていないと起きます。

### Storage policy already exists
すでに作成済みなのでOK（スキップでOK）。

---

## 8) 後であなたが付け足す場所（目印）
- AIプロンプト改善: `render_server/index.js`
- Premium本実装（課金）: `lib/core/services/premium_service.dart` を in_app_purchase に置換
- 目標を部位ごとに細かく: `lib/features/profile/profile_screen.dart`
- 音声AIコーチ: 追加予定（UI文言はProfile/Workoutに入れてあります）
>>>>>>> 23feb37 (APEXFIT initial commit)
