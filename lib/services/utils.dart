// ══════════════════════════════════════════════════════════════════════════
// 🛠️ UTILITIES - Constants, Date Helpers, Connectivity
// ══════════════════════════════════════════════════════════════════════════
// Single source of truth for app configuration and helper functions
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Added for Debouncer

// ══════════════════════════════════════════════════════════════════════════
// 1. APP CONFIGURATION - All constants and settings
// Also contains AppStrings and AppLayout
// ══════════════════════════════════════════════════════════════════════════

class AppStrings {
  // General
  static const String appName = 'GitHub Wallpaper';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String tryAgain = 'Try Again';

  // Customize Page
  static const String customizeTitle = 'Visual Designer';
  static const String sectionScaling = 'Scaling & Effects';
  static const String sectionOverlay = 'Custom Overlay';
  static const String noDataTitle = 'No Data Yet';
  static const String noDataMsg = 'Sync your GitHub contributions to get started.';
  static const String startSync = 'Start Sync';
  static const String applyWallpaper = 'Apply Wallpaper';
  static const String applying = 'Applying...';
  static const String wallpaperApplied = 'Wallpaper applied! 🎉';
  static const String goBack = 'Go Back';
  static const String resetDefaults = 'Settings reset to defaults';
  static const String labelScale = 'Scale';
  static const String labelOpacity = 'Opacity';
  static const String labelFontSize = 'Font Size';
  static const String labelPadding = 'Padding';
  static const String labelCornerRadius = 'Corner Radius';
  static const String customQuote = 'Custom Quote';
  static const String quoteHint = 'Keep coding...';
  static const String darkMode = 'Dark Mode Preview';
  
  // Stats Page
  static const String statsTitle = 'Detailed Analytics';
  static const String analyzing = 'Analyzing your contributions...';
  static const String noDataStats = 'Sync your contributions to view detailed analytics.';
  static const String keyMetrics = 'Key Performance Metrics';
  static const String contributionCalendar = 'Contribution Calendar';
  static const String weeklyActivity = 'Weekly Activity Breakdown';
  static const String contributionDensity = 'Contribution Density';
  static const String historyMsg = 'Visual history of your contributions over the past month.';
  static const String total = 'TOTAL';
  static const String active = 'ACTIVE';
  static const String avgDay = 'AVG/DAY';
  static const String avgCommits = 'Average Commits';
  static const String activeRatio = 'Active Ratio';
  static const String refresh = 'Refresh';
  static const String statsUpdated = 'Stats updated! ✅';
  static const String levelQuiet = 'Quiet Days';
  static const String levelLow = 'Low Activity';
  static const String levelBalanced = 'Balanced';
  static const String levelHigh = 'High Output';
  static const String levelPeak = 'Peak Coding';

  
  // Setup Page
  static const String setupTitle = 'Setup GitHub';
  static const String setupHelpTitle = 'Getting Your GitHub Token';
  static const String setupHelp1 = '1. Go to GitHub Settings';
  static const String setupHelp2 = '2. Developer Settings → Personal Access Tokens → Tokens (classic)';
  static const String setupHelp3 = '3. Generate new token (classic)';
  static const String setupHelp4 = '4. Select "read:user" scope';
  static const String setupHelp5 = '5. Copy the generated token';
  static const String setupImportant = '⚠️ Important: Save your token somewhere safe. GitHub only shows it once!';
  static const String openGithub = 'Open GitHub Settings';
  static const String githubTokenUrl = 'https://github.com/settings/tokens/new';
  static const String gotIt = 'Got it';
  static const String connectedSuccess = 'Connected successfully! 🎉';
  
