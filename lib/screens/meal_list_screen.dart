import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apex_ai/meal.dart';
import 'package:apex_ai/meal_entry_screen.dart';
import 'package:apex_ai/meal_service.dart';
import 'package:apex_ai/summary_service.dart';
import 'package:apex_ai/user_service.dart';

import 'package:apex_ai/services/ai_service.dart';
import 'package:apex_ai/widgets/plan_bottom_sheet.dart';

class MealListScreen extends StatefulWidget {
  final MealService mealService;
  final UserService userService; // ✅追加（ターゲットカロリー取得）
  final SupabaseClient supabase;
  final String flaskBaseUrl; // ✅Render URL

  const MealListScreen({
    super.key,
    required this.mealService,
    required this.userService,
    required this.supabase,
    required this.flaskBaseUrl,
  });

  @override
  State<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  User? _currentUser;
  late final StreamSubscription<AuthState> _authStateSubscription;
  late final SummaryService _summaryService;
  late final AiService _aiService;

  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.supabase.auth.currentUser;
    _summaryService = SummaryService();
    _aiService = AiService(supabase: widget.supabase, baseUrl: widget.flaskBaseUrl);

    _authStateSubscription =
        widget.supabase.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      setState(() {
        _currentUser = data.session?.user;
        if (_currentUser == null) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });

      await _updateMealSummary();
    });

    _updateMealSummary();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _updateMealSummary() async {
    if (_currentUser == null) return;
    final meals = await widget.mealService.getRealtimeMealsStream().first;
    await _summaryService.saveMealSummary(meals);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _addMeal() async {
    if (_currentUser == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealEntryScreen(mealService: widget.mealService),
      ),
    );
    _updateMealSummary();
  }

  void _editMeal(Meal meal) async {
    if (_currentUser == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealEntryScreen(
          mealService: widget.mealService,
          mealToEdit: meal,
        ),
      ),
    );
    _updateMealSummary();
  }

  void _deleteMeal(int mealId) {
    if (_currentUser == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('食事を削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.mealService.deleteMeal(mealId).then((_) {
                _showSnackBar('食事を削除しました。');
                _updateMealSummary();
              }).catchError((e) {
                _showSnackBar('削除失敗: $e', isError: true);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  // ✅ AI生成（食事プラン）
  Future<void> _generateMealPlanAi() async {
    if (_currentUser == null) return;

    setState(() => _aiLoading = true);

    try {
      final profile = await widget.userService.getUserProfile(_currentUser!.id);

      if (profile.targetCalories == null) {
        throw Exception('プロフィールで目標摂取カロリーを設定してください。');
      }

      // 過去要約
      final pastMealSummary = await _summaryService.getMealSummary();

      // PFC 仮
      final pfc = {'protein': 0.30, 'fat': 0.20, 'carbs': 0.50};

      _showSnackBar('AIが食事プランを生成中...');

      final plan = await _aiService.generateMealPlan(
        dailyCalories: profile.targetCalories!,
        pfcRatio: pfc,
        mealCount: 3,
        pastMealSummary: pastMealSummary,
      );

      if (!mounted) return;

      PlanBottomSheet.show(
        context,
        title: 'AI 食事プラン',
        plan: plan,
        itemBuilder: (item) => _buildMealPlanItem(context, item),
      );
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Widget _buildMealPlanItem(BuildContext context, Map<String, dynamic> item) {
    final dishes = (item['dishes'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['meal_name']?.toString() ?? '食事',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...dishes.map((d) => Text('・$d', style: const TextStyle(color: Colors.white70))),
          const SizedBox(height: 12),
          Text(
            'P:${item['estimated_protein']}g  F:${item['estimated_fat']}g  C:${item['estimated_carbs']}g',
            style: const TextStyle(color: Colors.white60),
          ),
          Text(
            '推定: ${item['estimated_calories']} kcal',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('食事記録'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMeal,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ AIボタン（上部）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aiLoading ? null : _generateMealPlanAi,
                icon: _aiLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_aiLoading ? '生成中...' : 'AI 食事プラン生成（Premium）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16161B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Meal>>(
              stream: widget.mealService.getRealtimeMealsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('エラー: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      '食事記録がありません。\n右上の+で追加できます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final meals = snapshot.data!;
                _summaryService.saveMealSummary(meals);

                return ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        title: Text(
                          '${meal.mealType} - ${meal.mealDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${meal.totalCalories} kcal\n${meal.notes ?? ''}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteMeal(meal.id),
                        ),
                        onTap: () => _editMeal(meal),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
