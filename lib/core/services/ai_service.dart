import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class AiService {
  Future<List<dynamic>> generateMealPlan(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${AppConstants.aiProxyBaseUrl}/generate_meal_plan');
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(payload));
    if (res.statusCode != 200) {
      throw Exception('AIエラー: ${res.statusCode} ${res.body}');
    }
    return json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  Future<List<dynamic>> generateWorkoutPlan(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${AppConstants.aiProxyBaseUrl}/generate_workout_plan');
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: json.encode(payload));
    if (res.statusCode != 200) {
      throw Exception('AIエラー: ${res.statusCode} ${res.body}');
    }
    return json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }
}
