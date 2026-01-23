import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

// ══════════════════════════════════════════════════════════════════════════
// 🎨 PREMIUM THEME ENGINE - COMPLETE DESIGN SYSTEM
// ══════════════════════════════════════════════════════════════════════════
// Single source of truth for colors, typography, shadows, gradients,
// glassmorphism, animations, and component styles.
// Transforms basic Material Design into a premium, delightful experience.
// ══════════════════════════════════════════════════════════════════════════

class AppTheme {
  // ════════════════════════════════════════════════════════════════════════
  // 📐 SECTION 1: DESIGN TOKENS (PRIMITIVES)
  // ════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────
  // SPACING SCALE (8pt Grid System)
  // ─────────────────────────────────────────────────────────────────────────
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;
  static const double spacing96 = 96.0;

  // ─────────────────────────────────────────────────────────────────────────
  // BORDER RADIUS SCALE
  // ─────────────────────────────────────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXL = 16.0;
  static const double radius2XL = 20.0;
  static const double radius3XL = 24.0;
  static const double radius4XL = 32.0;
  static const double radiusRound = 999.0;

  // ─────────────────────────────────────────────────────────────────────────
  // ICON SIZES
  // ─────────────────────────────────────────────────────────────────────────
  static const double iconXS = 12.0;
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXL = 32.0;
  static const double icon2XL = 48.0;
  static const double icon3XL = 64.0;

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 SECTION 2: COLOR SYSTEM (EXTENDED)
  // ════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND COLORS (Core Identity)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color brandBlue = Color(0xFF218BFF);
  static const Color brandGreen = Color(0xFF2DA44E);
  static const Color brandPurple = Color(0xFF8957E5);
  static const Color brandRed = Color(0xFFCF222E);
  static const Color brandYellow = Color(0xFFD29922);
  static const Color brandOrange = Color(0xFFFF9500);
  static const Color brandTeal = Color(0xFF17A2B8);
  static const Color brandPink = Color(0xFFE91E63);

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT MODE PALETTE
  // ─────────────────────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightBgSecondary = Color(0xFFFAFBFC);
  static const Color lightSurface = Color(0xFFF6F8FA);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceInteractive = Color(0xFFEBF0F5);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightBorderSubtle = Color(0xFFE8EDF3);
  static const Color lightTextPrimary = Color(0xFF24292F);
  static const Color lightTextSecondary = Color(0xFF57606A);
  static const Color lightTextMuted = Color(0xFF8C959F);
  static const Color lightAccent = Color(0xFF0969DA);
  static const Color lightOverlay = Color(0x1A000000);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK MODE PALETTE (GitHub Midnight)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkBgSecondary = Color(0xFF010409);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceElevated = Color(0xFF1C2128);
  static const Color darkSurfaceInteractive = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkBorderSubtle = Color(0xFF21262D);
  static const Color darkTextPrimary = Color(0xFFC9D1D9);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextMuted = Color(0xFF484F58);
  static const Color darkAccent = Color(0xFF58A6FF);
  static const Color darkOverlay = Color(0x33FFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC COLORS (Contextual Meaning)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2DA44E);
  static const Color successLight = Color(0xFFDCFFE4);
  static const Color successDark = Color(0xFF1A6635);

  static const Color warning = Color(0xFFD29922);
  static const Color warningLight = Color(0xFFFFF8DC);
  static const Color warningDark = Color(0xFF9A6700);