  static const String connectGithub = 'Connect Your GitHub';
  static const String enterCredentials = 'Enter your GitHub username and personal access token to get started.';
  static const String usernameLabel = 'GitHub Username';
  static const String usernameHint = 'octocat';
  static const String usernameRequired = 'Username is required';
  static const String usernameLength = 'Username must be at least 2 characters';
  static const String tokenLabel = 'Personal Access Token';
  static const String tokenHint = 'ghp_xxxxxxxxxxxxxxxxxxxx';
  static const String tokenRequired = 'Token is required';
  static const String tokenInvalid = 'Invalid token format (should start with ghp_ or github_pat_)';
  static const String needToken = 'Need a token? Tap the help icon above.';
  static const String connectBtn = 'Connect & Continue';
  static const String secureStorage = 'Secure Storage';
  static const String secureStorageMsg = 'Your token is encrypted and stored securely using Android Keystore.';

  // Home Page
  static const String dashboard = 'Dashboard';
  static const String lastUpdated = 'Last updated:';
  static const String syncSuccess = 'Data synced successfully! ✅';
  static const String syncFailed = 'Sync failed:';
  static const String credentialsMissing = 'Credentials not found. Please set up again.';
  static const String loadingContributions = 'Loading your contributions...';

  static const String syncNow = 'Sync Now';
  static const String keepStreakAlive = 'Keep the coding streak alive.';
  static const String dashboardOverview = 'Dashboard Overview';
  static const String activityHeatmap = 'Activity Heatmap';
  static const String exploreConfigure = 'Explore & Configure';
  static const String fullStats = 'FULL STATS';
  static const String visualDesigner = 'Visual Designer';
  static const String visualDesignerSub = 'Customize colors, scale & position';
  static const String performanceInsight = 'Performance Insight';
  static const String performanceInsightSub = 'Deep dive into your coding habits';
  static const String systemSettings = 'System Settings';
  static const String systemSettingsSub = 'Account & sync preferences';
  static const String setWallpaper = 'Set Wallpaper';
  static const String totalCode = 'Total Code';
  static const String currentStreak = 'Current Streak';
  static const String longestStreak = 'Longest Streak';
  static const String today = 'Today';
  
  // Settings Page
  static const String settingsTitle = 'Settings';
  static const String sectionAccount = 'Account';
  static const String sectionPreferences = 'Preferences';
  static const String sectionData = 'Data Management';
  static const String sectionHelp = 'Help & Support';
  static const String sectionAbout = 'About';
  
  static const String labelUsername = 'Username';
  static const String labelUpdateToken = 'Update Token';
  static const String subUpdateToken = 'Change your GitHub personal access token';
  static const String labelLogout = 'Logout';
  static const String subLogout = 'Clear all data and logout';
  
  static const String labelAutoUpdate = 'Auto-Update';
  static const String subAutoUpdate = 'Automatically sync contributions daily';
  static const String autoUpdateEnabled = 'Auto-update enabled';
  static const String autoUpdateDisabled = 'Auto-update disabled';

  static const String labelCacheStatus = 'Cache Status';
  static const String noCachedData = 'No cached data';
  static const String labelClearCache = 'Clear Cache';
  static const String subClearCache = 'Remove cached contribution data';
  static const String labelClearAll = 'Clear All Data';
  static const String subClearAll = 'Reset app to initial state';
  static const String cacheCleared = 'Cache cleared successfully';
  
  static const String dialogLogoutTitle = 'Logout';
  static const String dialogLogoutMsg = 'Are you sure you want to logout? This will clear all your data including cached contributions.';
  static const String dialogClearCacheTitle = 'Clear Cache';
  static const String dialogClearCacheMsg = 'This will remove cached contribution data. Your settings and credentials will be preserved.';
  static const String dialogClearAllTitle = 'Clear All Data';
  static const String dialogClearAllMsg = '⚠️ This will delete ALL app data including your credentials, settings, and cache. You will need to set up the app again.';
  static const String actionCancel = 'Cancel';
  static const String actionDeleteAll = 'Delete All';
  
  static const String labelDocs = 'Documentation';
  static const String subDocs = 'Learn how to use the app';
  static const String labelBug = 'Report Bug';
  static const String subBug = 'Found an issue? Let us know';
  static const String labelRate = 'Rate on Play Store';
  static const String subRate = 'Support us with a review';
  static const String msgComingSoon = 'Coming soon on Play Store!';
  
