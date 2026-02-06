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
  static const Color seedColor = Color(0xFF0969DA);
  static const Color accentPurple = Color(0xFF8250DF);
  static const Color accentTeal = Color(0xFF1B7C83);

  // ════════════════════════════════════════════════════════════════════════
  // ☀️ LIGHT THEME
  // ════════════════════════════════════════════════════════════════════════

  static ThemeData lightTheme(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF0969DA),
        onPrimary: Colors.white,
        secondary: Color(0xFF1F883D),
        onSecondary: Colors.white,
        error: Color(0xFFCF222E),
        onError: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF24292F),
        surfaceContainerHighest: Color(0xFFF6F8FA),
        outline: Color(0xFFD0D7DE),
      ),
      brightness: Brightness.light,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      extensions: [
        AppThemeExtension.light(),
      ],
      appBarTheme: base.appBarTheme.copyWith(
        systemOverlayStyle: _lightOverlayStyle,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: const Color(0xFFFFFFFF),
        indicatorColor: const Color(0x1A0969DA),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // 🌙 DARK THEME
  // ════════════════════════════════════════════════════════════════════════

  static ThemeData darkTheme(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF2F81F7),
        onPrimary: Color(0xFF0D1117),
        secondary: Color(0xFF3FB950),
        onSecondary: Color(0xFF0D1117),
        error: Color(0xFFFF7B72),
        onError: Color(0xFF0D1117),
        surface: Color(0xFF161B22),
        onSurface: Color(0xFFC9D1D9),
        surfaceContainerHighest: Color(0xFF0D1117),
        outline: Color(0xFF30363D),
      ),
      brightness: Brightness.dark,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      extensions: [
        AppThemeExtension.dark(),
      ],
      appBarTheme: base.appBarTheme.copyWith(
        systemOverlayStyle: _darkOverlayStyle,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: const Color(0xFF161B22),
        indicatorColor: const Color(0x1A2F81F7),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SYSTEM UI OVERLAY STYLES
  // ════════════════════════════════════════════════════════════════════════

  static const SystemUiOverlayStyle _lightOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF6F8FA),
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
      Color(0xFF0969DA),
      Color(0xFF2F81F7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF6F8FA),
      Color(0xFFFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );

  // ════════════════════════════════════════════════════════════════════════
  // STATIC PROPERTIES
  // ════════════════════════════════════════════════════════════════════════
  
  // Main theme
  static ThemeData theme(BuildContext context) => lightTheme(context);
  
  // Colors - Functional
  static const Color primaryBlue = Color(0xFF0969DA);
  static const Color successGreen = Color(0xFF1F883D);
  static const Color errorRed = Color(0xFFCF222E);
  static const Color warningOrange = Color(0xFF9A6700);
  
  // Colors - Backgrounds
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF6F8FA);
  
  // Colors - Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF24292F);
  static const Color textSecondary = Color(0xFF57606A);
  static const Color textTertiary = Color(0xFF6E7781);
  
  // Colors - Borders
  static const Color borderLight = Color(0xFFD0D7DE);
  static const Color previewBorder = Color(0xFF222222);

  // Colors - Stat cards (semantic icons)
  static const Color statOrange = Color(0xFFFF9500);
  static const Color statAmber = Color(0xFF9A6700);
  static const Color statBlue = Color(0xFF0969DA);
  static const Color statPurple = Color(0xFF8250DF);
  static const Color statTeal = Color(0xFF1B7C83);

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
    const levels = [
      Color(0xFFEBEDF0),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
    assert(levels.length == 5);
    assert(levels[1] == Color(0xFF9BE9A8));
    assert(levels[4] == Color(0xFF216E39));

    return const AppThemeExtension(
      headerGradient: AppTheme.headerGradient,
      backgroundGradient: AppTheme.backgroundGradient,
      heatmapLevels: levels,
      heatmapTodayHighlight: Color(0xFFFF9500),
    );
  }

  // Dark Mode
  factory AppThemeExtension.dark() {
    const levels = [
      Color(0xFF161B22),
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
    assert(levels.length == 5);
    assert(levels[0] == Color(0xFF161B22));
    assert(levels[4] == Color(0xFF216E39));

    return const AppThemeExtension(
      headerGradient: AppTheme.headerGradient,
      backgroundGradient: AppTheme.backgroundGradient,
      heatmapLevels: levels,
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

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacing20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.8)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: AppTheme.fontSizeTitle,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontSize: AppTheme.fontSizeBody,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppTheme.spacing12),
          trailing!,
        ],
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? helper;
  final VoidCallback? onTap;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.helper,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = iconColor ?? scheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: c.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: AppTheme.fontSizeHeadline,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontSize: AppTheme.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (helper != null) ...[
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    helper!,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.60),
                      fontSize: AppTheme.fontSizeCaption,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
