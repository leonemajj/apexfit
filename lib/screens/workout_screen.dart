import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apex_ai/workout.dart';
import 'package:apex_ai/workout_entry_screen.dart';
import 'package:apex_ai/workout_service.dart';
import 'package:apex_ai/summary_service.dart';
import 'package:apex_ai/user_service.dart';

import 'package:apex_ai/services/ai_service.dart';
import 'package:apex_ai/widgets/plan_bottom_sheet.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final UserService userService;
  final SupabaseClient supabase;
  final String flaskBaseUrl;

  const WorkoutScreen({
    super.key,
    required this.workoutService,
    required this.userService,
    required this.supabase,
    required this.flaskBaseUrl,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
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

      await _updateWorkoutSummary();
    });

    _updateWorkoutSummary();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _updateWorkoutSummary() async {
    if (_currentUser == null) return;
    final workouts = await widget.workoutService.getRealtimeWorkoutsStream().first;
    await _summaryService.saveWorkoutSummary(workouts);
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

  void _addWorkout() async {
    if (_currentUser == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutEntryScreen(workoutService: widget.workoutService),
      ),
    );
    _updateWorkoutSummary();
  }

  void _editWorkout(Workout workout) async {
    if (_currentUser == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutEntryScreen(
          workoutService: widget.workoutService,
          workoutToEdit: workout,
        ),
      ),
    );
    _updateWorkoutSummary();
  }

  void _deleteWorkout(String workoutId) {
    if (_currentUser == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ワークアウトを削除しますか？'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.workoutService.deleteWorkout(workoutId).then((_) {
                _showSnackBar('ワークアウトを削除しました。');
                _updateWorkoutSummary();
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

  // ✅ AI生成（ワークアウト）
  Future<void> _generateWorkoutAi() async {
    if (_currentUser == null) return;

    setState(() => _aiLoading = true);

    try {
      final profile = await widget.userService.getUserProfile(_currentUser!.id);
      final pastWorkoutSummary = await _summaryService.getWorkoutSummary();

      _showSnackBar('AIがワークアウトを生成中...');

      final plan = await _aiService.generateWorkoutPlan(
        level: 'beginner',
        frequency: 3,
        goal: 'maintain_weight',
        pastWorkoutSummary: pastWorkoutSummary,
        gender: profile.gender,
      );

      if (!mounted) return;

      PlanBottomSheet.show(
        context,
        title: 'AI ワークアウトプラン',
        plan: plan,
        itemBuilder: (item) => _buildWorkoutPlanItem(context, item),
      );
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Widget _buildWorkoutPlanItem(BuildContext context, Map<String, dynamic> item) {
    final exercises = (item['exercises'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

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
            '${item['day'] ?? ''}  ${item['focus'] ?? ''}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...exercises.map((ex) {
            final sets = ex['sets']?.toString() ?? '';
            final reps = ex['reps']?.toString() ?? ex['duration']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '・${ex['name']}  ${sets}set × $reps',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }),
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
        title: const Text('ワークアウト記録'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addWorkout,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ AIボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aiLoading ? null : _generateWorkoutAi,
                icon: _aiLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_aiLoading ? '生成中...' : 'AI ワークアウト生成'),
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
            child: StreamBuilder<List<Workout>>(
              stream: widget.workoutService.getRealtimeWorkoutsStream(),
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
                      'ワークアウト記録がありません。\n右上の+で追加できます。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final workouts = snapshot.data!;
                _summaryService.saveWorkoutSummary(workouts);

                return ListView.builder(
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        title: Text(
                          '${workout.workoutType} - ${workout.workoutDate.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${workout.durationMinutes}分 / ${workout.totalCaloriesBurned} kcal\n${workout.notes ?? ''}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteWorkout(workout.id),
                        ),
                        onTap: () => _editWorkout(workout),
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
