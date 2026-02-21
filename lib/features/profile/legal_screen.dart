import 'package:flutter/material.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/apex_card.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String text;
  const LegalScreen({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ApexCard(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}
