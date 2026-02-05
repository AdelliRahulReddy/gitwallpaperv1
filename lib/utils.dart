// ══════════════════════════════════════════════════════════════════════════
// 🛠️ UTILITIES - Production-Ready Helpers
// ══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';


import 'exceptions.dart';
import 'theme.dart';

// ══════════════════════════════════════════════════════════════════════════
// ERROR HANDLER
// ══════════════════════════════════════════════════════════════════════════

/// Centralized error handling with user-friendly messages
class ErrorHandler {
  /// Show error to user and optionally log it
  static void handle(
    BuildContext context,
    dynamic error, {
    String? userMessage,
    bool showSnackBar = true,
    VoidCallback? onRetry,
  }) {
    final message = userMessage ?? getUserFriendlyMessage(error);

    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: AppTheme.textWhite,
                  onPressed: onRetry,
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    Text(message),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog.
  static void hideLoading(BuildContext context) {
    if (context.mounted) {
      // Use canPop check to avoid popping the wrong thing if the dialog isn't there
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  /// Convert error to user-friendly message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is NetworkException || error is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    if (error is TokenExpiredException) {
      return 'Invalid or expired GitHub token.';
    }

    if (error is AccessDeniedException) {
      return 'Access denied. Check your token permissions.';
    }

    if (error is UserNotFoundException) {
      return 'GitHub user not found. Check the username.';
    }

    if (error is RateLimitException) {
      return 'GitHub API rate limit exceeded. Try again later.';
    }

    if (error is StorageException) {
      return 'Failed to save settings. Please restart the app.';
    }

    if (error is WallpaperException) {
      return 'Failed to set wallpaper. Check app permissions.';
    }

    final errorStr = error.toString().toLowerCase();

    // Fallback string matching for untyped errors
    if (errorStr.contains('socket') || errorStr.contains('network')) {
      return 'No internet connection. Please check your network.';
    }

    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorStr.contains('401')) {
      return 'Invalid GitHub token. Please check your credentials.';
    }

    if (errorStr.contains('403')) {
      return 'Access denied. Check your token permissions.';
    }

    // Audit Fix: Handle ContextInitException
    if (error is ContextInitException) {
      return 'App initialization failed. Please restart.';
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// VALIDATION UTILITIES
// ══════════════════════════════════════════════════════════════════════════

/// Input validation utilities
class ValidationUtils {
  /// Validate GitHub username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final trimmed = value.trim();

    // Length check
    if (trimmed.length > 39) {
      return 'Username too long (max 39 characters)';
    }

    // Format check
    if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$')
        .hasMatch(trimmed)) {
      return 'Invalid username format';
    }

    // No consecutive hyphens
    if (trimmed.contains('--')) {
      return 'Username cannot have consecutive hyphens';
    }

    // Reserved names
    const reserved = ['admin', 'api', 'www', 'github', 'support'];
    if (reserved.contains(trimmed.toLowerCase())) {
      return 'Username is reserved';
    }

    return null;
  }

  /// Validate GitHub token
  static String? validateToken(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Token is required';
    }

    final t = value.trim();
    final isValid = t.length >= 10 && !t.contains(' ');
    
    if (!isValid) {
      return 'Invalid token format (use ghp_, github_pat_, or OAuth token)';
    }

    return null;
  }