  static const String labelSource = 'View Source Code';
  static const String subSource = 'This app is open source';
  static const String labelDev = 'Developer';
  static const String subDev = 'Made with ❤️ by Rahul Reddy';
  static const String labelLicense = 'License';
  static const String subLicense = 'MIT License';
  static const String urlDocs = 'https://github.com/Start-sys-cmd/github_wallpaper#readme';
  static const String urlBug = 'https://github.com/Start-sys-cmd/github_wallpaper/issues';
  static const String urlRepo = 'https://github.com/Start-sys-cmd/github_wallpaper';
  static const String urlProfile = 'https://github.com/Start-sys-cmd';
  static const String urlLicense = 'https://github.com/Start-sys-cmd/github_wallpaper/blob/main/LICENSE';
  
  // Widgets
  static const String legendLess = 'Less';
  static const String legendMore = 'More';
  static const String errorDefault = 'Something went wrong';
  static const String errorAuth = 'Authentication failed';

  // Onboarding
  static const String onboardingSkip = 'Skip';
  static const String onboardingNext = 'Next';
  static const String onboardingStart = 'Get Started';
  
  static const String onboardingTitle1 = 'GitHub Contributions';
  static const String onboardingDesc1 = 'Transform your GitHub contribution graph into a beautiful, live wallpaper that updates automatically.';
  
  static const String onboardingTitle2 = 'Auto-Updating Wallpaper';
  static const String onboardingDesc2 = 'Your wallpaper updates daily with your latest contributions. Stay motivated to code every day!';
  
  static const String onboardingTitle3 = 'Fully Customizable';
  static const String onboardingDesc3 = 'Choose light or dark theme, adjust positioning, add custom quotes, and make it truly yours.';
}

class AppLayout {
  // Dimensions
  static const double previewHeightRatio = 0.48;
  static const double frameHeightRatio = 0.92;
  static const double phoneAspectRatio = 9 / 19.5;
  static const double frameBorderWidth = 6.0;
  static const double frameRadius = 28.0;
  
  // UI Sizing
  static const double buttonHeight = 56.0;
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  
  // Animations
  static const Duration animShort = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animLong = Duration(milliseconds: 400);
}

class AppConfig {
  // ════════════════════════════════════════════════════════════════════════
  // API SETTINGS
  // ════════════════════════════════════════════════════════════════════════

  static const String githubApiUrl = 'https://api.github.com/graphql';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const String userAgent = 'GitHubWallpaper/1.0';

  // ════════════════════════════════════════════════════════════════════════
  // HEATMAP COLORS
  // ════════════════════════════════════════════════════════════════════════

  // Dark Mode Colors
  static const Color heatmapDarkBg = Color(0xFF0D1117);
  static const Color heatmapDarkBox = Color(0xFF161B22);
  static const Color heatmapDarkLevel1 = Color(0xFF0E4429);
  static const Color heatmapDarkLevel2 = Color(0xFF006D32);
  static const Color heatmapDarkLevel3 = Color(0xFF26A641);
  static const Color heatmapDarkLevel4 = Color(0xFF39D353);

  // Light Mode Colors
  static const Color heatmapLightBg = Color(0xFFFFFFFF);
  static const Color heatmapLightBox = Color(0xFFEBEDF0);
  static const Color heatmapLightLevel1 = Color(0xFF9BE9A8);
  static const Color heatmapLightLevel2 = Color(0xFF40C463);
  static const Color heatmapLightLevel3 = Color(0xFF30A14E);
  static const Color heatmapLightLevel4 = Color(0xFF216E39);

  // Highlights
  static const Color todayHighlight = Color(0xFFFF9500);

  // ════════════════════════════════════════════════════════════════════════
  // HEATMAP LAYOUT
  // ════════════════════════════════════════════════════════════════════════

