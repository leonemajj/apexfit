import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/meal.dart';
import '../../models/workout.dart';

class SummaryService {
  static const String _mealSummaryKey = 'meal_summary';
  static const String _workoutSummaryKey = 'workout_summary';

  Future<void> saveMealSummary(List<Meal> meals) async {
    final prefs = await SharedPreferences.getInstance();
    if (meals.isEmpty) {
      await prefs.remove(_mealSummaryKey);
      return;
    }
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recent = meals.where((m) => m.mealDate.isAfter(sevenDaysAgo)).toList()
      ..sort((a, b) => b.mealDate.compareTo(a.mealDate));

    if (recent.isEmpty) {
      await prefs.remove(_mealSummaryKey);
      return;
    }

    final summary = <String, dynamic>{
      'last_meal_date': DateFormat('yyyy-MM-dd').format(recent.first.mealDate),
      'average_daily_calories_last_7_days': _avgDailyCalories(recent),
      'meal_type_distribution': _mealTypeDist(recent),
    };
    await prefs.setString(_mealSummaryKey, json.encode(summary));
  }

  double _avgDailyCalories(List<Meal> meals) {
    final Map<String, int> daily = {};
    for (final m in meals) {
      final d = DateFormat('yyyy-MM-dd').format(m.mealDate);
      daily.update(d, (v) => v + m.totalCalories, ifAbsent: () => m.totalCalories);
    }
    if (daily.isEmpty) return 0.0;
    final total = daily.values.fold<int>(0, (s, v) => s + v);
    return total / daily.length;
  }

  Map<String, int> _mealTypeDist(List<Meal> meals) {
    final Map<String, int> dist = {};
    for (final m in meals) {
      dist.update(m.mealType, (v) => v + 1, ifAbsent: () => 1);
    }
    return dist;
  }

  Future<String?> getMealSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mealSummaryKey);
  }

  Future<void> saveWorkoutSummary(List<Workout> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    if (workouts.isEmpty) {
      await prefs.remove(_workoutSummaryKey);
      return;
    }
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recent = workouts.where((w) => w.workoutDate.isAfter(sevenDaysAgo)).toList()
      ..sort((a, b) => b.workoutDate.compareTo(a.workoutDate));

    if (recent.isEmpty) {
      await prefs.remove(_workoutSummaryKey);
      return;
    }

    final summary = <String, dynamic>{
      'last_workout_date': DateFormat('yyyy-MM-dd').format(recent.first.workoutDate),
      'total_workouts_last_7_days': recent.length,
      'average_calories_burned_per_workout': _avgCaloriesBurned(recent),
      'workout_type_distribution': _workoutTypeDist(recent),
    };
    await prefs.setString(_workoutSummaryKey, json.encode(summary));
  }

  double _avgCaloriesBurned(List<Workout> workouts) {
    if (workouts.isEmpty) return 0.0;
    final total = workouts.fold<int>(0, (s, w) => s + w.totalCaloriesBurned);
    return total / workouts.length;
  }

  Map<String, int> _workoutTypeDist(List<Workout> workouts) {
    final Map<String, int> dist = {};
    for (final w in workouts) {
      dist.update(w.workoutType, (v) => v + 1, ifAbsent: () => 1);
    }
    return dist;
  }

  Future<String?> getWorkoutSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_workoutSummaryKey);
  }
}