  /// Validate custom quote
  static String? validateQuote(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    final trimmed = value.trim();

    // Max length
    if (trimmed.length > 200) {
      return 'Quote too long (max 200 characters)';
    }

    // Sanitize HTML/scripts
    if (RegExp(r'<script|<iframe|javascript:', caseSensitive: false)
        .hasMatch(trimmed)) {
      return 'Invalid characters detected';
    }

    return null;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 📅 DATE UTILS
// ══════════════════════════════════════════════════════════════════════════

/// Utilities for date handling and manipulation
class AppDateUtils {
  AppDateUtils._(); // Private constructor

  /// Get current date/time in UTC
  static DateTime get nowUtc => DateTime.now().toUtc();

  /// Get current date/time in local timezone
  static DateTime get nowLocal => DateTime.now();

  /// Convert DateTime to date-only (strips time component)
  static DateTime toDateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Format date as ISO date string (YYYY-MM-DD)
  static String toIsoDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Create date key for map lookups (YYYY-MM-DD format)
  static String createDateKey(DateTime date) {
    // Audit Fix: Direct alias to avoid logic duplication
    return toIsoDateString(date);
  }

  static int _parseFailures = 0;

  /// Parse ISO date string to DateTime (date-only)
  static DateTime? parseIsoDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final parsed = DateTime.parse(dateStr);
      return toDateOnly(parsed);
    } catch (e) {
      _parseFailures++;
      // Audit Fix: Track failure rate (simple counter for now)
      if (_parseFailures % 10 == 0) {
        debugPrint('⚠️ High Date Parse Failure Rate: $_parseFailures failures. Last error: $e');
      }
      return null;
    }
  }

  /// Check if two dates are the same day (ignoring time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isLeapYear(int year) {
    if (year <= 0) {
      throw ArgumentError.value(year, 'year', 'Year must be positive');
    }
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    return year % 4 == 0;
  }

  static int daysInMonth(int year, int month) {
    if (year <= 0) {
      throw ArgumentError.value(year, 'year', 'Year must be positive');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'Month must be 1-12');
    }
    if (month == 2) return isLeapYear(year) ? 29 : 28;
    if (month == 4 || month == 6 || month == 9 || month == 11) return 30;
    return 31;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// APP STRINGS (i18n Preparation)
// ══════════════════════════════════════════════════════════════════════════

/// Centralized app strings for easy localization
class AppStrings {
  // App Info
  static const appName = 'GitHub Wallpaper';
  static const appTagline = 'Your Code Journey, Visualized';

  // Onboarding
  static const onboardingTitle1 = 'Beautiful Contributions';
  static const onboardingDesc1 =
      'Turn your GitHub contribution graph into aesthetic wallpapers for your Home and Lock screen.';
  static const onboardingTitle2 = 'Always Updated';
  static const onboardingDesc2 =
      'Your wallpaper updates automatically in the background. Keep your coding streak visible!';
  static const onboardingTitle3 = 'Built by Developer';
  static const connectGitHub = 'Connect GitHub';
  static const connectAccount = 'Connect Account';
  static const backToIntro = 'Back to Introduction';

  // Labels
  static const username = 'GitHub Username';
  static const token = 'Personal Access Token';
  static const needToken = 'Need a token? ';
  static const createHere = 'Create one here →';

  // Buttons
  static const skip = 'Skip';
  static const next = 'Next';
  static const getStarted = 'Get Started';
  static const apply = 'Apply';
  static const cancel = 'Cancel';
  static const retry = 'Retry';
  static const save = 'Save';
  static const logout = 'Logout';
  static const clearCache = 'Clear Cache';

  // Messages
  static const settingUpWorkspace = 'Setting up your workspace...';
  static const generatingWallpaper = 'Generating wallpaper...';
  static const applyingWallpaper = 'Applying wallpaper...';
  static const refreshingData = 'Refreshing data...';

  // Success
  static const wallpaperApplied = 'Wallpaper applied successfully!';
  static const settingsSaved = 'Settings saved';
  static const cacheCleared = 'Cache cleared successfully';

  // Errors
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'No internet connection';
  static const errorInvalidToken = 'Invalid GitHub token';
  static const errorUserNotFound = 'GitHub user not found';
  static const errorRateLimit = 'API rate limit exceeded';
  static const errorStorageInit =
      'Failed to initialize local storage.\nPlease restart the app.';
  static const errorAppInit = 'Initialization Error';
  static const errorContextInit = 'Context-dependent initialization failed';

