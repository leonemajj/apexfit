import 'package:flutter/material.dart';
import '../../core/ui.dart';
import '../../core/text_styles.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食事プラン'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: AccentButton(
                text: 'AI生成',
                icon: Icons.auto_awesome,
                onPressed: () {
                  // TODO: ステップでGemini/Render連携
                },
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日の食事', style: AppText.title(context)),
                const SizedBox(height: 8),
                Text('食事記録の一覧がここに表示される', style: AppText.muted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
