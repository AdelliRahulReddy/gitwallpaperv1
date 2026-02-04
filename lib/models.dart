// ══════════════════════════════════════════════════════════════════════════
// 📊 DATA MODELS - Production Ready
// ══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'app_constants.dart';

// ══════════════════════════════════════════════════════════════════════════
// DATE UTILITIES
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
    return toIsoDateString(date);
  }

  /// Parse ISO date string to DateTime (date-only)
  static DateTime? parseIsoDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final parsed = DateTime.parse(dateStr);
      return toDateOnly(parsed);
    } catch (e) {
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
// CONTRIBUTION DAY
// ══════════════════════════════════════════════════════════════════════════

/// Represents a single day of GitHub contributions
@immutable
class ContributionDay {
  /// The date of this contribution day (time component stripped)
  final DateTime date;

  /// Number of contributions made on this day
  final int contributionCount;

  /// GitHub's contribution level string (NONE, FIRST_QUARTILE, etc.)
  final String? contributionLevel;

  const ContributionDay({
    required this.date,
    required this.contributionCount,
    this.contributionLevel,
  });

  /// Create from GitHub API JSON response
  factory ContributionDay.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final parsedDate = AppDateUtils.parseIsoDate(dateStr);

    if (parsedDate == null) {
      // Return empty day instead of corrupting data with wrong date
      throw FormatException('Invalid date in ContributionDay JSON: $dateStr');
    }

    final count = json['contributionCount'];
    final validCount = (count is int && count >= 0) ? count : 0;

    return ContributionDay(
      date: parsedDate,
      contributionCount: validCount,
      contributionLevel: json['contributionLevel'] as String?,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'date': AppDateUtils.toIsoDateString(date),
        'contributionCount': contributionCount,
        'contributionLevel': contributionLevel,
      };

  /// Whether this day has any contributions
  bool get isActive => contributionCount > 0;

  /// Get visual intensity level (0-4) for heatmap rendering
  ///
  /// Uses fixed thresholds for consistency:
  /// - 0: No contributions
  /// - 1: 1-3 contributions
  /// - 2: 4-6 contributions
  /// - 3: 7-9 contributions
  /// - 4: 10+ contributions
  int get intensityLevel {
    if (contributionCount == 0) return 0;
    if (contributionCount <= 3) return 1;
    if (contributionCount <= 6) return 2;
    if (contributionCount <= 9) return 3;
    return 4;
  }

  /// Get date key for map lookups (YYYY-MM-DD format)
  String get dateKey => AppDateUtils.createDateKey(date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContributionDay &&
          runtimeType == other.runtimeType &&
          AppDateUtils.isSameDay(date, other.date) &&
          contributionCount == other.contributionCount &&
          contributionLevel == other.contributionLevel;

  @override
  int get hashCode =>
      date.year.hashCode ^
      date.month.hashCode ^
      date.day.hashCode ^
      contributionCount.hashCode ^
      contributionLevel.hashCode;

  @override
  String toString() => '$dateKey: $contributionCount contributions';
}

// ══════════════════════════════════════════════════════════════════════════
// CONTRIBUTION STATISTICS
// ══════════════════════════════════════════════════════════════════════════

/// Statistics calculated from contribution data
@immutable
class ContributionStats {
  final int currentStreak;
  final int longestStreak;
  final int todayContributions;
  final int activeDaysCount;
  final int peakDayContributions;
  final int totalContributions;
  final String mostActiveWeekday;

  const ContributionStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.todayContributions,
    required this.activeDaysCount,
    required this.peakDayContributions,
    required this.totalContributions,
    required this.mostActiveWeekday,
  });

  /// Calculate statistics from contribution days
  factory ContributionStats.fromDays(List<ContributionDay> days) {
    if (days.isEmpty) {
      return const ContributionStats(
        currentStreak: 0,
        longestStreak: 0,
        todayContributions: 0,
        activeDaysCount: 0,
        peakDayContributions: 0,
        totalContributions: 0,
        mostActiveWeekday: 'None',
      );
    }

    final streaks = _calculateStreaks(days);
    final todayCount = _getTodayContributions(days);
    final activeCount = days.where((d) => d.isActive).length;
    final peak = days.fold(
        0,
        (max, day) =>
            day.contributionCount > max ? day.contributionCount : max);
    final total = days.fold<int>(0, (sum, d) => sum + d.contributionCount);
    final weekday = _getMostActiveWeekday(days);

    return ContributionStats(
      currentStreak: streaks['current']!,
      longestStreak: streaks['longest']!,
      todayContributions: todayCount,
      activeDaysCount: activeCount,
      peakDayContributions: peak,
      totalContributions: total,
      mostActiveWeekday: weekday,
    );
  }

  /// Calculate current and longest streaks from contribution days
  static Map<String, int> _calculateStreaks(List<ContributionDay> days) {
    if (days.isEmpty) return {'current': 0, 'longest': 0};

    // Sort by date descending (newest first)
    final sortedDays = List<ContributionDay>.from(days)
      ..sort((a, b) => b.date.compareTo(a.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final today = AppDateUtils.toDateOnly(AppDateUtils.nowLocal);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime? expectedDate = today;
    bool streakActive = true;

    for (final day in sortedDays) {
      final dayDate = AppDateUtils.toDateOnly(day.date);

      if (expectedDate != null && AppDateUtils.isSameDay(dayDate, expectedDate)) {
        if (day.isActive) {
          tempStreak++;
          if (streakActive) {
            currentStreak = tempStreak;
          }
          longestStreak =
              tempStreak > longestStreak ? tempStreak : longestStreak;
          expectedDate = dayDate.subtract(const Duration(days: 1));
        } else {
          // Break in streak
          if (streakActive && !AppDateUtils.isSameDay(dayDate, today)) {
            streakActive = false;
            currentStreak = 0;
          }
          tempStreak = 0;
          longestStreak =
              tempStreak > longestStreak ? tempStreak : longestStreak;
          expectedDate = dayDate.subtract(const Duration(days: 1));
        }
      } else if (expectedDate != null && dayDate.isBefore(expectedDate)) {
        // Date gap - streak broken
        if (streakActive) {
          streakActive = false;
          currentStreak = 0;
        }
        tempStreak = day.isActive ? 1 : 0;
        longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
        expectedDate = dayDate.subtract(const Duration(days: 1));
      }
    }

    // If today has no contributions, check if yesterday did (grace period)
    if (!streakActive && currentStreak == 0) {
      final yesterdayDay = sortedDays.firstWhere(
        (d) => AppDateUtils.isSameDay(d.date, yesterday),
        orElse: () => ContributionDay(date: yesterday, contributionCount: 0),
      );
      if (yesterdayDay.isActive) {
        // Streak is the consecutive days ending yesterday; tempStreak may be 0 here,
        // so count backwards from yesterday.
        int graceStreak = 0;
        DateTime? expect = yesterday;
        for (final day in sortedDays) {
          final dayDate = AppDateUtils.toDateOnly(day.date);
          if (expect != null && AppDateUtils.isSameDay(dayDate, expect)) {
            if (day.isActive) {
              graceStreak++;
              expect = dayDate.subtract(const Duration(days: 1));
            } else {
              break;
            }
          } else if (expect != null && dayDate.isBefore(expect)) {
            break;
          }
        }
        currentStreak = graceStreak;
      }
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  /// Get contributions for today
  static int _getTodayContributions(List<ContributionDay> days) {
    final today = AppDateUtils.toDateOnly(AppDateUtils.nowLocal);
    final todayDay = days.firstWhere(
      (d) => AppDateUtils.isSameDay(d.date, today),
      orElse: () => ContributionDay(date: today, contributionCount: 0),
    );
    return todayDay.contributionCount;
  }

  /// Find most active weekday
  static String _getMostActiveWeekday(List<ContributionDay> days) {
    if (days.isEmpty) return 'None';

    final weekdayCounts = List.filled(7, 0);
    for (final day in days) {
      weekdayCounts[day.date.weekday - 1] += day.contributionCount;
    }

    int maxIndex = 0;
    int maxValue = weekdayCounts[0];
    for (int i = 1; i < 7; i++) {
      if (weekdayCounts[i] > maxValue) {
        maxValue = weekdayCounts[i];
        maxIndex = i;
      }
    }

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[maxIndex];
  }

  /// Average contributions per active day
  double get averagePerActiveDay {
    if (activeDaysCount == 0) return 0.0;
    return totalContributions / activeDaysCount;
  }

  @override
  String toString() =>
      'Stats(current: $currentStreak, longest: $longestStreak, today: $todayContributions)';
}

// ══════════════════════════════════════════════════════════════════════════
// CACHED CONTRIBUTION DATA
// ══════════════════════════════════════════════════════════════════════════

/// Complete GitHub contribution data with caching metadata
@immutable
class CachedContributionData {
  /// GitHub username
  final String username;

  /// Total contributions across all days
  final int totalContributions;

  /// List of contribution days
  final List<ContributionDay> days;

  /// When this data was last fetched
  final DateTime lastUpdated;

  /// Calculated statistics (cached)
  final ContributionStats stats;

  /// Pre-computed date lookup map for O(1) access
  late final Map<String, ContributionDay> _dateLookupCache =
      {for (var day in days) day.dateKey: day};

  CachedContributionData({
    required this.username,
    required this.totalContributions,
    required this.days,
    required this.lastUpdated,
    ContributionStats? stats,
  }) : stats = stats ?? ContributionStats.fromDays(days);

  /// Create from GitHub API JSON response
  factory CachedContributionData.fromJson(Map<String, dynamic> json) {
    final daysList = json['days'] as List<dynamic>? ?? [];
    final parsedDays = <ContributionDay>[];

    // Parse days with error handling
    for (final dayJson in daysList) {
      try {
        if (dayJson is Map<String, dynamic>) {
          parsedDays.add(ContributionDay.fromJson(dayJson));
        }
      } catch (e) {
        // Skip invalid days - logged in production via Crashlytics
        continue;
      }
    }

    DateTime timestamp;
    try {
      final lastUpdatedStr = json['lastUpdated'] as String?;
      timestamp = lastUpdatedStr != null
          ? DateTime.parse(lastUpdatedStr)
          : AppDateUtils.nowUtc;
    } catch (e) {
      timestamp = AppDateUtils.nowUtc;
    }

    // Calculate stats from parsed data
    final stats = ContributionStats.fromDays(parsedDays);

    return CachedContributionData(
      username: json['username'] as String? ?? '',
      totalContributions: json['totalContributions'] as int? ?? 0,
      days: parsedDays,
      lastUpdated: timestamp,
      stats: stats,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'username': username,
        'totalContributions': totalContributions,
        'currentStreak': stats.currentStreak,
        'longestStreak': stats.longestStreak,
        'todayCommits': stats.todayContributions,
        'days': days.map((d) => d.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  /// Get contributions for a specific date (fast lookup)
  int getContributionsForDate(DateTime date) {
    final key = AppDateUtils.createDateKey(date);
    return _dateLookupCache[key]?.contributionCount ?? 0;
  }

  /// Check if cached data is stale
  bool isStale([Duration? customThreshold]) {
    final threshold = customThreshold ?? AppConstants.cacheExpiry;
    return DateTime.now().difference(lastUpdated) > threshold;
  }

  /// Convenience getters delegating to stats
  int get currentStreak => stats.currentStreak;
  int get longestStreak => stats.longestStreak;
  int get todayCommits => stats.todayContributions;
  int get activeDaysCount => stats.activeDaysCount;
  int get peakDay => stats.peakDayContributions;
  String get mostActiveWeekday => stats.mostActiveWeekday;
  bool get hasContributedToday => stats.todayContributions > 0;

  /// Average contributions per active day
  double get averagePerActiveDay {
    if (stats.activeDaysCount == 0) return 0.0;
    return totalContributions / stats.activeDaysCount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedContributionData &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          totalContributions == other.totalContributions &&
          lastUpdated == other.lastUpdated &&
          listEquals(days, other.days);

  @override
  int get hashCode =>
      username.hashCode ^
      totalContributions.hashCode ^
      lastUpdated.hashCode ^
      Object.hashAll(days);

  @override
  String toString() =>
      'CachedContributionData(user: $username, total: $totalContributions, days: ${days.length})';
}

// ══════════════════════════════════════════════════════════════════════════
// WALLPAPER CONFIGURATION
// ══════════════════════════════════════════════════════════════════════════

/// Configuration for wallpaper generation and rendering
@immutable
class WallpaperConfig {
  /// Dark mode enabled
  final bool isDarkMode;

  /// Vertical position (0.0 = top, 1.0 = bottom)
  final double verticalPosition;

  /// Horizontal position (0.0 = left, 1.0 = right)
  final double horizontalPosition;

  /// Scale factor for heatmap
  final double scale;

  final bool autoFitWidth;

  /// Opacity of heatmap cells (0.0 = transparent, 1.0 = opaque)
  final double opacity;

  /// Custom quote text
  final String customQuote;

  /// Quote font size
  final double quoteFontSize;

  /// Quote opacity
  final double quoteOpacity;

  /// Padding from edges
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  /// Corner radius of heatmap cells
  final double cornerRadius;

  const WallpaperConfig({
    this.isDarkMode = false,
    this.verticalPosition = 0.5,
    this.horizontalPosition = 0.5,
    this.scale = AppConstants.defaultWallpaperScale,
    this.autoFitWidth = true,
    this.opacity = AppConstants.defaultWallpaperOpacity,
    this.customQuote = '',
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.cornerRadius = AppConstants.defaultCornerRadius,
  })  : assert(verticalPosition >= 0.0 && verticalPosition <= 1.0,
            'verticalPosition must be 0.0-1.0'),
        assert(horizontalPosition >= 0.0 && horizontalPosition <= 1.0,
            'horizontalPosition must be 0.0-1.0'),
        assert(scale > 0.0, 'scale must be positive'),
        assert(opacity >= 0.0 && opacity <= 1.0, 'opacity must be 0.0-1.0'),
        assert(quoteOpacity >= 0.0 && quoteOpacity <= 1.0,
            'quoteOpacity must be 0.0-1.0'),
        assert(quoteFontSize > 0.0, 'quoteFontSize must be positive'),
        assert(cornerRadius >= 0.0, 'cornerRadius must be non-negative'),
        assert(paddingTop >= 0.0, 'paddingTop must be non-negative'),
        assert(paddingBottom >= 0.0, 'paddingBottom must be non-negative'),
        assert(paddingLeft >= 0.0, 'paddingLeft must be non-negative'),
        assert(paddingRight >= 0.0, 'paddingRight must be non-negative');

  /// Create with default values
  factory WallpaperConfig.defaults() => const WallpaperConfig();

  /// Create from JSON storage
  factory WallpaperConfig.fromJson(Map<String, dynamic> json) {
    try {
      return WallpaperConfig(
        isDarkMode: json['isDarkMode'] as bool? ?? false,
        verticalPosition: _parseDouble(json['verticalPosition'], 0.5, 0.0, 1.0),
        horizontalPosition:
            _parseDouble(json['horizontalPosition'], 0.5, 0.0, 1.0),
        scale: _parseDouble(
            json['scale'], AppConstants.defaultWallpaperScale, 0.5, 8.0),
        autoFitWidth: json['autoFitWidth'] as bool? ?? true,
        opacity: _parseDouble(
            json['opacity'], AppConstants.defaultWallpaperOpacity, 0.0, 1.0),
        customQuote: (json['customQuote'] as String? ?? '').trim(),
        quoteFontSize: _parseDouble(json['quoteFontSize'], 14.0, 10.0, 40.0),
        quoteOpacity: _parseDouble(json['quoteOpacity'], 1.0, 0.0, 1.0),
        paddingTop: _parseDouble(json['paddingTop'], 0.0, 0.0, 500.0),
        paddingBottom: _parseDouble(json['paddingBottom'], 0.0, 0.0, 500.0),
        paddingLeft: _parseDouble(json['paddingLeft'], 0.0, 0.0, 500.0),
        paddingRight: _parseDouble(json['paddingRight'], 0.0, 0.0, 500.0),
        cornerRadius: _parseDouble(
            json['cornerRadius'], AppConstants.defaultCornerRadius, 0.0, 20.0),
      );
    } catch (e) {
            return WallpaperConfig.defaults();
    }
  }

  /// Helper to safely parse and clamp double values
  static double _parseDouble(
      dynamic value, double defaultValue, double min, double max) {
    if (value == null) return defaultValue;
    final parsed = (value is num) ? value.toDouble() : defaultValue;
    return parsed.clamp(min, max);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'verticalPosition': verticalPosition,
        'horizontalPosition': horizontalPosition,
        'scale': scale,
        'autoFitWidth': autoFitWidth,
        'opacity': opacity,
        'customQuote': customQuote,
        'quoteFontSize': quoteFontSize,
        'quoteOpacity': quoteOpacity,
        'paddingTop': paddingTop,
        'paddingBottom': paddingBottom,
        'paddingLeft': paddingLeft,
        'paddingRight': paddingRight,
        'cornerRadius': cornerRadius,
      };

  /// Create a copy with modified values
  WallpaperConfig copyWith({
    bool? isDarkMode,
    double? verticalPosition,
    double? horizontalPosition,
    double? scale,
    bool? autoFitWidth,
    double? opacity,
    String? customQuote,
    double? quoteFontSize,
    double? quoteOpacity,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    double? cornerRadius,
  }) {
    return WallpaperConfig(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      verticalPosition: verticalPosition ?? this.verticalPosition,
      horizontalPosition: horizontalPosition ?? this.horizontalPosition,
      scale: scale ?? this.scale,
      autoFitWidth: autoFitWidth ?? this.autoFitWidth,
      opacity: opacity ?? this.opacity,
      customQuote: customQuote ?? this.customQuote,
      quoteFontSize: quoteFontSize ?? this.quoteFontSize,
      quoteOpacity: quoteOpacity ?? this.quoteOpacity,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperConfig &&
          runtimeType == other.runtimeType &&
          isDarkMode == other.isDarkMode &&
          verticalPosition == other.verticalPosition &&
          horizontalPosition == other.horizontalPosition &&
          scale == other.scale &&
          autoFitWidth == other.autoFitWidth &&
          opacity == other.opacity &&
          customQuote == other.customQuote &&
          quoteFontSize == other.quoteFontSize &&
          quoteOpacity == other.quoteOpacity &&
          paddingTop == other.paddingTop &&
          paddingBottom == other.paddingBottom &&
          paddingLeft == other.paddingLeft &&
          paddingRight == other.paddingRight &&
          cornerRadius == other.cornerRadius;

  @override
  int get hashCode =>
      isDarkMode.hashCode ^
      verticalPosition.hashCode ^
      horizontalPosition.hashCode ^
      scale.hashCode ^
      autoFitWidth.hashCode ^
      opacity.hashCode ^
      customQuote.hashCode ^
      quoteFontSize.hashCode ^
      quoteOpacity.hashCode ^
      paddingTop.hashCode ^
      paddingBottom.hashCode ^
      paddingLeft.hashCode ^
      paddingRight.hashCode ^
      cornerRadius.hashCode;

  @override
  String toString() =>
      'WallpaperConfig(dark: $isDarkMode, scale: $scale, opacity: $opacity)';
}
