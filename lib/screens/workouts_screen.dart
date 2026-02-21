import 'package:flutter/material.dart';
import '../../core/ui.dart';
import '../../core/text_styles.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ワークアウト'),
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
                Text('今日のワークアウト', style: AppText.title(context)),
                const SizedBox(height: 8),
                Text('ワークアウト記録の一覧がここに表示される', style: AppText.muted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
