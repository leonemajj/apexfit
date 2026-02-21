import 'package:flutter/material.dart';
import '../../core/ui.dart';
import '../../core/text_styles.dart';
import '../../core/palette.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  int days = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('体重')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              PremiumChip(label: '7日', icon: Icons.calendar_month),
              const SizedBox(width: 8),
              PremiumChip(label: '1ヶ月', icon: Icons.calendar_view_month),
              const SizedBox(width: 8),
              PremiumChip(label: '2ヶ月', icon: Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 14),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('体重推移', style: AppText.title(context)),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppPalette.surface2,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppPalette.stroke.withOpacity(0.6)),
                  ),
                  child: Center(child: Text('折れ線グラフ（次ステップで実装）', style: AppText.muted(context))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
