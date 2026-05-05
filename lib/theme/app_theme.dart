import 'package:flutter/material.dart';

class AppThemePalette {
  static const Color brand = Color(0xFF1E5AA8);
  static const Color onBrand = Colors.white;
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2A37);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFD5DEE8);
}

class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppThemePalette.brand,
      onPrimary: AppThemePalette.onBrand,
      secondary: Color(0xFF2F7DDA),
      onSecondary: Colors.white,
      surface: AppThemePalette.surface,
      onSurface: AppThemePalette.textPrimary,
      error: Color(0xFFC2410C),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppThemePalette.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppThemePalette.surface,
        foregroundColor: AppThemePalette.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppThemePalette.surface,
        elevation: 1.5,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppThemePalette.brand,
          foregroundColor: AppThemePalette.onBrand,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppThemePalette.brand,
          side: BorderSide.none,
          backgroundColor: AppThemePalette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppThemePalette.brand,
        foregroundColor: AppThemePalette.onBrand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemePalette.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppThemePalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppThemePalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppThemePalette.brand, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppThemePalette.border),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppThemePalette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppThemePalette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: AppThemePalette.textPrimary),
        bodySmall: TextStyle(color: AppThemePalette.textMuted),
      ),
    );
  }
}