  static const double boxSize = 15.0;
  static const double boxSpacing = 3.0;
  static const double boxRadius = 2.0;
  static const double todayBorderWidth = 2.0;

  // ════════════════════════════════════════════════════════════════════════
  // WALLPAPER SETTINGS
  // ════════════════════════════════════════════════════════════════════════

  // Default positioning
  static const double defaultVerticalPosition = 0.45;
  static const double defaultHorizontalPosition = 0.5;
  static const double defaultScale = 3.5;

  // Limits
  static const double minVerticalPos = 0.0;
  static const double maxVerticalPos = 1.0;
  static const double minScale = 0.5;
  static const double maxScale = 5.0;

  // Resolution - Auto-detected at runtime
  static late double wallpaperWidth;
  static late double wallpaperHeight;
  static double? _devicePixelRatio;
  
  /// Get device pixel ratio with safe fallback
  static double get devicePixelRatio => _devicePixelRatio ?? 3.0;

  // Fallback if detection fails
  static const double fallbackWidth = 1080.0;
  static const double fallbackHeight = 2340.0;

  // Track initialization status
  static bool _isInitialized = false;

  /// Initialize wallpaper dimensions from device
  /// Call this ONCE when app starts (in main.dart)
  static void initializeFromContext(BuildContext context) {
    if (_isInitialized) {
      if (kDebugMode) debugPrint('⚠️ AppConfig already initialized');
      return;
    }

    try {
      final size = MediaQuery.of(context).size;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;

      // Calculate physical pixels
      wallpaperWidth = size.width * pixelRatio;
      wallpaperHeight = size.height * pixelRatio;
      _devicePixelRatio = pixelRatio;

      _isInitialized = true;

      if (kDebugMode) {
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
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to detect device: $e');
        debugPrint('📱 Using fallback: $fallbackWidth × $fallbackHeight');
      }
      wallpaperWidth = fallbackWidth;
      wallpaperHeight = fallbackHeight;
      _devicePixelRatio = 3.0; // Reasonable default
      _isInitialized = true;
    }
  }

  /// Check if initialized
  static bool get isInitialized => _isInitialized;

  /// Get aspect ratio (height/width)
  static double get aspectRatio => wallpaperHeight / wallpaperWidth;

  // ════════════════════════════════════════════════════════════════════════
  // BACKGROUND TASKS
  // ════════════════════════════════════════════════════════════════════════

  static const String keyWallpaperConfig = 'wallpaper_config';
  static const String wallpaperTaskName = 'github-wallpaper-update';
  static const String wallpaperTaskTag = 'updateGitHubWallpaper';
  static const Duration updateInterval = Duration(hours: 24);
  static const Duration minimumInterval = Duration(minutes: 15);

  // ════════════════════════════════════════════════════════════════════════
  // CACHE & REFRESH SETTINGS
  // ════════════════════════════════════════════════════════════════════════

  static const Duration cacheValidDuration = Duration(hours: 6);
  static const Duration autoRefreshThreshold = Duration(hours: 6);

  // ════════════════════════════════════════════════════════════════════════
  // STORAGE KEYS
  // ════════════════════════════════════════════════════════════════════════

  // User Data
  static const String keyUsername = 'github_username';
  static const String keyToken = 'github_token_secure';
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
  static const String keyOnboardingComplete = 'onboardingComplete';
}

// ══════════════════════════════════════════════════════════════════════════
// 2. DATE HELPER - All date/time operations
// ══════════════════════════════════════════════════════════════════════════

class DateHelper {
  // ════════════════════════════════════════════════════════════════════════
  // CURRENT DATE/TIME
  // ════════════════════════════════════════════════════════════════════════

  /// Returns current month name (e.g., "January")
  static String getCurrentMonthName() {
    return DateFormat('MMMM').format(DateTime.now());
  }

  /// Returns current day of month (1-31)
  static int getCurrentDayOfMonth() {
    return DateTime.now().day;
  }