  static const supportEmail = 'support@rahulreddy.dev';
  static const supportPhone = '+91 7032784208';
  static const supportFeedback = 'SUPPORT & FEEDBACK';

  // About
  static const developer = 'DEVELOPED BY';
  static const developerName = 'Adelli Rahulreddy';
  static const developerTagline = 'Building tools for developers';
  static const appVersion = '1.0.1';
}

// ══════════════════════════════════════════════════════════════════════════
// ⚙️ APP CONSTANTS - Configuration Values
// ══════════════════════════════════════════════════════════════════════════

/// Application-wide configuration constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ════════════════════════════════════════════════════════════════════════
  // WALLPAPER DEFAULTS
  // ════════════════════════════════════════════════════════════════════════

  static const double defaultWallpaperScale = 0.7;
  static const double defaultWallpaperOpacity = 1.0;
  static const double defaultCornerRadius = 2.0;

  // ════════════════════════════════════════════════════════════════════════
  // HEATMAP RENDERING
  // ════════════════════════════════════════════════════════════════════════

  static const double heatmapBoxSize = 15.0;
  static const double heatmapBoxSpacing = 3.0;
  static const int heatmapWeeks = 53;
  static const int heatmapDaysPerWeek = 7;

  /// Total days displayed in heatmap grid
  static const int heatmapTotalDays = heatmapWeeks * heatmapDaysPerWeek; // 371

  static const int intensity1 = 3;
  static const int intensity2 = 6;
  static const int intensity3 = 9;

  static const int monthGridColumns = 7;

  // ════════════════════════════════════════════════════════════════════════
  // API & CACHE
  // ════════════════════════════════════════════════════════════════════════

  /// Days of contribution data to fetch from GitHub (1 year + buffer)
  static const int githubDataFetchDays = 370;

  /// API request timeout
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Cache expiry duration
  static const Duration cacheExpiry = Duration(hours: 6);

  // ════════════════════════════════════════════════════════════════════════
  // STORAGE KEYS
  // ════════════════════════════════════════════════════════════════════════

  static const String keyToken = 'gh_token';
  static const String keyUsername = 'username';
  static const String keyCachedData = 'cached_data_v2';
  static const String keyWallpaperConfig = 'wp_config_v2';
  static const String keyLastUpdate = 'last_update';
  static const String keyAutoUpdate = 'auto_update';
  static const String keyOnboarding = 'onboarding';
  static const String keyDimensionWidth = 'dim_w';
  static const String keyDimensionHeight = 'dim_h';
  static const String keyDimensionPixelRatio = 'dim_pr';
  static const String keyDeviceModel = 'device_model';
  static const String keySafeInsetTop = 'safe_top';
  static const String keySafeInsetBottom = 'safe_bottom';
  static const String keySafeInsetLeft = 'safe_left';
  static const String keySafeInsetRight = 'safe_right';
  static const String keyWallpaperHash = 'wp_hash';
  static const String keyWallpaperPath = 'wp_path';

  // ════════════════════════════════════════════════════════════════════════
  // UI DIMENSIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Default wallpaper dimensions (1080p portrait)
  static const double defaultWallpaperWidth = 1080.0;
  static const double defaultWallpaperHeight = 1920.0;
  static const double defaultPixelRatio = 1.0;

  // ════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ════════════════════════════════════════════════════════════════════════

  /// Validate contribution level is within valid range
  static bool isValidContributionLevel(int level) => level >= 0 && level <= 4;

  // ════════════════════════════════════════════════════════════════════════
  // FIREBASE
  // ════════════════════════════════════════════════════════════════════════

  static const String fcmTopicDailyUpdates = 'daily-updates';

  static const List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const String fallbackWeekday = 'None';

  // ════════════════════════════════════════════════════════════════════════
  // API & CONNECTIVITY
  // ════════════════════════════════════════════════════════════════════════
  static const String apiUrl = 'https://api.github.com/graphql';
  static const int refreshCooldownMinutes = 15;
  static const List<String> connectivityHosts = ['api.github.com', 'one.one.one.one'];

  // ════════════════════════════════════════════════════════════════════════
  // VALIDATION & LIMITS
  // ════════════════════════════════════════════════════════════════════════
  static const int usernameMaxLength = 39;
  static const int quoteMaxLength = 200;

  // ════════════════════════════════════════════════════════════════════════
  // UI LAYOUT BUFFERS
  // ════════════════════════════════════════════════════════════════════════
  static const double clockAreaBuffer = 120.0;
  static const double horizontalBuffer = 32.0;
}

