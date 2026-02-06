import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const primaryBlue = Color(0xFF0969DA);
  static const successGreen = Color(0xFF1F883D);
  static const errorRed = Color(0xFFCF222E);
  static const warningOrange = Color(0xFF9A6700);

  // Sky Gradients (Main Theme)
  static const skyDawnTop = Color(0xFFFF9A8B);
  static const skyDawnBottom = Color(0xFFFECFEF);
  static const skyDayTop = Color(0xFF4A90E2);
  static const skyDayBottom = Color(0xFF87CEEB);
  static const skyDuskTop = Color(0xFF6B4CE6);
  static const skyDuskBottom = Color(0xFFFF6B9D);
  static const skyNightTop = Color(0xFF0F2027);
  static const skyNightBottom = Color(0xFF2C5364);

  // Sky Accents
  static const skyDawnAccent = Color(0xFFFF6B95);
  static const skyDayAccent = Color(0xFF2E5BFF);
  static const skyDuskAccent = Color(0xFF9D50E0);
  static const skyNightAccent = Color(0xFF64B5F6);

  // Light/Dark Mode
  static const lightBg = Color(0xFFF6F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF24292F);
  static const lightBorder = Color(0xFFD0D7DE);
  static const darkBg = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkText = Color(0xFFC9D1D9);
  static const darkBorder = Color(0xFF30363D);

  // Sizing
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Typography
  static const double fontCaption = 11.0;
  static const double fontSmall = 12.0;
  static const double fontBody = 13.0;
  static const double fontBase = 14.0;
  static const double fontMedium = 15.0;
  static const double fontLarge = 16.0;
  static const double fontTitle = 18.0;
  static const double fontHeadline = 24.0;
  static const double fontDisplay = 32.0;

  // Sky Gradients
  static const skyDawn = LinearGradient(
      colors: [skyDawnTop, skyDawnBottom],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const skyDay = LinearGradient(
      colors: [skyDayTop, skyDayBottom],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const skyDusk = LinearGradient(
      colors: [skyDuskTop, skyDuskBottom],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);
  static const skyNight = LinearGradient(
      colors: [skyNightTop, skyNightBottom],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight);

  // Helper: Get sky gradient by progress (0-1)
  static LinearGradient skyGradient(double progress) {
    if (progress < 0.25) return skyDawn;
    if (progress < 0.5) return skyDay;
    if (progress < 0.75) return skyDusk;
    return skyNight;
  }

  // Helper: Get sky accent by progress (0-1)
  static Color skyAccent(double progress) {
    if (progress < 0.25) return skyDawnAccent;
    if (progress < 0.5) return skyDayAccent;
    if (progress < 0.75) return skyDuskAccent;
    return skyNightAccent;
  }

  // Helper: Get sky gradient by index (0-3)
  static LinearGradient skyByIndex(int index) {
    switch (index) {
      case 0:
        return skyDay;
      case 1:
        return skyDusk;
      case 2:
        return skyNight;
      default:
        return skyDawn;
    }
  }

  // Helper: Get sky accent by index (0-3)
  static Color skyAccentByIndex(int index) {
    switch (index) {
      case 0:
        return skyDayAccent;
      case 1:
        return skyDuskAccent;
      case 2:
        return skyNightAccent;
      default:
        return skyDawnAccent;
    }
  }

  // Helper: Check if sky is dark
  static bool isSkyDark(double progress) => progress >= 0.5;
  static bool isSkyDarkByIndex(int index) => index >= 1;

  // Helper: Text colors for sky
  static Color skyTextColor(bool isDark) => isDark ? lightSurface : lightText;
  static Color skySubtextColor(bool isDark) =>
      isDark ? darkText : lightText.withValues(alpha: 0.7);

  // Glass card decoration
  static BoxDecoration glassCard({double blur = 0.1, Color? tint}) =>
      BoxDecoration(
        color: (tint ?? lightSurface).withValues(alpha: blur),
        borderRadius: BorderRadius.circular(radiusLarge),
        border: Border.all(color: lightSurface.withValues(alpha: 0.2)),
      );

  // Shadow helper
  static List<BoxShadow> shadow(Color color,
          {double blur = 24.0, double spread = 0.0, double opacity = 0.15}) =>
      [
        BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: blur,
            spreadRadius: spread,
            offset: const Offset(0, 8))
      ];

  // Material themes
  static ThemeData lightTheme(BuildContext c) => _buildTheme(
      c,
      Brightness.light,
      const ColorScheme(
        brightness: Brightness.light,
        primary: primaryBlue,
        onPrimary: lightSurface,
        secondary: successGreen,
        onSecondary: lightSurface,
        error: errorRed,
        onError: lightSurface,
        surface: lightSurface,
        onSurface: lightText,
        surfaceContainerHighest: lightBg,
        outline: lightBorder,
      ));

  static ThemeData darkTheme(BuildContext c) => _buildTheme(
      c,
      Brightness.dark,
      const ColorScheme(
        brightness: Brightness.dark,
        primary: skyDayAccent,
        onPrimary: darkBg,
        secondary: successGreen,
        onSecondary: darkBg,
        error: errorRed,
        onError: darkBg,
        surface: darkSurface,
        onSurface: darkText,
        surfaceContainerHighest: darkBg,
        outline: darkBorder,
      ));

  static ThemeData _buildTheme(BuildContext c, Brightness b, ColorScheme s) {
    final base = ThemeData(useMaterial3: true, colorScheme: s, brightness: b);
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      scaffoldBackgroundColor: s.surfaceContainerHighest,
      extensions: [AppThemeExt(isLight: b == Brightness.light)],
      appBarTheme: base.appBarTheme.copyWith(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              b == Brightness.light ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: s.surfaceContainerHighest,
          systemNavigationBarIconBrightness:
              b == Brightness.light ? Brightness.dark : Brightness.light,
        ),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: s.surface,
        indicatorColor: s.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: fontSmall)),
      ),
    );
  }
}

