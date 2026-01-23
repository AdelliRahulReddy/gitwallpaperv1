import 'dart:ui';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════
// ⚙️ APP CONSTANTS - AUTO-DETECT DEVICE
// ══════════════════════════════════════════════════════════════════════════
// Single source of truth for all app configuration
// Now with automatic device dimension detection
// ══════════════════════════════════════════════════════════════════════════

class AppConstants {
  // ════════════════════════════════════════════════════════════════════════
  // 🌐 API CONFIGURATION
  // ════════════════════════════════════════════════════════════════════════

  static const String githubApiUrl = 'https://api.github.com/graphql';
  static const Duration apiTimeout = Duration(seconds: 30);

  // ════════════════════════════════════════════════════════════════════════
  // 🎨 HEATMAP COLORS
  // ════════════════════════════════════════════════════════════════════════

  // Dark Mode
  static const Color heatmapDarkBg = Color(0xFF0D1117);
  static const Color heatmapDarkBox = Color(0xFF161B22);
  static const Color heatmapDarkLevel1 = Color(0xFF0E4429);
  static const Color heatmapDarkLevel2 = Color(0xFF006D32);
  static const Color heatmapDarkLevel3 = Color(0xFF26A641);
  static const Color heatmapDarkLevel4 = Color(0xFF39D353);

  // Light Mode
  static const Color heatmapLightBg = Color(0xFFFFFFFF);
  static const Color heatmapLightBox = Color(0xFFEBEDF0);
  static const Color heatmapLightLevel1 = Color(0xFF9BE9A8);
  static const Color heatmapLightLevel2 = Color(0xFF40C463);
  static const Color heatmapLightLevel3 = Color(0xFF30A14E);
  static const Color heatmapLightLevel4 = Color(0xFF216E39);

  // Highlights
  static const Color todayHighlight = Color(0xFFFF9500);

  // ════════════════════════════════════════════════════════════════════════
  // 📐 HEATMAP LAYOUT
  // ════════════════════════════════════════════════════════════════════════

  static const double boxSize = 12.0;
  static const double boxSpacing = 3.0;
  static const double boxRadius = 2.0;
  static const double todayBorderWidth = 2.0;

  // ════════════════════════════════════════════════════════════════════════
  // 🖼️ WALLPAPER SETTINGS - AUTO-DETECTED
  // ════════════════════════════════════════════════════════════════════════

  // Defaults
  static const double defaultVerticalPosition = 0.5;
  static const double defaultHorizontalPosition = 0.5;
  static const double defaultScale = 0.7;

  // Limits
  static const double minVerticalPos = 0.0;
  static const double maxVerticalPos = 1.0;
  static const double minScale = 0.5;
  static const double maxScale = 2.0;

  // Resolution - AUTO-DETECTED (initialized at runtime)
  static late double wallpaperWidth;
  static late double wallpaperHeight;

  // Fallback defaults (if detection fails)
  static const double fallbackWidth = 1080.0;
  static const double fallbackHeight = 2340.0;

  // Flag to track if device was detected
  static bool _isInitialized = false;

  /// Initialize wallpaper dimensions from device
  /// Call this ONCE when app starts
  static void initializeFromContext(BuildContext context) {
    if (_isInitialized) {
      debugPrint('⚠️ AppConstants already initialized, skipping...');
      return;
    }

    try {
      final size = MediaQuery.of(context).size;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;

      // Calculate physical pixels
      wallpaperWidth = size.width * pixelRatio;
      wallpaperHeight = size.height * pixelRatio;

      _isInitialized = true;

      // Log device info
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('📱 DEVICE AUTO-DETECTED');
      debugPrint('═══════════════════════════════════════════════');
      debugPrint(
        'Logical Size:    ${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)} dp',
      );
      debugPrint(
        'Physical Pixels: ${wallpaperWidth.toStringAsFixed(0)} × ${wallpaperHeight.toStringAsFixed(0)} px',
      );
      debugPrint('Pixel Ratio:     ${pixelRatio.toStringAsFixed(2)}x');
      debugPrint(
        'Aspect Ratio:    ${(wallpaperHeight / wallpaperWidth).toStringAsFixed(3)} : 1',
      );
      debugPrint('═══════════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Failed to detect device dimensions: $e');
      debugPrint('📱 Using fallback: $fallbackWidth × $fallbackHeight');
      wallpaperWidth = fallbackWidth;
      wallpaperHeight = fallbackHeight;
      _isInitialized = true;
    }
  }

  /// Check if device dimensions are initialized
  static bool get isInitialized => _isInitialized;

  /// Get aspect ratio (height/width)
  static double get aspectRatio => wallpaperHeight / wallpaperWidth;

  // ════════════════════════════════════════════════════════════════════════
  // ⏰ BACKGROUND TASKS
  // ════════════════════════════════════════════════════════════════════════

  static const String wallpaperTaskName = 'github-wallpaper-update';
  static const String wallpaperTaskTag = 'updateGitHubWallpaper';
  static const Duration updateInterval = Duration(hours: 24);
  static const Duration minimumInterval = Duration(minutes: 15);

  // ════════════════════════════════════════════════════════════════════════
  // 💾 STORAGE KEYS
  // ════════════════════════════════════════════════════════════════════════

  // User Data
  static const String keyUsername = 'github_username';
  static const String keyToken = 'github_token';
  static const String keyCachedData = 'cachedData';
  static const String keyLastUpdate = 'lastUpdate';

  // Appearance
  static const String keyDarkMode = 'isDarkMode';
  static const String keyVerticalPos = 'verticalPosition';
  static const String keyHorizontalPos = 'horizontalPosition';
  static const String keyScale = 'scale';

  // Customization
  static const String keyCustomQuote = 'customQuote';
  static const String keyOpacity = 'opacity';
  static const String keyCornerRadius = 'cornerRadius';
  static const String keyQuoteFontSize = 'quoteFontSize';
  static const String keyQuoteOpacity = 'quoteOpacity';
  static const String keyPaddingTop = 'paddingTop';
  static const String keyPaddingBottom = 'paddingBottom';
  static const String keyPaddingLeft = 'paddingLeft';
  static const String keyPaddingRight = 'paddingRight';

  // Preferences
  static const String keyWallpaperTarget = 'wallpaperTarget';
  static const String keyAutoUpdate = 'autoUpdate';
}
