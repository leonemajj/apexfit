import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserService {
  final SupabaseClient _client;
  UserService(this._client);

  Future<UserProfile> getProfile(String userId) async {
    final res = await _client.from('users').select().eq('id', userId).single();
    return UserProfile.fromJson(res);
  }

  Future<void> upsertProfile(String userId, {String? email, String? username}) async {
    await _client.from('users').upsert({
      'id': userId,
      'email': email,
      'username': username,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateProfile(
    String userId, {
    String? username,
    int? targetCalories,
    double? targetWeight,
    int? height,
    String? gender,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (targetCalories != null) updates['target_calories'] = targetCalories;
    if (targetWeight != null) updates['target_weight'] = targetWeight;
    if (height != null) updates['height'] = height;
    if (gender != null) updates['gender'] = gender;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('users').update(updates).eq('id', userId);
  }
}
