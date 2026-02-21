import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weight.dart';

class WeightService {
  final SupabaseClient _client;
  WeightService(this._client);

  SupabaseClient get client => _client;

  Future<void> addOrUpdate(DateTime date, double kg) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    final d = DateFormat('yyyy-MM-dd').format(date);

    final existing = await _client.from('weights').select().eq('user_id', user.id).eq('date', d).limit(1);
    if (existing.isNotEmpty) {
      await _client.from('weights').update({'weight_kg': kg, 'updated_at': DateTime.now().toIso8601String()}).eq('id', existing[0]['id']);
    } else {
      await _client.from('weights').insert({'user_id': user.id, 'date': d, 'weight_kg': kg, 'created_at': DateTime.now().toIso8601String()});
    }
  }

  Stream<List<Weight>> streamWeights() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);
    return _client.from('weights')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('date', ascending: false)
        .map((rows) => rows.map((r) => Weight.fromJson(r)).toList());
  }
}
