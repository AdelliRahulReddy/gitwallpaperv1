import 'package:flutter/material.dart';

class AppConstants {
  // ══════════════════════════════════════════════════════════════════════════
  // GITHUB API CONFIGURATION
  // ══════════════════════════════════════════════════════════════════════════

  static const String githubApiUrl = 'https://api.github.com/graphql';
  static const Duration apiTimeout = Duration(
    seconds: 30,
  ); // ✅ Reduced from 60s

  // ══════════════════════════════════════════════════════════════════════════
  // GITHUB DARK THEME COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFC9D1D9);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkAccent = Color(0xFF58A6FF);
  static const Color darkSuccess = Color(0xFF238636);

  // ══════════════════════════════════════════════════════════════════════════
  // GITHUB LIGHT THEME COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF6F8FA);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightTextPrimary = Color(0xFF24292F);
  static const Color lightTextSecondary = Color(0xFF57606A);
  static const Color lightAccent = Color(0xFF0969DA);
  static const Color lightSuccess = Color(0xFF2DA44E);

  // ══════════════════════════════════════════════════════════════════════════
  // CONTRIBUTION COLORS (GitHub Green Scale)
  // ══════════════════════════════════════════════════════════════════════════

  // Dark mode contribution levels
  static const Color level0 = Color(0xFF161B22); // Empty
  static const Color level1 = Color(0xFF0E4429); // 1-3 contributions
  static const Color level2 = Color(0xFF006D32); // 4-6 contributions
  static const Color level3 = Color(0xFF26A641); // 7-9 contributions
  static const Color level4 = Color(0xFF39D353); // 10+ contributions

  // Light mode contribution levels
  static const Color level0Light = Color(0xFFEBEDF0); // Empty
  static const Color level1Light = Color(0xFF9BE9A8); // 1-3 contributions
  static const Color level2Light = Color(0xFF40C463); // 4-6 contributions
  static const Color level3Light = Color(0xFF30A14E); // 7-9 contributions
  static const Color level4Light = Color(0xFF216E39); // 10+ contributions

  // Today highlight (orange glow)
  static const Color todayHighlight = Color(0xFFFF9500);

  // ══════════════════════════════════════════════════════════════════════════
  // HEATMAP DISPLAY SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  static const double boxSize = 12.0; // Size of each day square
  static const double boxSpacing = 3.0; // Gap between squares
  static const double boxRadius = 2.0; // Corner radius of squares
  static const double todayBorderWidth = 2.0; // Border width for today's square

  // ══════════════════════════════════════════════════════════════════════════
  // DEFAULT WALLPAPER POSITION
  // ══════════════════════════════════════════════════════════════════════════

  static const double defaultVerticalPosition = 0.5; // Centered vertically
  static const double defaultHorizontalPosition = 0.5; // Centered horizontally
  static const double defaultScale = 0.7; // 70% size

  // ══════════════════════════════════════════════════════════════════════════
  // CUSTOMIZATION RANGES
  // ══════════════════════════════════════════════════════════════════════════

  // Position ranges (0.0 = top/left, 1.0 = bottom/right)
  static const double minVerticalPos = 0.0;
  static const double maxVerticalPos = 1.0;

  // Scale range (0.5 = 50% size, 2.0 = 200% size)
  static const double minScale = 0.5;
  static const double maxScale = 2.0;

  // ══════════════════════════════════════════════════════════════════════════
  // WORKMANAGER CONFIGURATION (BACKGROUND TASKS)
  // ══════════════════════════════════════════════════════════════════════════

  static const String wallpaperTaskName = 'github-wallpaper-update';
  static const String wallpaperTaskTag = 'updateGitHubWallpaper';

  // ✅ TESTING: Reduced to 15 minutes for verification (Android minimum)
  static const Duration updateInterval = Duration(minutes: 15);

  // Minimum interval for WorkManager (Android requirement)
  static const Duration minimumInterval = Duration(minutes: 15);

  // ══════════════════════════════════════════════════════════════════════════
  // STORAGE KEYS (SharedPreferences)
  // ══════════════════════════════════════════════════════════════════════════

  static const String keyUsername = 'github_username';
  static const String keyToken = 'github_token';
  static const String keyDarkMode = 'isDarkMode';
  static const String keyVerticalPos = 'verticalPosition';
  static const String keyHorizontalPos = 'horizontalPosition';
  static const String keyScale = 'scale';
  static const String keyCustomQuote = 'customQuote';
  static const String keyCachedData = 'cachedData';
  static const String keyLastUpdate = 'lastUpdate';

  // ══════════════════════════════════════════════════════════════════════════
  // WALLPAPER DIMENSIONS (Standard FHD+ for modern phones)
  // ══════════════════════════════════════════════════════════════════════════

  static const int wallpaperWidth = 1080; // Full HD width
  static const int wallpaperHeight =
      2400; // 20:9 aspect ratio (common on 2020+ phones)

  // Alternative dimensions for different screen ratios
  static const int wallpaperWidthQHD = 1440; // QHD (1440p)
  static const int wallpaperHeightQHD = 3200; // QHD height
}
