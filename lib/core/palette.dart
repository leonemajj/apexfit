import 'package:flutter/material.dart';

class AppPalette {
  // Base
  static const Color bg = Color(0xFF0B0F14);       // ほぼ黒
  static const Color surface = Color(0xFF101723);  // カード面
  static const Color surface2 = Color(0xFF0E1520);

  // Lines
  static const Color stroke = Color(0xFF223044);

  // Text
  static const Color text = Color(0xFFEAF0FF);
  static const Color textMuted = Color(0xFF9FB0C9);

  // Accent (好みで変更OK)
  static const Color accent = Color(0xFF4F7DFF);     // ブルー
  static const Color accent2 = Color(0xFF19D3A2);    // ミント
  static const Color warn = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5C7C);

  // Subtle glow（光りすぎないマット系）
  static Color glow(Color c) => c.withOpacity(0.18);

  // Gradient（控えめ）
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF15233A),
      Color(0xFF0B0F14),
    ],
  );

  static LinearGradient accentGradient({double opacity = 1}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(opacity),
          accent2.withOpacity(opacity),
        ],
      );
}
