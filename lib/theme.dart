// ══════════════════════════════════════════════════════════════════════════
// 🎨 THEME - Simple MVP (Clean & Minimal) - UPDATED
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ════════════════════════════════════════════════════════════════════════
  // SPACING (Only what you need)
  // ════════════════════════════════════════════════════════════════════════

  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ════════════════════════════════════════════════════════════════════════

  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;

  // ════════════════════════════════════════════════════════════════════════
  // COLORS - Core palette only
  // ════════════════════════════════════════════════════════════════════════

  // Background
  static const Color bg = Color(0xFFF0F9FF);

  static const LinearGradient mainBgGradient = LinearGradient(
    colors: [
      Color(0xFFF0F9FF), // Sky Blue
      Color(0xFFE0F2FE), // Light Blue
      Color(0xFFDBEAFE), // Soft Blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // Typography
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Main accent colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color successGreen = Color(0xFF10B981);
  static const Color alertOrange = Color(0xFFF59E0B);
  static const Color brandPurple = Color(0xFF8B5CF6);

  // Borders
  static const Color borderDefault = Color(0xFFE2E8F0);
  static const Color shadowColor = Color(0xFF1E293B);

  // ════════════════════════════════════════════════════════════════════════
  // GRADIENTS - For stat cards
  // ════════════════════════════════════════════════════════════════════════

  static const LinearGradient accentBlue = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGreen = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentOrange = LinearGradient(
    colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentPurple = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ════════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ════════════════════════════════════════════════════════════════════════

  static List<BoxShadow> get blueCardGlow => [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.15), // ✅ FIXED
          blurRadius: 12,
          offset: const Offset(0, 6),
        )
      ];

  // ════════════════════════════════════════════════════════════════════════
  // THEME DATA
  // ════════════════════════════════════════════════════════════════════════

  static ThemeData get theme {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        surface: bg,
        brightness: Brightness.light,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // Card
      cardTheme: const CardThemeData(
        color: Color(0xBFFFFFFF),
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusXL)),
          side: BorderSide(color: Color(0x99FFFFFF), width: 1.5),
        ),
      ),

      // Typography
      textTheme: textTheme.copyWith(
        displaySmall: textTheme.displaySmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: textSecondary,
          height: 1.6,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: textTertiary,
          height: 1.4,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0.0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing12,
            vertical: spacing8,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(
            color: textTertiary.withValues(alpha: 0.4), // ✅ FIXED
            width: 1.3,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8), // ✅ FIXED
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: textTertiary.withValues(alpha: 0.4), // ✅ FIXED
            width: 1.3,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: textTertiary.withValues(alpha: 0.4), // ✅ FIXED
            width: 1.3,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.3,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        labelStyle: const TextStyle(color: textTertiary),
        hintStyle: const TextStyle(color: textTertiary),
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryBlue,
        circularTrackColor: textTertiary.withValues(alpha: 0.2), // ✅ FIXED
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? successGreen
              : textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? successGreen.withValues(alpha: 0.4) // ✅ FIXED
              : textTertiary.withValues(alpha: 0.3); // ✅ FIXED
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: textTertiary.withValues(alpha: 0.3), // ✅ FIXED
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withValues(alpha: 0.2), // ✅ FIXED
        valueIndicatorColor: primaryBlue,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.9), // ✅ FIXED
        indicatorColor: primaryBlue.withValues(alpha: 0.1), // ✅ FIXED
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
            );
          }
          return textTheme.labelMedium?.copyWith(color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryBlue, size: 26);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
        elevation: 0,
        height: 72,
      ),
    );
  }
}
