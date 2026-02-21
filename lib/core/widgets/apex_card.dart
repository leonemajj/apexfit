import 'package:flutter/material.dart';
import '../theme/palette.dart';

class ApexCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const ApexCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.stroke),
      ),
      padding: padding,
      child: child,
    );
  }
}
