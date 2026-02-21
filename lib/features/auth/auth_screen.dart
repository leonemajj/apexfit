import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/apex_card.dart';
import '../../core/theme/palette.dart';
import '../../services/user_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loginMode = true;
  bool _agree = false;
  bool _loading = false;

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: err ? Palette.danger : Palette.surface2));
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _email.text.trim();
    final pass = _pass.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack('メールとパスワードを入力してください', err: true);
      return;
    }
    if (!_agree) {
      _snack('利用規約とプライバシーポリシーに同意してください', err: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      if (_loginMode) {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      } else {
        final res = await supabase.auth.signUp(email: email, password: pass);
        final user = res.user;
        if (user != null) {
          await UserService(supabase).upsertProfile(user.id, email: email);
        }
      }
    } on AuthException catch (e) {
      _snack(e.message, err: true);
    } catch (e) {
      _snack('エラー: $e', err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ApexCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('APEXFIT', style: AppText.h1),
                  const SizedBox(height: 6),
                  Text('記録×AIで継続を加速する', style: AppText.muted),
                  const SizedBox(height: 16),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'メールアドレス')),
                  const SizedBox(height: 12),
                  TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'パスワード')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                      Expanded(
                        child: Text('利用規約・プライバシーポリシーに同意します', style: AppText.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? '処理中...' : (_loginMode ? 'ログイン' : '新規登録')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : () => setState(() => _loginMode = !_loginMode),
                    child: Text(_loginMode ? '新規登録はこちら' : 'ログインはこちら'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ApexCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: const [
                  Icon(Icons.verified_user, color: Palette.accent),
                  SizedBox(width: 10),
                  Expanded(child: Text('注意: 医療行為ではありません。体調が悪い場合は医療機関へ。', style: TextStyle(color: Palette.textMuted))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