// Theme Extension for heatmap colors
class AppThemeExt extends ThemeExtension<AppThemeExt> {
  final List<Color> heatmapLevels;
  final Color heatmapHighlight;

  AppThemeExt({required bool isLight})
      : heatmapLevels = isLight
            ? [
                const Color(0xFFEBEDF0),
                const Color(0xFF9BE9A8),
                const Color(0xFF40C463),
                const Color(0xFF30A14E),
                const Color(0xFF216E39)
              ]
            : [
                const Color(0xFF161B22),
                const Color(0xFF0E4429),
                const Color(0xFF006D32),
                const Color(0xFF26A641),
                const Color(0xFF39D353)
              ],
        heatmapHighlight = const Color(0xFFFF9500);

  Color get heatmapTodayHighlight => heatmapHighlight;

  @override
  ThemeExtension<AppThemeExt> copyWith(
          {List<Color>? heatmapLevels, Color? heatmapHighlight}) =>
      AppThemeExt(isLight: true);

  @override
  ThemeExtension<AppThemeExt> lerp(
          ThemeExtension<AppThemeExt>? other, double t) =>
      this;

  static AppThemeExt of(BuildContext c) =>
      Theme.of(c).extension<AppThemeExt>()!;
}

// Context extension
extension ThemeContext on BuildContext {
  AppThemeExt get appTheme => AppThemeExt.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get colors => Theme.of(this).colorScheme;
}

// Reusable card widget
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext c) {
    final s = c.colors;
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: s.outline.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}

// Section header widget
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext c) {
    final s = c.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: s.onSurface,
                      fontSize: AppTheme.fontTitle,
                      fontWeight: FontWeight.w700,
                      height: 1.1)),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacing8),
                Text(subtitle!,
                    style: TextStyle(
                        color: s.onSurface.withValues(alpha: 0.7),
                        fontSize: AppTheme.fontBody,
                        fontWeight: FontWeight.w500,
                        height: 1.3)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppTheme.spacing12),
          trailing!
        ],
      ],
    );
  }
}

// Metric tile widget
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const MetricTile(
      {super.key,
      required this.label,
      required this.value,
      this.helper,
      required this.icon,
      this.iconColor,
      this.onTap});

  @override
  Widget build(BuildContext c) {
    final s = c.colors;
    final col = iconColor ?? s.primary;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: col.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: col, size: 20),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: s.onSurface,
                        fontSize: AppTheme.fontHeadline,
                        fontWeight: FontWeight.w800,
                        height: 1.0)),
                if (helper != null) ...[
                  const SizedBox(height: 4),
                  Text(helper!,
                      style: TextStyle(
                          color: col,
                          fontSize: AppTheme.fontCaption,
                          fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: AppTheme.spacing8),
                Text(label,
                    style: TextStyle(
                        color: s.onSurface.withValues(alpha: 0.7),
                        fontSize: AppTheme.fontBody,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
