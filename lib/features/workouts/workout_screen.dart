import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/apex_card.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/summary_service.dart';
import '../../models/workout.dart';
import '../../services/workout_service.dart';
import '../../services/user_service.dart';
import 'workout_entry_screen.dart';
import 'timer_widget.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutService workoutService;
  final UserService userService;

  const WorkoutScreen({super.key, required this.workoutService, required this.userService});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _summary = SummaryService();
  final _ai = AiService();
  bool _aiLoading = false;

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: err ? Palette.danger : Palette.surface2));
  }

  Future<void> _openAi() async {
    setState(() => _aiLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profile = await widget.userService.getProfile(user.id);
      final summaryJson = await _summary.getWorkoutSummary();
      final payload = {
        'user': {
          'id': user.id,
          'gender': profile.gender,
          'height': profile.height,
          'target_weight': profile.targetWeight,
        },
        'summary': summaryJson != null ? json.decode(summaryJson) : null,
        'request': {'goal': '筋肥大', 'days': 1},
      };
      final plan = await _ai.generateWorkoutPlan(payload);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _AiPlanSheet(title: 'AIワークアウト', items: plan),
      );
    } catch (e) {
      _snack('AI生成に失敗: $e', err: true);
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _openSessionTimer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('ワークアウトセッション', style: AppText.h2),
              SizedBox(height: 6),
              Text('休憩タイマー（初期: 3分）', style: AppText.muted),
              SizedBox(height: 12),
              SessionTimer(initialSeconds: 180),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ワークアウト'),
        actions: [
          IconButton(onPressed: _aiLoading ? null : _openAi, icon: const Icon(Icons.auto_awesome), tooltip: 'AI生成'),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutEntryScreen(workoutService: widget.workoutService)));
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: StreamBuilder<List<Workout>>(
        stream: widget.workoutService.streamWorkouts(),
        builder: (context, snap) {
          final workouts = snap.data ?? [];
          _summary.saveWorkoutSummary(workouts);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ApexCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('クイックセッション', style: AppText.h2),
                    const SizedBox(height: 6),
                    const Text('タイマー付きでセット間休憩を管理', style: AppText.muted),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openSessionTimer,
                        icon: const Icon(Icons.timer),
                        label: const Text('セッション開始'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (workouts.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Text('ワークアウト記録がありません', style: AppText.muted)))
              else
                ...workouts.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ApexCard(
                        child: ListTile(
                          title: Text('${w.workoutType}  •  ${w.workoutDate.toLocal().toString().split(' ')[0]}', style: AppText.body),
                          subtitle: Text('時間: ${w.durationMinutes}分  消費: ${w.totalCaloriesBurned}kcal\n${w.notes ?? ''}', style: AppText.muted),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Palette.danger),
                            onPressed: () => widget.workoutService.deleteWorkout(w.id),
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutEntryScreen(workoutService: widget.workoutService, workoutToEdit: w)));
                          },
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _AiPlanSheet extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  const _AiPlanSheet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.h2),
            const SizedBox(height: 8),
            Text('将来: 音声AIコーチ・フォーム解析など拡張予定', style: AppText.muted),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i] as Map<String, dynamic>;
                  return ApexCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']?.toString() ?? 'メニュー', style: AppText.h2),
                        const SizedBox(height: 6),
                        Text(item['detail']?.toString() ?? '', style: AppText.body),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))),
          ],
        ),
      ),
    );
  }
}