// ══════════════════════════════════════════════════════════════════════════
// 🎨 RENDER UTILS
// ══════════════════════════════════════════════════════════════════════════

class RenderUtils {
  static final Map<String, ui.Radius> _radiusCache = {};
  static const int _maxCacheSize = 50;

  /// Render header text for a date
  static String headerTextForDate(DateTime date) {
    const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];
    return "${months[date.month - 1]} ${date.year}";
  }

  /// Shared text drawing helper
  static TextPainter drawText({
    required ui.Canvas canvas,
    required String text,
    required TextStyle style,
    required Offset offset,
    required double maxWidth,
    TextAlign textAlign = TextAlign.left,
    int? maxLines,
    bool paint = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);

    if (paint) {
      double dx = offset.dx;
      if (textAlign == TextAlign.center) {
        dx += (maxWidth - painter.width) / 2;
      } else if (textAlign == TextAlign.right) {
        dx += maxWidth - painter.width;
      }
      painter.paint(canvas, Offset(dx, offset.dy));
    }
    return painter;
  }

  /// Calculate contribution quartiles for dynamic intensity
  static Quartiles calculateQuartiles(List<int> counts) {
    // Filter non-zero contributions
    final nonZero = counts.where((c) => c > 0).toList()..sort();
    
    if (nonZero.isEmpty) {
      return Quartiles(1, 2, 3); // Fallback defaults
    }

    // Calculate percentiles
    int getPercentile(double p) {
      final index = (nonZero.length * p).ceil() - 1;
      return nonZero[index.clamp(0, nonZero.length - 1)];
    }

    final q1 = getPercentile(0.25);
    final q2 = getPercentile(0.50);
    final q3 = getPercentile(0.75);

    // Ensure strict ascending order to avoid level overlap
    final t1 = q1 > 0 ? q1 : 1;
    final t2 = q2 > t1 ? q2 : t1 + 1;
    final t3 = q3 > t2 ? q3 : t2 + 1;

    return Quartiles(t1, t2, t3);
  }

  /// Get contribution level (0-4) using dynamic thresholds
  static int getContributionLevel(int count, {Quartiles? quartiles}) {
    if (count == 0) return 0;
    
    // If no quartiles provided, use fallback defaults (3/6/9)
    // This maintains backward compatibility if caller doesn't have quartiles
    final q = quartiles ?? Quartiles(AppConstants.intensity1, AppConstants.intensity2, AppConstants.intensity3);
    
    if (count <= q.q1) return 1;
    if (count <= q.q2) return 2;
    if (count <= q.q3) return 3;
    return 4;
  }
  /// Safe radius cache access
  static ui.Radius getCachedRadius(double radius, double scale) {
    final key = '${radius}_$scale';
    if (_radiusCache.length >= _maxCacheSize && !_radiusCache.containsKey(key)) {
      _radiusCache.remove(_radiusCache.keys.first);
    }
    return _radiusCache.putIfAbsent(key, () => Radius.circular(radius * scale));
  }

  static void clearCaches() => _radiusCache.clear();
}

/// Dynamic intensity thresholds
class Quartiles {
  final int q1;
  final int q2;
  final int q3;

  const Quartiles(this.q1, this.q2, this.q3);
  
  @override
  String toString() => 'Q($q1, $q2, $q3)';
}
