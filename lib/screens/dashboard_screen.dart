import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/meal_service.dart';
import '../services/workout_service.dart';
import '../services/weight_service.dart';
import '../services/user_service.dart';

import '../models/meal.dart';
import '../models/workout.dart';
import '../weight_service.dart' show Weight;

class DashboardScreen extends StatefulWidget {
  final MealService mealService;
  final WorkoutService workoutService;
  final WeightService weightService;
  final UserService userService;

  const DashboardScreen({
    super.key,
    required this.mealService,
    required this.workoutService,
    required this.weightService,
    required this.userService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum WeightRange { days7, days30, days90 }

class _DashboardScreenState extends State<DashboardScreen> {
  User? _currentUser;
  late final StreamSubscription<AuthState> _authStateSubscription;

  WeightRange _range = WeightRange.days7;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.userService._supabaseClient.auth.currentUser;

    _authStateSubscription =
        widget.userService._supabaseClient.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() => _currentUser = data.session?.user);
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今日の進捗',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('yyyy/MM/dd').format(today),
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 16),

              _buildSummaryCards(today),
              const SizedBox(height: 18),

              _buildAiButtons(),
              const SizedBox(height: 18),

              _buildMealPie(today),
              const SizedBox(height: 18),

              _buildWeightLineChart(),
              const SizedBox(height: 18),

              _buildRecentActivities(),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // ✅ 今日のサマリー（摂取/消費/差分）
  // ----------------------------
  Widget _buildSummaryCards(DateTime today) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: '摂取',
            icon: Icons.restaurant_rounded,
            child: StreamBuilder<List<Meal>>(
              stream: widget.mealService.getRealtimeMealsStream().map(
                    (meals) => meals
                        .where((m) => DateUtils.dateOnly(m.mealDate) == today)
                        .toList(),
                  ),
              builder: (context, snapshot) {
                final total = snapshot.data?.fold<int>(
                        0, (sum, item) => sum + item.totalCalories) ??
                    0;
                return Text(
                  '$total kcal',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            title: '消費',
            icon: Icons.local_fire_department_rounded,
            child: StreamBuilder<List<Workout>>(
              stream: widget.workoutService.getRealtimeWorkoutsStream().map(
                    (workouts) => workouts
                        .where((w) =>
                            DateUtils.dateOnly(w.workoutDate) == today)
                        .toList(),
                  ),
              builder: (context, snapshot) {
                final total = snapshot.data?.fold<int>(
                        0, (sum, item) => sum + item.totalCaloriesBurned) ??
                    0;
                return Text(
                  '$total kcal',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ----------------------------
  // ✅ AIボタン（ホームから導線）
  // ----------------------------
  Widget _buildAiButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // NOTE: 食事画面のAIボタンに誘導したいだけなら
              // BottomNavのindex=1へ飛ばすのもあり
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('食事プラン画面でAI生成できます')),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('AI 食事プラン'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ワークアウト画面でAI生成できます')),
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('AI ワークアウト'),
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // ✅ 円グラフ：今日の食事内訳
  // ----------------------------
  Widget _buildMealPie(DateTime today) {
    return StreamBuilder<List<Meal>>(
      stream: widget.mealService.getRealtimeMealsStream().map((meals) => meals
          .where((m) => DateUtils.dateOnly(m.mealDate) == today)
          .toList()),
      builder: (context, snapshot) {
        final meals = snapshot.data ?? [];

        final dist = <String, int>{};
        for (final m in meals) {
          dist[m.mealType] = (dist[m.mealType] ?? 0) + m.totalCalories;
        }

        if (dist.isEmpty) {
          return _sectionCard(
            title: '今日の食事内訳',
            child: const Text(
              'まだ食事記録がありません。',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final total = dist.values.fold<int>(0, (a, b) => a + b);
        final sections = dist.entries.map((e) {
          final value = e.value.toDouble();
          final pct = (value / total * 100).toStringAsFixed(0);
          return PieChartSectionData(
            value: value,
            title: '$pct%',
            radius: 55,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          );
        }).toList();

        return _sectionCard(
          title: '今日の食事内訳',
          child: Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dist.entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '• ${e.key}: ${e.value} kcal',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------
  // ✅ 折れ線：体重推移（切替）
  // ----------------------------
  Widget _buildWeightLineChart() {
    return StreamBuilder<List<Weight>>(
      stream: widget.weightService.getWeightHistoryStream(),
      builder: (context, snapshot) {
        final weights = snapshot.data ?? [];

        int days;
        String label;
        switch (_range) {
          case WeightRange.days7:
            days = 7;
            label = '7日';
            break;
          case WeightRange.days30:
            days = 30;
            label = '30日';
            break;
          case WeightRange.days90:
            days = 90;
            label = '90日';
            break;
        }

        final cutoff = DateTime.now().subtract(Duration(days: days));
        final filtered = weights
            .where((w) => w.date.isAfter(cutoff))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        return _sectionCard(
          title: '体重推移（$label）',
          trailing: _rangeSelector(),
          child: filtered.isEmpty
              ? const Text(
                  '体重データがありません。',
                  style: TextStyle(color: Colors.white70),
                )
              : SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < filtered.length; i++)
                              FlSpot(i.toDouble(), filtered[i].weightKg),
                          ],
                          isCurved: true,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _rangeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('7日', _range == WeightRange.days7, () {
          setState(() => _range = WeightRange.days7);
        }),
        const SizedBox(width: 6),
        _chip('30日', _range == WeightRange.days30, () {
          setState(() => _range = WeightRange.days30);
        }),
        const SizedBox(width: 6),
        _chip('90日', _range == WeightRange.days90, () {
          setState(() => _range = WeightRange.days90);
        }),
      ],
    );
  }

  Widget _chip(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6C5CE7) : const Color(0xFF141418),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : Colors.white60,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // ✅ 最近の記録（食事＋ワークアウト）
  // ----------------------------
  Widget _buildRecentActivities() {
    return _sectionCard(
      title: '最近の記録',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<Meal>>(
            stream: widget.mealService.getRealtimeMealsStream().map((meals) {
              meals.sort((a, b) => b.mealDate.compareTo(a.mealDate));
              return meals.take(3).toList();
            }),
            builder: (context, snapshot) {
              final meals = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('食事', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  ...meals.map((m) => Text(
                        '• ${m.mealType} ${DateFormat('MM/dd HH:mm').format(m.mealDate)} - ${m.totalCalories} kcal',
                        style: const TextStyle(color: Colors.white),
                      )),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          StreamBuilder<List<Workout>>(
            stream: widget.workoutService.getRealtimeWorkoutsStream().map((ws) {
              ws.sort((a, b) => b.workoutDate.compareTo(a.workoutDate));
              return ws.take(3).toList();
            }),
            builder: (context, snapshot) {
              final workouts = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ワークアウト',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  ...workouts.map((w) => Text(
                        '• ${w.workoutType} ${DateFormat('MM/dd HH:mm').format(w.workoutDate)} - ${w.durationMinutes}分 / ${w.totalCaloriesBurned}kcal',
                        style: const TextStyle(color: Colors.white),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // 共通：セクションカード
  // ----------------------------
  Widget _sectionCard({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
