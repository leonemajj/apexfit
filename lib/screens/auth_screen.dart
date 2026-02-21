import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/palette.dart';
import '../../core/ui.dart';
import '../../core/text_styles.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;

  bool _agreed = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用規約とプライバシーポリシーに同意してください')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;

      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _pass.text.trim(),
        );
      } else {
        final res = await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _pass.text.trim(),
        );

        // usersテーブルへ初期プロフィール
        if (res.user != null) {
          await supabase.from('users').upsert({
            'id': res.user!.id,
            'username': res.user!.email?.split('@').first ?? 'user',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('エラー: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppPalette.heroGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: PremiumCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('APEXFIT', style: AppText.h1(context)),
                      const SizedBox(height: 6),
                      Text('あなたの記録とAIプランで継続を強くする。', style: AppText.muted(context)),
                      const SizedBox(height: 18),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              decoration: AppUI.inputDecoration(context, 'メールアドレス', prefixIcon: const Icon(Icons.mail_outline)),
                              validator: (v) => (v == null || v.isEmpty) ? '入力してください' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pass,
                              obscureText: true,
                              decoration: AppUI.inputDecoration(context, 'パスワード', prefixIcon: const Icon(Icons.lock_outline)),
                              validator: (v) => (v == null || v.length < 6) ? '6文字以上で入力してください' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (v) => setState(() => _agreed = v ?? false),
                            activeColor: AppPalette.accent,
                          ),
                          Expanded(
                            child: Text(
                              '利用規約・プライバシーポリシーに同意します',
                              style: AppText.muted(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      AccentButton(
                        text: _isLogin ? 'ログイン' : '新規登録',
                        icon: Icons.arrow_forward_rounded,
                        loading: _loading,
                        onPressed: _submit,
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin ? 'アカウント作成はこちら' : 'すでにアカウントがあります',
                            style: AppText.muted(context).copyWith(color: AppPalette.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
