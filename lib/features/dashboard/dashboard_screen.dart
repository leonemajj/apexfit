import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/apex_card.dart';
import '../../core/widgets/primary_chip.dart';
import '../../services/meal_service.dart';
import '../../services/workout_service.dart';
import '../../services/weight_service.dart';
import '../../services/user_service.dart';
import '../../models/meal.dart';
import '../../models/workout.dart';
import '../../models/weight.dart';

enum RangePreset { d7, m1, m3 }

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

class _DashboardScreenState extends State<DashboardScreen> {
  RangePreset _preset = RangePreset.d7;

  DateTime _cutoff() {
    final now = DateTime.now();
    switch (_preset) {
      case RangePreset.d7:
        return now.subtract(const Duration(days: 7));
      case RangePreset.m1:
        return now.subtract(const Duration(days: 30));
      case RangePreset.m3:
        return now.subtract(const Duration(days: 90));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = _cutoff();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<RangePreset>(
              segments: const [
                ButtonSegment(value: RangePreset.d7, label: Text('7日')),
                ButtonSegment(value: RangePreset.m1, label: Text('1ヶ月')),
                ButtonSegment(value: RangePreset.m3, label: Text('3ヶ月')),
              ],
              selected: {_preset},
              onSelectionChanged: (s) => setState(() => _preset = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Palette.surface),
                foregroundColor: WidgetStatePropertyAll(Palette.text),
                side: WidgetStatePropertyAll(BorderSide(color: Palette.stroke)),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroHeader(),
          const SizedBox(height: 14),
          StreamBuilder<List<Weight>>(
            stream: widget.weightService.streamWeights(),
            builder: (context, snap) {
              final weights = (snap.data ?? []).where((w) => w.date.isAfter(cutoff)).toList();
              return _WeightChartCard(weights: weights);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<Meal>>(
                  stream: widget.mealService.streamMeals(),
                  builder: (context, snap) {
                    final meals = (snap.data ?? []).where((m) => m.mealDate.isAfter(cutoff)).toList();
                    return _PieCard(
                      title: '食事バランス',
                      subtitle: '食事タイプ比率',
                      dist: _distMeals(meals),
                      emptyHint: '食事記録がありません',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<List<Workout>>(
                  stream: widget.workoutService.streamWorkouts(),
                  builder: (context, snap) {
                    final w = (snap.data ?? []).where((x) => x.workoutDate.isAfter(cutoff)).toList();
                    return _PieCard(
                      title: '運動タイプ',
                      subtitle: '種目の比率',
                      dist: _distWorkouts(w),
                      emptyHint: 'ワークアウト記録がありません',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, int> _distMeals(List<Meal> meals) {
    final map = <String, int>{};
    for (final m in meals) {
      map.update(m.mealType, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }

  Map<String, int> _distWorkouts(List<Workout> workouts) {
    final map = <String, int>{};
    for (final w in workouts) {
      map.update(w.workoutType, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }
}

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Palette.stroke),
        gradient: LinearGradient(
          colors: [
            Palette.surface2,
            Palette.surface2.withOpacity(0.72),
            Palette.surface.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('今日の進捗', style: AppText.h1),
                SizedBox(height: 6),
                Text('「記録→見える化→改善」だけで身体は変わる', style: AppText.muted),
              ],
            ),
          ),
          const PrimaryChip(label: 'Premium', color: Palette.accent),
        ],
      ),
    );
  }
}

class _WeightChartCard extends StatelessWidget {
  final List<Weight> weights;
  const _WeightChartCard({required this.weights});

  @override
  Widget build(BuildContext context) {
    final data = List<Weight>.from(weights)..sort((a, b) => a.date.compareTo(b.date));
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('体重推移', style: AppText.h2),
          const SizedBox(height: 4),
          const Text('折れ線グラフ', style: AppText.muted),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: data.isEmpty
                ? const Center(child: Text('体重の記録がありません', style: AppText.muted))
                : LineChart(_lineData(data)),
          ),
        ],
      ),
    );
  }

  LineChartData _lineData(List<Weight> data) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].weightKg));
    }
    final minY = data.map((e) => e.weightKg).reduce(min) - 1;
    final maxY = data.map((e) => e.weightKg).reduce(max) + 1;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Palette.accent.withOpacity(0.12)),
          color: Palette.accent,
          spots: spots,
        )
      ],
    );
  }
}

class _PieCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, int> dist;
  final String emptyHint;

  const _PieCard({required this.title, required this.subtitle, required this.dist, required this.emptyHint});

  @override
  Widget build(BuildContext context) {
    final total = dist.values.fold<int>(0, (s, v) => s + v);
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h2),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.muted),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: total == 0
                ? Center(child: Text(emptyHint, style: AppText.muted, textAlign: TextAlign.center))
                : PieChart(_pieData(dist)),
          ),
        ],
      ),
    );
  }

  PieChartData _pieData(Map<String, int> dist) {
    final entries = dist.entries.toList();
    final total = dist.values.fold<int>(0, (s, v) => s + v);
    return PieChartData(
      centerSpaceRadius: 40,
      sectionsSpace: 2,
      sections: List.generate(entries.length, (i) {
        final e = entries[i];
        final value = e.value.toDouble();
        final percent = (value / total * 100).round();
        // no explicit colors rule doesn't apply here (app design) but keep subtle list
        final colors = [Palette.accent, Palette.accent2, Palette.warning, Palette.danger, Palette.textMuted];
        final c = colors[i % colors.length];
        return PieChartSectionData(
          color: c,
          value: value,
          radius: 48,
          title: '$percent%',
          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
        );
      }),
    );
  }
}