  /// Returns number of days in current month (28-31)
  static int getDaysInCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  /// Returns weekday of first day of month (1=Mon, 7=Sun)
  static int getFirstWeekdayOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1).weekday;
  }

  // ════════════════════════════════════════════════════════════════════════
  // FORMATTING
  // ════════════════════════════════════════════════════════════════════════

  /// Formats to relative time ("5m ago", "2h ago", "Just now")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Returns day name ("Monday")
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Returns short day name ("Mon")
  static String getShortDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Formats as "2026-01-25"
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formats as "Jan 25, 2026"
  static String formatDateLong(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Formats as "Jan 25, 2026 at 11:15 AM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
  }

  // ════════════════════════════════════════════════════════════════════════
  // PARSING
  // ════════════════════════════════════════════════════════════════════════

  /// Parses date string safely (returns null on error)
  static DateTime? parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      if (kDebugMode) debugPrint('DateHelper: Parse error "$dateString": $e');
      return null;
    }
  }

  /// Parses date with fallback
  static DateTime parseDateOr(String dateString, DateTime fallback) {
    return parseDate(dateString) ?? fallback;
  }

  // ════════════════════════════════════════════════════════════════════════
  // BOUNDARIES
  // ════════════════════════════════════════════════════════════════════════

  /// Returns first day of current month (Jan 1 00:00:00)
  static DateTime getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Returns last day of current month (Jan 31 23:59:59)
  static DateTime getEndOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  /// Returns start of today (00:00:00)
  static DateTime getStartOfDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }

  /// Returns end of today (23:59:59)
  static DateTime getEndOfDay([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  // ════════════════════════════════════════════════════════════════════════
  // COMPARISONS
  // ════════════════════════════════════════════════════════════════════════

  /// Checks if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Checks if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Checks if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ════════════════════════════════════════════════════════════════════════
  // CALCULATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Returns days between two dates (ignoring time)
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays;
  }

  /// Adds days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtracts days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Adds months to date
  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }

  /// Subtracts months from date
  static DateTime subtractMonths(DateTime date, int months) {
    return DateTime(date.year, date.month - months, date.day);
  }

  // ════════════════════════════════════════════════════════════════════════
  // GITHUB-SPECIFIC
  // ════════════════════════════════════════════════════════════════════════

  /// Returns date 365 days ago (for fetching full year)
  static DateTime getOneYearAgo() {
    return DateTime.now().subtract(const Duration(days: 365));
  }

  /// Returns list of all dates in current month
  static List<DateTime> getDatesInCurrentMonth() {
    final now = DateTime.now();
    final daysInMonth = getDaysInCurrentMonth();

    return List.generate(
      daysInMonth,
      (i) => DateTime(now.year, now.month, i + 1),
    );
  }

  /// Returns week number of year (1-53)
  static int getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// 3. CONNECTIVITY HELPER - Network status checking
// ══════════════════════════════════════════════════════════════════════════

class ConnectivityHelper {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  static Future<bool> hasConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();

      // Check if connected to any network
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      if (kDebugMode) debugPrint('ConnectivityHelper: Check failed: $e');
      return false;
    }
  }

  /// Get current connection type as string
  static Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result.contains(ConnectivityResult.wifi)) return 'WiFi';
      if (result.contains(ConnectivityResult.mobile)) return 'Mobile Data';
      if (result.contains(ConnectivityResult.ethernet)) return 'Ethernet';
      return 'None';
    } catch (e) {
      if (kDebugMode) debugPrint('ConnectivityHelper: Type check failed: $e');
      return 'Unknown';
    }
  }

  /// Stream of connectivity changes
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// Check connection with user-friendly error message
  static Future<String?> checkConnectionWithMessage() async {
    final hasConn = await hasConnection();
    if (!hasConn) {
      return 'No internet connection. Please check your WiFi or mobile data.';
    }
    return null; // No error
  }
}

/// Helper to debounce actions
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
