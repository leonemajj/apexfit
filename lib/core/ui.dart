import 'package:flutter/material.dart';
import 'palette.dart';
import 'text_styles.dart';

class AppUI {
  static const double r = 18; // 角丸
  static const double r2 = 26;

  static BoxDecoration cardDecoration({bool elevated = true}) {
    return BoxDecoration(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(r2),
      border: Border.all(color: AppPalette.stroke.withOpacity(0.7), width: 1),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ]
          : [],
    );
  }

  static BoxDecoration softPanelDecoration() {
    return BoxDecoration(
      gradient: AppPalette.heroGradient,
      borderRadius: BorderRadius.circular(r2),
      border: Border.all(color: AppPalette.stroke.withOpacity(0.55), width: 1),
    );
  }

  static InputDecoration inputDecoration(BuildContext context, String label, {String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppPalette.surface2,
      labelStyle: AppText.muted(context),
      hintStyle: AppText.muted(context).copyWith(color: AppPalette.textMuted.withOpacity(0.6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide(color: AppPalette.stroke.withOpacity(0.8), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide(color: AppPalette.accent.withOpacity(0.9), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide(color: AppPalette.danger.withOpacity(0.9), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide(color: AppPalette.danger.withOpacity(0.9), width: 1.2),
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool elevated;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppUI.cardDecoration(elevated: elevated),
      padding: padding,
      child: child,
    );
  }
}

class AccentButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;

  const AccentButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 10),
              ],
              Text(text, style: AppText.chip(context)),
            ],
          );

    final ButtonStyle style = outline
        ? OutlinedButton.styleFrom(
            foregroundColor: AppPalette.text,
            side: BorderSide(color: AppPalette.stroke.withOpacity(0.9), width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUI.r)),
          )
        : ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: AppPalette.accent,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUI.r)),
            elevation: 0,
          );

    return outline
        ? OutlinedButton(onPressed: loading ? null : onPressed, style: style, child: child)
        : ElevatedButton(onPressed: loading ? null : onPressed, style: style, child: child);
  }
}

class PremiumChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const PremiumChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppPalette.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: c.withOpacity(0.95)),
            const SizedBox(width: 8),
          ],
          Text(label, style: AppText.chip(context).copyWith(color: AppPalette.text)),
        ],
      ),
    );
  }
}
