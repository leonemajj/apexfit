import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal.dart';

class MealService {
  final SupabaseClient _client;
  MealService(this._client);

  SupabaseClient get client => _client;

  Future<void> addMeal(String mealType, DateTime mealDate, int totalCalories, {String? notes}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    await _client.from('meals').insert({
      'user_id': user.id,
      'meal_type': mealType,
      'meal_date': mealDate.toIso8601String(),
      'total_calories': totalCalories,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Meal>> streamMeals() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);
    return _client
        .from('meals')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('meal_date', ascending: false)
        .map((rows) => rows.map((r) => Meal.fromJson(r)).toList());
  }

  Future<void> updateMeal(int id, {String? mealType, DateTime? mealDate, int? totalCalories, String? notes}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    final updates = <String, dynamic>{};
    if (mealType != null) updates['meal_type'] = mealType;
    if (mealDate != null) updates['meal_date'] = mealDate.toIso8601String();
    if (totalCalories != null) updates['total_calories'] = totalCalories;
    if (notes != null) updates['notes'] = notes;
    if (updates.isEmpty) return;
    await _client.from('meals').update(updates).eq('id', id).eq('user_id', user.id);
  }

  Future<void> deleteMeal(int id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    await _client.from('meals').delete().eq('id', id).eq('user_id', user.id);
  }
}
