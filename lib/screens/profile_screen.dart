import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserService userService;
  const ProfileScreen({super.key, required this.userService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  UserProfile? _profile;

  final _username = TextEditingController();
  final _targetCalories = TextEditingController();
  final _targetWeight = TextEditingController();
  final _height = TextEditingController();
  String? _gender;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
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

  Future<void> _load() async {
    final u = _user;
    if (u == null) return;

    setState(() => _loading = true);
    try {
      final p = await widget.userService.getProfile(u.id);
      setState(() {
        _profile = p;
        _username.text = p.username ?? '';
        _targetCalories.text = p.targetCalories?.toString() ?? '';
        _targetWeight.text = p.targetWeight?.toString() ?? '';
        _height.text = p.height?.toString() ?? '';
        _gender = p.gender;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('取得失敗: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final u = _user;
    if (u == null) return;

    setState(() => _loading = true);
    try {
      await widget.userService.updateProfile(
        u.id,
        username: _username.text.trim(),
        targetCalories: int.tryParse(_targetCalories.text.trim()),
        targetWeight: double.tryParse(_targetWeight.text.trim()),
        height: int.tryParse(_height.text.trim()),
        gender: _gender,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失敗: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    if (u == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(onPressed: _loading ? null : _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: _loading && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('メール: ${u.email ?? '-'}'),
                  const SizedBox(height: 16),
                  TextField(controller: _username, decoration: const InputDecoration(labelText: 'ユーザー名')),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: '性別'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('男性')),
                      DropdownMenuItem(value: 'female', child: Text('女性')),
                      DropdownMenuItem(value: 'other', child: Text('その他')),
                      DropdownMenuItem(value: 'prefer_not_to_say', child: Text('回答しない')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _targetCalories,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '目標摂取カロリー(kcal)'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _targetWeight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: '目標体重(kg)'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '身長(cm)'),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('保存'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: _logout,
                      child: const Text('ログアウト'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
