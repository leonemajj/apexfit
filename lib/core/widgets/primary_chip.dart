import 'package:flutter/material.dart';
import '../theme/palette.dart';

class PrimaryChip extends StatelessWidget {
  final String label;
  final Color? color;

  const PrimaryChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Palette.accent).withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: (color ?? Palette.accent).withOpacity(0.35)),
      ),
      child: Text(label, style: const TextStyle(color: Palette.text, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
