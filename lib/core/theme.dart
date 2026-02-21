import 'package:flutter/material.dart';
import 'palette.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.bg,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppPalette.accent,
        secondary: AppPalette.accent2,
        surface: AppPalette.surface,
        onSurface: AppPalette.text,
        error: AppPalette.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.bg,
        foregroundColor: AppPalette.text,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.surface,
        contentTextStyle: const TextStyle(color: AppPalette.text, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardTheme(
        color: AppPalette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(
        color: AppPalette.stroke.withOpacity(0.7),
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppPalette.bg,
        selectedItemColor: AppPalette.accent,
        unselectedItemColor: AppPalette.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
