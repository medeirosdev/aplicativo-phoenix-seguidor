import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Phoenix brand
  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryDark = Color(0xFFE05500);
  static const Color primaryLight = Color(0xFFFF8F33);

  // Background
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color card = Color(0xFF252525);

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF2196F3);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF666666);

  // BLE
  static const Color bleConnected = Color(0xFF00E676);
  static const Color bleScanning = Color(0xFF2196F3);
  static const Color bleDisconnected = Color(0xFF666666);
  static const Color bleError = Color(0xFFFF1744);

  // Terminal
  static const Color terminalSent = Color(0xFF64B5F6);
  static const Color terminalReceived = Color(0xFFE0E0E0);
  static const Color terminalBackground = Color(0xFF0D0D0D);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x29FF6B00),
        valueIndicatorColor: AppColors.primary,
        showValueIndicator: ShowValueIndicator.always,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.4);
          }
          return AppColors.surfaceLight;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
      ),
      dividerColor: AppColors.surfaceLight,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }

  static TextStyle get terminalStyle => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.4,
        color: AppColors.terminalReceived,
      );

  static TextStyle get terminalSentStyle => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.4,
        color: AppColors.terminalSent,
      );
}