  static const Color error = Color(0xFFCF222E);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFF9A1A1F);

  static const Color info = Color(0xFF218BFF);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF0969DA);

  // ─────────────────────────────────────────────────────────────────────────
  // ALPHA VARIANTS (For overlays, backgrounds)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color blueAlpha10 = Color(0x1A218BFF);
  static const Color blueAlpha20 = Color(0x33218BFF);
  static const Color blueAlpha30 = Color(0x4D218BFF);

  static const Color greenAlpha10 = Color(0x1A2DA44E);
  static const Color greenAlpha20 = Color(0x332DA44E);
  static const Color greenAlpha30 = Color(0x4D2DA44E);

  static const Color purpleAlpha10 = Color(0x1A8957E5);
  static const Color purpleAlpha20 = Color(0x338957E5);
  static const Color purpleAlpha30 = Color(0x4D8957E5);

  static const Color yellowAlpha10 = Color(0x1AD29922);
  static const Color yellowAlpha20 = Color(0x33D29922);
  static const Color yellowAlpha30 = Color(0x4DD29922);

  static const Color redAlpha10 = Color(0x1ACF222E);
  static const Color redAlpha20 = Color(0x33CF222E);
  static const Color redAlpha30 = Color(0x4DCF222E);

  // ════════════════════════════════════════════════════════════════════════
  // 🌈 SECTION 3: GRADIENT SYSTEM
  // ════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND GRADIENTS (Linear)
  // ─────────────────────────────────────────────────────────────────────────
  static const Gradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradientWarning = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradientDanger = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradientPurple = LinearGradient(
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradientOcean = LinearGradient(
    colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradientSunset = LinearGradient(
    colors: [Color(0xFFFF512F), Color(0xFFF09819)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradientGreen = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // MESH GRADIENTS (Multi-stop for backgrounds)
  // ─────────────────────────────────────────────────────────────────────────
  static const Gradient meshDark = LinearGradient(
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient meshLight = LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2), Color(0xFFE0E7F1)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // SHIMMER GRADIENT (For loading states)
  // ─────────────────────────────────────────────────────────────────────────
  static const Gradient shimmerLight = LinearGradient(
    colors: [Color(0xFFEBEBF4), Color(0xFFF4F4F4), Color(0xFFEBEBF4)],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  static const Gradient shimmerDark = LinearGradient(
    colors: [Color(0xFF1C2128), Color(0xFF30363D), Color(0xFF1C2128)],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // RADIAL GRADIENTS (Spotlight effects)
  // ─────────────────────────────────────────────────────────────────────────
  static const Gradient spotlightBlue = RadialGradient(
    colors: [Color(0x33218BFF), Color(0x00218BFF)],
    center: Alignment.center,
    radius: 1.0,
  );

  static const Gradient spotlightGreen = RadialGradient(
    colors: [Color(0x332DA44E), Color(0x002DA44E)],
    center: Alignment.center,
    radius: 1.0,
  );

  // ════════════════════════════════════════════════════════════════════════
  // 🔦 SECTION 4: SHADOW & ELEVATION SYSTEM
  // ════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────
  // MATERIAL SHADOWS (5 Levels of Depth)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<BoxShadow> shadow1 = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadow2 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadow3 = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadow4 = [
    BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadow5 = [
    BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // GLOW EFFECTS (Colored shadows for emphasis)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<BoxShadow> glowBlue = [
    BoxShadow(color: Color(0x4D218BFF), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> glowGreen = [
    BoxShadow(color: Color(0x4D2DA44E), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> glowPurple = [
    BoxShadow(color: Color(0x4D8957E5), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> glowYellow = [
    BoxShadow(color: Color(0x4DD29922), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> glowRed = [
    BoxShadow(color: Color(0x4DCF222E), blurRadius: 20, offset: Offset(0, 4)),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // NEUMORPHIC SHADOWS (Soft depth effect)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<BoxShadow> neumorphicLight = [
    BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 10, offset: Offset(-5, -5)),
    BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(5, 5)),
  ];

  static const List<BoxShadow> neumorphicDark = [
    BoxShadow(color: Color(0x1AFFFFFF), blurRadius: 10, offset: Offset(-5, -5)),
    BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(5, 5)),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // INNER SHADOWS (For pressed states)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<BoxShadow> innerShadow = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      blurStyle: BlurStyle.inner,
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════
  // ⏱️ SECTION 5: MOTION DESIGN (ANIMATIONS)
  // ════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────
  // DURATIONS (Semantic naming)
  // ─────────────────────────────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration dramatic = Duration(milliseconds: 800);
  static const Duration epic = Duration(milliseconds: 1200);

  // ─────────────────────────────────────────────────────────────────────────
  // CUSTOM CURVES (Premium feel)
  // ─────────────────────────────────────────────────────────────────────────
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveSmooth = Curves.easeInOutQuart;
  static const Curve curveSnappy = Curves.easeOutExpo;
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveBounce = Curves.elasticOut;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;

  // ─────────────────────────────────────────────────────────────────────────
  // MICRO-INTERACTION DURATIONS
  // ─────────────────────────────────────────────────────────────────────────
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration cardFlip = Duration(milliseconds: 600);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration modalSlide = Duration(milliseconds: 400);
  static const Duration ripple = Duration(milliseconds: 300);

  // ════════════════════════════════════════════════════════════════════════
  // ✨ SECTION 6: GLASSMORPHISM & EFFECTS
  // ════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────
  // BLUR PRESETS
  // ─────────────────────────────────────────────────────────────────────────
  static final ui.ImageFilter blurLight = ui.ImageFilter.blur(
    sigmaX: 10,
    sigmaY: 10,
  );
  static final ui.ImageFilter blurMedium = ui.ImageFilter.blur(
    sigmaX: 20,
    sigmaY: 20,
  );
  static final ui.ImageFilter blurHeavy = ui.ImageFilter.blur(
    sigmaX: 40,
    sigmaY: 40,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // GLASS CONTAINER DECORATION BUILDER
  // ─────────────────────────────────────────────────────────────────────────
  static BoxDecoration glassContainer(
    BuildContext context, {
    double radius = radiusLarge,
    Color? color,
    bool elevated = false,
  }) {
    final isDark = context.isDarkMode;
    return BoxDecoration(
      color:
          color ??
          (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.03)),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        width: 1.5,
      ),
      boxShadow: elevated ? shadow3 : shadow1,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FROSTED GLASS WIDGET (Pre-built)
  // ─────────────────────────────────────────────────────────────────────────
  static Widget frostedGlass({
    required Widget child,
    double radius = radiusLarge,
    double blur = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🔤 SECTION 7: PREMIUM TYPOGRAPHY SYSTEM (GOOGLE FONTS)
  // ════════════════════════════════════════════════════════════════════════

  static TextTheme buildPremiumTextTheme(Color primary, Color secondary) {
    return TextTheme(
      // ─────────────────────────────────────────────────────────────────────
      // DISPLAY (Hero text) - Using Poppins for impact
      // ─────────────────────────────────────────────────────────────────────
      displayLarge: GoogleFonts.poppins(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -2.0,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -1.5,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -1.0,
        height: 1.2,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // HEADLINE (Section headers) - Poppins for hierarchy
      // ─────────────────────────────────────────────────────────────────────
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.25,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0,
        height: 1.4,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // TITLE (Card headers) - Inter for clarity
      // ─────────────────────────────────────────────────────────────────────
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.1,
        height: 1.5,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // BODY (Paragraph text) - Inter for readability
      // ─────────────────────────────────────────────────────────────────────
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        letterSpacing: 0,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
        letterSpacing: 0.1,
        height: 1.6,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
        letterSpacing: 0.2,
        height: 1.5,
      ),

      // ─────────────────────────────────────────────────────────────────────
      // LABEL (Buttons, Chips) - Inter Medium
      // ─────────────────────────────────────────────────────────────────────
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 0.8,
        height: 1.3,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 SECTION 8: COMPONENT STYLE VARIANTS
  // ════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────
  // BUTTON VARIANTS
  // ─────────────────────────────────────────────────────────────────────────
  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: brandGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.black.withOpacity(0.1);
        }
        return null;
      }),
    );
  }

  static ButtonStyle secondaryButton(BuildContext context) {
    final isDark = context.isDarkMode;
    return OutlinedButton.styleFrom(
      foregroundColor: isDark ? darkTextPrimary : lightTextPrimary,
      backgroundColor: isDark ? darkSurface : lightSurface,
      side: BorderSide(color: isDark ? darkBorder : lightBorder, width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle ghostButton(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: context.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle dangerButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: brandRed,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle glassmorphButton(BuildContext context) {
    final isDark = context.isDarkMode;
    return ElevatedButton.styleFrom(
      backgroundColor: isDark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.05),
      foregroundColor: isDark ? darkTextPrimary : lightTextPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.black.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD VARIANTS
  // ─────────────────────────────────────────────────────────────────────────
  static BoxDecoration elevatedCard(
    BuildContext context, {
    double radius = radiusLarge,
  }) {
    final isDark = context.isDarkMode;
    return BoxDecoration(
      color: isDark ? darkSurface : lightBg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow3,
    );
  }

  static BoxDecoration outlinedCard(
    BuildContext context, {
    double radius = radiusLarge,
  }) {
    final isDark = context.isDarkMode;
    return BoxDecoration(
      color: isDark ? darkSurface : lightBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: isDark ? darkBorder : lightBorder, width: 1.5),
    );
  }

  static BoxDecoration gradientCard({
    required Gradient gradient,
    double radius = radiusLarge,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow3,
    );
  }

  static BoxDecoration glassCard(
    BuildContext context, {
    double radius = radiusLarge,
  }) {
    return glassContainer(context, radius: radius, elevated: true);
  }

  static BoxDecoration glowCard({
    required Color glowColor,
    double radius = radiusLarge,
  }) {
    return BoxDecoration(
      color: glowColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glowColor.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INPUT FIELD VARIANTS
  // ─────────────────────────────────────────────────────────────────────────
  static InputDecoration floatingLabelInput(
    BuildContext context,
    String label, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final isDark = context.isDarkMode;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? darkBg : lightSurface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: BorderSide(color: isDark ? darkBorder : lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: BorderSide(color: isDark ? darkBorder : lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: BorderSide(
          color: isDark ? darkAccent : lightAccent,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        borderSide: const BorderSide(color: brandRed, width: 1.5),
      ),
      labelStyle: GoogleFonts.inter(
        color: isDark ? darkTextSecondary : lightTextSecondary,
      ),
      hintStyle: GoogleFonts.inter(
        color: isDark ? darkTextMuted : lightTextMuted,
      ),
    );
  }

  static InputDecoration searchInput(BuildContext context, String hint) {
    final isDark = context.isDarkMode;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        Icons.search,
        color: isDark ? darkTextMuted : lightTextMuted,
      ),
      filled: true,
      fillColor: isDark ? darkSurface : lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusRound),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusRound),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusRound),
        borderSide: BorderSide(
          color: isDark ? darkAccent : lightAccent,
          width: 2,
        ),
      ),
      hintStyle: GoogleFonts.inter(
        color: isDark ? darkTextMuted : lightTextMuted,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🎭 SECTION 9: THEME DATA (LIGHT & DARK)
  // ════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,

      // ═══ COLOR SCHEME ═══
      colorScheme: const ColorScheme.light(
        primary: lightAccent,
        secondary: brandGreen,
        surface: lightSurface,
        background: lightBg,
        error: brandRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
        outline: lightBorder,
        surfaceVariant: lightSurfaceElevated,
        tertiary: brandPurple,
      ),

      // ═══ APP BAR ═══
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: lightBg,
        foregroundColor: lightTextPrimary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary, size: 24),
        shape: const Border(
          bottom: BorderSide(color: lightBorderSubtle, width: 1),
        ),
      ),

      // ═══ CARDS ═══
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: lightBorder, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ═══ ELEVATED BUTTONS ═══
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ═══ OUTLINED BUTTONS ═══
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          backgroundColor: lightSurface,
          side: const BorderSide(color: lightBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ═══ TEXT BUTTONS ═══
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightAccent,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ═══ INPUT FIELDS ═══
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: lightBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: lightBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: lightAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: brandRed, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: lightTextSecondary),
        hintStyle: GoogleFonts.inter(color: lightTextMuted),
      ),

      // ═══ DIVIDERS ═══
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),

      // ═══ BOTTOM NAV ═══
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightBg,
        selectedItemColor: lightAccent,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ═══ CHIP ═══
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        deleteIconColor: lightTextSecondary,
        labelStyle: GoogleFonts.inter(color: lightTextPrimary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: lightBorder),
        ),
      ),

      // ═══ FLOATING ACTION BUTTON ═══
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ═══ DIALOG ═══
      dialogTheme: DialogThemeData(
        backgroundColor: lightBg,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius3XL),
        ),
      ),

      // ═══ BOTTOM SHEET ═══
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lightBg,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius3XL)),
        ),
      ),

      // ═══ SNACKBAR ═══
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // ═══ PREMIUM TYPOGRAPHY ═══
      textTheme: buildPremiumTextTheme(lightTextPrimary, lightTextSecondary),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,

      // ═══ COLOR SCHEME ═══
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        secondary: brandGreen,
        surface: darkSurface,
        background: darkBg,
        error: brandRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
        outline: darkBorder,
        surfaceVariant: darkSurfaceElevated,
        tertiary: brandPurple,
      ),

      // ═══ APP BAR ═══
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: darkBg,
        foregroundColor: darkTextPrimary,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary, size: 24),
        shape: const Border(
          bottom: BorderSide(color: darkBorderSubtle, width: 1),
        ),
      ),

      // ═══ CARDS ═══
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: darkBorder, width: 1.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ═══ ELEVATED BUTTONS ═══
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ═══ OUTLINED BUTTONS ═══
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          backgroundColor: darkSurface,
          side: const BorderSide(color: darkBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ═══ TEXT BUTTONS ═══
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkAccent,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ═══ INPUT FIELDS ═══
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBg,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: darkAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: brandRed, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary),
        hintStyle: GoogleFonts.inter(color: darkTextMuted),
      ),

      // ═══ DIVIDERS ═══
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // ═══ BOTTOM NAV ═══
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBg,
        selectedItemColor: darkAccent,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ═══ CHIP ═══
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        deleteIconColor: darkTextSecondary,
        labelStyle: GoogleFonts.inter(color: darkTextPrimary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: darkBorder),
        ),
      ),

      // ═══ FLOATING ACTION BUTTON ═══
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ═══ DIALOG ═══
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius3XL),
        ),
      ),

      // ═══ BOTTOM SHEET ═══
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius3XL)),
        ),
      ),

      // ═══ SNACKBAR ═══
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      // ═══ PREMIUM TYPOGRAPHY ═══
      textTheme: buildPremiumTextTheme(darkTextPrimary, darkTextSecondary),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🧩 SECTION 10: PRE-BUILT WIDGETS (READY TO USE)
  // ════════════════════════════════════════════════════════════════════════

  /// Glass Box Widget (renamed from glassContainer to avoid conflict)
  static Widget glassBox({
    required Widget child,
    double radius = radiusLarge,
    EdgeInsets? padding,
    Color? color,
    required BuildContext context,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: AppTheme.glassContainer(
        context,
        radius: radius,
        color: color,
      ),
      child: child,
    );
  }

  /// Gradient Text Widget
  static Widget gradientText(
    String text, {
    required Gradient gradient,
    TextStyle? style,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(
        text,
        style:
            style?.copyWith(color: Colors.white) ??
            GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  /// Shimmer Loading Container
  static Widget shimmerContainer({
    required BuildContext context,
    double width = 100,
    double height = 20,
    double radius = radiusMedium,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isDark ? shimmerDark : shimmerLight,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// Icon Container with Colored Background
  static Widget iconContainer({
    required IconData icon,
    required Color color,
    double size = iconLarge,
    double containerSize = 48,
    double radius = radiusLarge,
  }) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  /// Glow Container (Card with colored glow)
  static Widget glowContainer({
    required Widget child,
    required Color glowColor,
    double radius = radiusLarge,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: glowCard(glowColor: glowColor, radius: radius),
      child: child,
    );
  }

  /// Premium Divider with Optional Label
  static Widget divider({
    BuildContext? context,
    String? label,
    Color? color,
    double height = 1,
    double thickness = 1,
  }) {
    if (label != null) {
      return Row(
        children: [
          Expanded(
            child: Divider(
              color:
                  color ??
                  (context != null ? context.borderColor : lightBorder),
              height: height,
              thickness: thickness,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: context != null
                    ? context.theme.hintColor
                    : lightTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color:
                  color ??
                  (context != null ? context.borderColor : lightBorder),
              height: height,
              thickness: thickness,
            ),
          ),
        ],
      );
    }
    return Divider(
      color: color ?? (context != null ? context.borderColor : lightBorder),
      height: height,
      thickness: thickness,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 🔧 SECTION 11: THEME EXTENSIONS (CONTEXT HELPERS)
// ══════════════════════════════════════════════════════════════════════════

extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ─────────────────────────────────────────────────────────────────────────
  // SEMANTIC COLORS
  // ─────────────────────────────────────────────────────────────────────────
  Color get primaryColor => colorScheme.primary;
  Color get backgroundColor => colorScheme.background;
  Color get surfaceColor => colorScheme.surface;
  Color get onSurfaceColor => colorScheme.onSurface;
  Color get borderColor => theme.dividerColor;
  Color get errorColor => colorScheme.error;
  Color get successColor => AppTheme.success;
  Color get warningColor => AppTheme.warning;
  Color get infoColor => AppTheme.info;

  // ─────────────────────────────────────────────────────────────────────────
  // SURFACE VARIANTS
  // ─────────────────────────────────────────────────────────────────────────
  Color get surfaceElevated =>
      isDarkMode ? AppTheme.darkSurfaceElevated : AppTheme.lightSurfaceElevated;

  Color get surfaceInteractive => isDarkMode
      ? AppTheme.darkSurfaceInteractive
      : AppTheme.lightSurfaceInteractive;

  // ─────────────────────────────────────────────────────────────────────────
  // RESPONSIVE UTILITIES
  // ─────────────────────────────────────────────────────────────────────────
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 768;
  bool get isLargeScreen => screenWidth >= 768;

  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLightMode => theme.brightness == Brightness.light;

  // ─────────────────────────────────────────────────────────────────────────
  // STANDARD PADDING
  // ─────────────────────────────────────────────────────────────────────────
  EdgeInsets get screenPadding => const EdgeInsets.symmetric(
    horizontal: AppTheme.spacing20,
    vertical: AppTheme.spacing16,
  );

  EdgeInsets get cardPadding => const EdgeInsets.all(AppTheme.spacing16);
  EdgeInsets get sectionPadding => const EdgeInsets.all(AppTheme.spacing24);

  // ─────────────────────────────────────────────────────────────────────────
  // SAFE AREA HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  double get topSafeArea => MediaQuery.of(this).padding.top;
  double get bottomSafeArea => MediaQuery.of(this).padding.bottom;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  // ─────────────────────────────────────────────────────────────────────────
  // THEME SWITCHER
  // ─────────────────────────────────────────────────────────────────────────
  void setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}
