import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AiService {
  final SupabaseClient supabase;
  final String baseUrl;

  AiService({
    required this.supabase,
    required this.baseUrl,
  });

  Future<String> _getAccessToken() async {
    final session = supabase.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw Exception('ログインしていません（tokenなし）');
    }
    return token;
  }

  Future<List<dynamic>> generateMealPlan({
    required int dailyCalories,
    required Map<String, double> pfcRatio,
    int mealCount = 3,
    String? pastMealSummary,
  }) async {
    final token = await _getAccessToken();

    final body = {
      'daily_calories': dailyCalories,
      'pfc_ratio': pfcRatio,
      'meal_count': mealCount,
      'past_meal_summary': pastMealSummary,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/generate_meal_plan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }

    if (res.statusCode == 402) {
      throw Exception('食事AIはプレミアム限定です。');
    }

    throw Exception('生成失敗: ${res.statusCode} ${res.body}');
  }

  Future<List<dynamic>> generateWorkoutPlan({
    String level = 'beginner',
    int frequency = 3,
    String goal = 'maintain_weight',
    String? pastWorkoutSummary,
    String? gender,
  }) async {
    final token = await _getAccessToken();

    final body = {
      'level': level,
      'frequency': frequency,
      'goal': goal,
      'gender': gender,
      'past_workout_summary': pastWorkoutSummary,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/generate_workout_plan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }

    throw Exception('生成失敗: ${res.statusCode} ${res.body}');
  }
}
