// ══════════════════════════════════════════════════════════════════════════
// 🎨 THEME - Calm & Focus Premium Light (Glass & Depth)
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ════════════════════════════════════════════════════════════════════════
  // SPACING SCALE (8pt grid system)
  // ════════════════════════════════════════════════════════════════════════

  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // ════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS
  // ════════════════════════════════════════════════════════════════════════

  static const double radiusSmall = 6.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // ════════════════════════════════════════════════════════════════════════
  // ICON SIZES
  // ════════════════════════════════════════════════════════════════════════

  static const double iconSmall = 18.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXL = 48.0;

  // ════════════════════════════════════════════════════════════════════════
  // CALM & FOCUS LIGHT PALETTE (from prototype)
// Soft sky blues + crisp azure for a distraction-free environment
  // ════════════════════════════════════════════════════════════════════════

  // Background
  static const Color bg = Color(0xFFF0F9FF); // base canvas

  static const LinearGradient mainBgGradient = LinearGradient(
    colors: [
      Color(0xFFF0F9FF), // Sky Blue (clarity)
      Color(0xFFE0F2FE), // Light Blue (calm)
      Color(0xFFDBEAFE), // Soft Blue (focus)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400

  // Accents
  static const Color primaryBlue = Color(0xFF2563EB); // Focus blue
  static const Color successGreen = Color(0xFF10B981);
  static const Color alertOrange = Color(0xFFF59E0B);

  // Icon gradients
  static const LinearGradient accentPurple = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentOrange = LinearGradient(
    colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGreen = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentBlue = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Depth / shadow
  static const Color shadowColor = Color(0xFF1E293B);

  // ════════════════════════════════════════════════════════════════════════
  // MISSING MEMBERS (Legacy Compatibility & Aliases)
  // ════════════════════════════════════════════════════════════════════════

  // Basic Colors
  static const Color brandBlue = primaryBlue;
  static const Color brandGreen = successGreen;
  static const Color brandOrange = alertOrange;
  static const Color brandPurple = Color(0xFF8B5CF6);

  static const Color bluePrimary = primaryBlue;
  static const Color greenPrimary = successGreen;
  static const Color orangePrimary = alertOrange;
  static const Color purplePrimary = brandPurple;

  static const Color textMuted = textTertiary;
  static const Color error = Colors.redAccent;
  static const Color success = successGreen;
  static const Color info = primaryBlue;

  static const Color borderDefault = Color(0xFFE2E8F0);
  static const Color surfaceElevated = Colors.white;
  static const Color surfaceHover = Color(0xFFF8FAFC);

  // Gradients
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueStatsGradient = accentBlue;
  static const LinearGradient greenStatsGradient = accentGreen;
  static const LinearGradient orangeStatsGradient = accentOrange;
  static const LinearGradient purpleStatsGradient = accentPurple;

  // Shadows / Glows
  static List<BoxShadow> get blueCardGlow => [
        BoxShadow(
          color: primaryBlue.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];

  static List<BoxShadow> get greenCardGlow => [
        BoxShadow(
          color: successGreen.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];

  static List<BoxShadow> get orangeCardGlow => [
        BoxShadow(
          color: alertOrange.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];

  static List<BoxShadow> get purpleCardGlow => [
        BoxShadow(
          color: brandPurple.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        )
      ];

  // ════════════════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS
  // ════════════════════════════════════════════════════════════════════════

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ════════════════════════════════════════════════════════════════════════
  // UNIVERSAL THEME - Calm & Focus Premium Light
  // ════════════════════════════════════════════════════════════════════════

  static ThemeData get theme {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      // fontFamily: 'Inter', // Removed to avoid conflict with GoogleFonts

      // ColorScheme seeded by focus blue
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        surface: bg,
        brightness: Brightness.light,
      ),

      // AppBar – clean, minimal, sitting over gradient background
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

      // Card – frosted glass base
      cardTheme: const CardThemeData(
        color: Color(0xBFFFFFFF), // White with 75% opacity (safe const)
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusXL)),
          side: BorderSide(
             color: Color(0x99FFFFFF), // White with 60% opacity
             width: 1.5,
          ),
        ),
      ),

      // Typography – tuned for readability on soft blue background
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

      // Primary buttons – crisp azure focus color
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

      // Text buttons – link-style actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing12,
            vertical: spacing8,
          ),
        ),
      ),

      // Outlined buttons – subtle secondary actions
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(
            color: textTertiary.withOpacity(0.4),
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

      // FAB – use focus blue
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 10.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // Inputs – minimal, soft borders
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: textTertiary.withOpacity(0.4),
            width: 1.3,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: textTertiary.withOpacity(0.4),
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

      // Dividers – very soft
      dividerTheme: DividerThemeData(
        color: textTertiary.withOpacity(0.2),
        thickness: 1.0,
        space: 1.0,
      ),

      // Progress indicator – focus blue
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryBlue,
        circularTrackColor: textTertiary.withOpacity(0.2),
      ),

      // SnackBar – Default neutral style to avoid conflicts
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating, 
      ),

      // Switch – use green for confirmation
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return successGreen;
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return successGreen.withOpacity(0.4);
          }
          return textTertiary.withOpacity(0.3);
        }),
      ),

      // Slider – focus blue
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: textTertiary.withOpacity(0.3),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withOpacity(0.2),
        valueIndicatorColor: primaryBlue,
      ),

      // Navigation Bar – modern Material 3, distinct from background
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(0.9),
        indicatorColor: primaryBlue.withOpacity(0.1),
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
