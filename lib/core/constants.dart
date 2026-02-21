class AppConstants {
  // TODO: Supabase project URL / anon key を入力
class Constants {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
  // TODO: Render のAI中継URL（末尾スラッシュなし）
  // 例: https://apex-ai-u52h.onrender.com
  static const aiProxyBaseUrl = 'https://apex-ai-1.onrender.com';

  static const appName = 'APEXFIT';
}
