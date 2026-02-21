import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/apex_card.dart';
import '../../core/services/premium_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/summary_service.dart';
import '../../models/meal.dart';
import '../../services/meal_service.dart';
import '../../services/user_service.dart';
import 'meal_entry_screen.dart';

class MealListScreen extends StatefulWidget {
  final MealService mealService;
  final UserService userService;

  const MealListScreen({super.key, required this.mealService, required this.userService});

  @override
  State<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  final _summary = SummaryService();
  final _premium = PremiumService();
  final _ai = AiService();
  bool _aiLoading = false;

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: err ? Palette.danger : Palette.surface2));
  }

  Future<void> _openAi() async {
    final isPremium = await _premium.isPremium();
    if (!isPremium) {
      _snack('食事プランAIはPremium限定です（開発中）', err: true);
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final profile = await widget.userService.getProfile(user.id);
      final summaryJson = await _summary.getMealSummary();
      final payload = {
        'user': {
          'id': user.id,
          'gender': profile.gender,
          'height': profile.height,
          'target_calories': profile.targetCalories,
          'target_weight': profile.targetWeight,
        },
        'summary': summaryJson != null ? json.decode(summaryJson) : null,
        'request': {'style': 'high_protein', 'days': 1},
      };
      final plan = await _ai.generateMealPlan(payload);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _AiPlanSheet(title: 'AI食事プラン', items: plan),
      );
    } catch (e) {
      _snack('AI生成に失敗: $e', err: true);
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食事プラン'),
        actions: [
          IconButton(
            onPressed: _aiLoading ? null : _openAi,
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI生成',
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealEntryScreen(mealService: widget.mealService)));
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: StreamBuilder<List<Meal>>(
        stream: widget.mealService.streamMeals(),
        builder: (context, snap) {
          final meals = snap.data ?? [];
          // summary save
          _summary.saveMealSummary(meals);
          if (meals.isEmpty) {
            return const Center(child: Text('食事記録がありません', style: AppText.muted));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final m = meals[i];
              return ApexCard(
                child: ListTile(
                  title: Text('${m.mealType}  •  ${m.mealDate.toLocal().toString().split(' ')[0]}', style: AppText.body),
                  subtitle: Text('カロリー: ${m.totalCalories} kcal\n${m.notes ?? ''}', style: AppText.muted),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Palette.danger),
                    onPressed: () => widget.mealService.deleteMeal(m.id),
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealEntryScreen(mealService: widget.mealService, mealToEdit: m)));
                  },
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: meals.length,
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
            Text('※ AI生成は参考情報です。体調・アレルギー等に注意。', style: AppText.muted),
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
                        Text(item['title']?.toString() ?? 'プラン', style: AppText.h2),
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
