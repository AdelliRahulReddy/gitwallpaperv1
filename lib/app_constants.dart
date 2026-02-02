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
  static const String keyDesiredWallpaperWidth = 'wp_desired_w';
  static const String keyDesiredWallpaperHeight = 'wp_desired_h';

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

  /// Minimum valid contribution level
  static const int minContributionLevel = 0;

  /// Maximum valid contribution level
  static const int maxContributionLevel = 4;

  /// Validate contribution level is within valid range
  static bool isValidContributionLevel(int level) {
    return level >= minContributionLevel && level <= maxContributionLevel;
  }

  // ════════════════════════════════════════════════════════════════════════
  // FIREBASE
  // ════════════════════════════════════════════════════════════════════════

  static const String fcmTopicDailyUpdates = 'daily-updates';
}
