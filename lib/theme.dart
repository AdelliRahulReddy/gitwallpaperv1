// ══════════════════════════════════════════════════════════════════════════
// 🎨 THEME - Production Ready
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════════════════
// MAIN THEME PROVIDER
// ══════════════════════════════════════════════════════════════════════════

class AppTheme {
  // Brand Colors
  static const Color seedColor = Color(0xFF3B82F6); // Primary Blue
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentTeal = Color(0xFF14B8A6);

  // ════════════════════════════════════════════════════════════════════════
  // ☀️ LIGHT THEME
  // ════════════════════════════════════════════════════════════════════════

  static ThemeData lightTheme(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: Brightness.light,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      extensions: [
        AppThemeExtension.light(),
      ],
      appBarTheme: base.appBarTheme.copyWith(
        systemOverlayStyle: _lightOverlayStyle,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🌙 DARK THEME
  // ════════════════════════════════════════════════════════════════════════

  static ThemeData darkTheme(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seedColor,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      extensions: [
        AppThemeExtension.dark(),
      ],
      appBarTheme: base.appBarTheme.copyWith(
        systemOverlayStyle: _darkOverlayStyle,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SYSTEM UI OVERLAY STYLES
  // ════════════════════════════════════════════════════════════════════════

  static const SystemUiOverlayStyle _lightOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle _darkOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F172A),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  // ════════════════════════════════════════════════════════════════════════
  // GRADIENTS (Custom to your app)
  // ════════════════════════════════════════════════════════════════════════

  static const LinearGradient headerGradient = LinearGradient(
    colors: [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFEFF6FF), // Very light blue
      Color(0xFFFAF5FF), // Very light purple
      Color(0xFFF0FDFA), // Very light teal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ════════════════════════════════════════════════════════════════════════
  // STATIC PROPERTIES
  // ════════════════════════════════════════════════════════════════════════
  
  // Main theme
  static ThemeData theme(BuildContext context) => lightTheme(context);
  
  // Colors - Functional
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  
  // Colors - Backgrounds
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF8FAFC);
  
  // Colors - Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  
  // Colors - Borders
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color previewBorder = Color(0xFF222222);

  // Colors - Stat cards (semantic icons)
  static const Color statOrange = Color(0xFFFF9500);
  static const Color statAmber = Color(0xFFF59E0B);
  static const Color statBlue = Color(0xFF3B82F6);
  static const Color statPurple = Color(0xFF8B5CF6);
  static const Color statTeal = Color(0xFF14B8A6);

  // Colors - GitHub dark palette (cards, dark surfaces)
  static const Color githubDarkBg = Color(0xFF0D1117);
  static const Color githubDarkCard = Color(0xFF161B22);

  // Colors - Overlays on dark surfaces
  static const Color whiteMuted = Color(0xB3FFFFFF); // white 70%
  static const Color whiteSubtle = Color(0x3DFFFFFF); // white 24%
  static const Color whiteBorder = Color(0x1FFFFFFF); // white 12%

  // Gradients
  static const LinearGradient mainBgGradient = backgroundGradient;
  static const LinearGradient slideGradient1 = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient slideGradient2 = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Radii
  static const double radiusXSmall = 4.0;
  static const double radiusSmall = 8.0;
  static const double radius10 = 10.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radius2XLarge = 24.0;
  static const double radius3XLarge = 30.0;

  // Spacing
  static const double spacing3 = 3.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Font sizes
  static const double fontSizeCaption = 11.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeBody = 13.0;
  static const double fontSizeSub = 13.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeMedium = 15.0;
  static const double fontSizeLead = 16.0;
  static const double fontSizeTitle = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeDisplay = 26.0;
  
  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
  
  // Decorations
  static BoxDecoration whiteCard() => BoxDecoration(
    color: bgWhite,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: cardShadow,
  );
  
  static BoxDecoration gradientCard(LinearGradient gradient) => BoxDecoration(
    gradient: gradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: cardShadow,
  );
  
  static List<BoxShadow> gradientShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// ══════════════════════════════════════════════════════════════════════════
// THEME EXTENSION - Custom Properties
// ══════════════════════════════════════════════════════════════════════════

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final LinearGradient headerGradient;
  final LinearGradient backgroundGradient;
  final List<Color> heatmapLevels;
  final Color heatmapTodayHighlight;

  const AppThemeExtension({
    required this.headerGradient,
    required this.backgroundGradient,
    required this.heatmapLevels,
    required this.heatmapTodayHighlight,
  });

  // Light Mode
  factory AppThemeExtension.light() {
    return const AppThemeExtension(
      headerGradient: AppTheme.headerGradient,
      backgroundGradient: AppTheme.backgroundGradient,
      heatmapLevels: [
        Color(0xFFEBEDF0), // Level 0 (Empty)
        Color(0xFF9BE9A8), // Level 1
        Color(0xFF40C463), // Level 2
        Color(0xFF30A14E), // Level 3
        Color(0xFF216E39), // Level 4
      ],
      heatmapTodayHighlight: Color(0xFFFF9500),
    );
  }

  // Dark Mode
  factory AppThemeExtension.dark() {
    return const AppThemeExtension(
      headerGradient: AppTheme.headerGradient,
      backgroundGradient: AppTheme.backgroundGradient,
      heatmapLevels: [
        Color(0xFF161B22), // Level 0 (Empty)
        Color(0xFF0E4429), // Level 1
        Color(0xFF006D32), // Level 2
        Color(0xFF26A641), // Level 3
        Color(0xFF39D353), // Level 4
      ],
      heatmapTodayHighlight: Color(0xFFFF9500),
    );
  }

  // Required for ThemeExtension
  @override
  ThemeExtension<AppThemeExtension> copyWith({
    LinearGradient? headerGradient,
    LinearGradient? backgroundGradient,
    List<Color>? heatmapLevels,
    Color? heatmapTodayHighlight,
  }) {
    return AppThemeExtension(
      headerGradient: headerGradient ?? this.headerGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      heatmapLevels: heatmapLevels ?? this.heatmapLevels,
      heatmapTodayHighlight:
          heatmapTodayHighlight ?? this.heatmapTodayHighlight,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      headerGradient:
          LinearGradient.lerp(headerGradient, other.headerGradient, t)!,
      backgroundGradient:
          LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      heatmapLevels: List.generate(
        5,
        (i) => Color.lerp(heatmapLevels[i], other.heatmapLevels[i], t)!,
      ),
      heatmapTodayHighlight:
          Color.lerp(heatmapTodayHighlight, other.heatmapTodayHighlight, t)!,
    );
  }

  // Helper to get extension from context
  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>()!;
  }

  // Safe color access with bounds checking
  Color getHeatmapColor(int level) {
    if (level < 0 || level >= heatmapLevels.length) {
      return heatmapLevels[0]; // Return empty color if out of bounds
    }
    return heatmapLevels[level];
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HELPER EXTENSIONS
// ══════════════════════════════════════════════════════════════════════════

extension ThemeGetter on BuildContext {
  AppThemeExtension get appTheme => AppThemeExtension.of(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
