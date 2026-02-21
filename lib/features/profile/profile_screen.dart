import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/apex_card.dart';
import '../../core/services/premium_service.dart';
import '../../services/user_service.dart';
import '../../services/image_upload_service.dart';
import 'legal_screen.dart';
import 'legal_texts.dart';

class ProfileScreen extends StatefulWidget {
  final UserService userService;
  final ImageUploadService imageUploadService;

  const ProfileScreen({super.key, required this.userService, required this.imageUploadService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _username = TextEditingController();
  final _targetCalories = TextEditingController();
  final _targetWeight = TextEditingController();
  final _height = TextEditingController();
  String _gender = '未設定';

  bool _loading = true;
  bool _premium = false;
  String? _avatarUrl;

  final _premiumService = PremiumService();

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: err ? Palette.danger : Palette.surface2));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profile = await widget.userService.getProfile(user.id);
      _username.text = profile.username ?? '';
      _targetCalories.text = profile.targetCalories?.toString() ?? '';
      _targetWeight.text = profile.targetWeight?.toString() ?? '';
      _height.text = profile.height?.toString() ?? '';
      _gender = profile.gender ?? '未設定';
      _avatarUrl = profile.avatarUrl;
      _premium = await _premiumService.isPremium();
    } catch (e) {
      _snack('読み込み失敗: $e', err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _username.dispose();
    _targetCalories.dispose();
    _targetWeight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await widget.userService.updateProfile(
        user.id,
        username: _username.text.trim(),
        targetCalories: int.tryParse(_targetCalories.text.trim()),
        targetWeight: double.tryParse(_targetWeight.text.trim()),
        height: int.tryParse(_height.text.trim()),
        gender: _gender == '未設定' ? null : _gender,
      );
      _snack('保存しました');
    } catch (e) {
      _snack('保存失敗: $e', err: true);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final url = await widget.imageUploadService.pickAndUploadAvatar(user.id);
      if (url != null) {
        setState(() => _avatarUrl = url);
        _snack('画像を更新しました');
      }
    } catch (e) {
      _snack('画像アップロード失敗: $e', err: true);
    }
  }

  Future<void> _togglePremium(bool v) async {
    await _premiumService.setPremium(v);
    setState(() => _premium = v);
    _snack(v ? 'Premium有効（開発用）' : 'Premium無効');
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(onPressed: _loading ? null : _save, icon: const Icon(Icons.save)),
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ApexCard(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Palette.surface2,
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null ? const Icon(Icons.person, size: 28) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.email ?? '', style: AppText.muted),
                            const SizedBox(height: 4),
                            Text(_username.text.isEmpty ? 'ユーザー' : _username.text, style: AppText.h2),
                          ],
                        ),
                      ),
                      Switch(value: _premium, onChanged: _togglePremium),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ApexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('目標', style: AppText.h2),
                      const SizedBox(height: 12),
                      TextField(controller: _username, decoration: const InputDecoration(labelText: 'ユーザー名')),
                      const SizedBox(height: 12),
                      TextField(controller: _targetCalories, decoration: const InputDecoration(labelText: '目標カロリー (kcal)'), keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      TextField(controller: _targetWeight, decoration: const InputDecoration(labelText: '目標体重 (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                      const SizedBox(height: 12),
                      TextField(controller: _height, decoration: const InputDecoration(labelText: '身長 (cm)'), keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        items: const ['未設定', '男性', '女性', 'その他'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => _gender = v ?? '未設定'),
                        decoration: const InputDecoration(labelText: '性別'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('保存'))),
                      const SizedBox(height: 6),
                      Text('将来実装: 音声AIコーチ / 有料決済 / 詳細な目標（部位別など）', style: AppText.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ApexCard(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('利用規約'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(title: '利用規約', text: termsText))),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('プライバシーポリシー'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(title: 'プライバシーポリシー', text: privacyText))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
