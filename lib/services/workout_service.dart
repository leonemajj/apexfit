import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout.dart';

class WorkoutService {
  final SupabaseClient _client;
  WorkoutService(this._client);

  SupabaseClient get client => _client;

  Future<void> addWorkout(String workoutType, DateTime workoutDate, int durationMinutes, int calories, {String? notes}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    await _client.from('workouts').insert({
      'user_id': user.id,
      'workout_type': workoutType,
      'workout_date': workoutDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_calories_burned': calories,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Workout>> streamWorkouts() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value([]);
    return _client
        .from('workouts')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('workout_date', ascending: false)
        .map((rows) => rows.map((r) => Workout.fromJson(r)).toList());
  }

  Future<void> updateWorkout(String id, {String? workoutType, DateTime? workoutDate, int? durationMinutes, int? calories, String? notes}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    final updates = <String, dynamic>{};
    if (workoutType != null) updates['workout_type'] = workoutType;
    if (workoutDate != null) updates['workout_date'] = workoutDate.toIso8601String();
    if (durationMinutes != null) updates['duration_minutes'] = durationMinutes;
    if (calories != null) updates['total_calories_burned'] = calories;
    if (notes != null) updates['notes'] = notes;
    if (updates.isEmpty) return;
    await _client.from('workouts').update(updates).eq('id', id).eq('user_id', user.id);
  }

  Future<void> deleteWorkout(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');
    await _client.from('workouts').delete().eq('id', id).eq('user_id', user.id);
  }
}
