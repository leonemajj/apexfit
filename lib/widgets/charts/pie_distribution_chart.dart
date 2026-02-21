import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;
  const PieDistributionChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    final total = distribution.values.fold<int>(0, (s, v) => s + v);

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    final keys = distribution.keys.toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 36,
        sections: List.generate(keys.length, (i) {
          final k = keys[i];
          final v = distribution[k] ?? 0;
          final percent = (v / total * 100);

          return PieChartSectionData(
            value: v.toDouble(),
            title: '${percent.toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            color: colors[i % colors.length],
          );
        }),
      ),
    );
  }
}
