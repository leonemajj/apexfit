import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/weight.dart';

class LineWeightChart extends StatelessWidget {
  final List<Weight> weights;
  const LineWeightChart({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const Center(child: Text('体重データがありません'));
    }

    final sorted = [...weights]..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].weightKg));
    }

    final minY = sorted.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final maxY = sorted.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY - 1,
        maxY: maxY + 1,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return Text(value.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.bodySmall);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (sorted.length / 4).clamp(1, 10).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(DateFormat('MM/dd').format(sorted[i].date),
                      style: Theme.of(context).textTheme.bodySmall),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true),
          ),
        ],
      ),
    );
  }
}
